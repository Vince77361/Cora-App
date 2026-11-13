import { Logger } from '@nestjs/common';
import {
  Collaboration,
  InstagramConnection,
  SettlementMethod,
} from '@prisma/client';
import { CollaborationsRepository } from '../collaborations/collaborations.repository';
import { SecretBox } from '../common/crypto/secret-box';
import { AppError } from '../common/errors/app-error';
import { CreatorsService } from '../creators/creators.service';
import { FakeInstagramAdapter } from '../integrations/instagram/fake-instagram.adapter';
import { UsersService } from '../users/users.service';
import { FakeClock } from '../../test/support/fake-clock';
import {
  InstagramConnectionData,
  InstagramRepository,
} from './instagram.repository';
import { InstagramService } from './instagram.service';

const CREATOR = '11111111-1111-4111-8111-111111111111';
const OTHER = '22222222-2222-4222-8222-222222222222';
const KEY = Buffer.alloc(32, 3).toString('base64');
const T0 = new Date('2026-12-01T00:00:00.000Z');

// 서비스 규칙만 보려고 메모리에 저장하는 손 구현. 유일 제약(SQL)은 e2e가 확인한다.
class FakeInstagramRepository extends InstagramRepository {
  readonly rows = new Map<string, InstagramConnection>();
  // 읽을 때는 비어 있었는데 저장할 때 다른 요청이 먼저 그 아이디를 연결한 경우를 흉내 낸다.
  loseHandleRace = false;

  constructor() {
    super(null as never);
  }

  findByCreatorId(creatorId: string) {
    return Promise.resolve(this.rows.get(creatorId) ?? null);
  }

  findByHandle(handle: string) {
    return Promise.resolve(
      [...this.rows.values()].find((row) => row.handle === handle) ?? null,
    );
  }

  upsert(creatorId: string, data: InstagramConnectionData) {
    if (this.loseHandleRace) return Promise.resolve(null);
    const row = {
      id: `id-${creatorId}`,
      creatorId,
      ...data,
      createdAt: T0,
      updatedAt: T0,
      deletedAt: null,
    } as InstagramConnection;
    this.rows.set(creatorId, row);
    return Promise.resolve(row);
  }

  remove(creatorId: string) {
    this.rows.delete(creatorId);
    return Promise.resolve();
  }
}

class FakeUsers extends UsersService {
  role: 'CREATOR' | 'STORE' | null = 'CREATOR';
  constructor() {
    super(null as never);
  }
  getRole() {
    return Promise.resolve(this.role);
  }
}

class FakeCreators extends CreatorsService {
  readonly overwritten: { userId: string; handle: string }[] = [];
  constructor() {
    super(null as never, null as never, null as never, null as never);
  }
  overwriteInstagramHandle(userId: string, handle: string): Promise<void> {
    this.overwritten.push({ userId, handle });
    return Promise.resolve();
  }
}

class FakeCollaborations extends CollaborationsRepository {
  held: Pick<Collaboration, 'kind' | 'stage'>[] = [];
  asked: { creatorId: string; methods: string[] }[] = [];
  constructor() {
    super(null as never);
  }
  listForCreator(creatorId: string, methods: SettlementMethod[]) {
    this.asked.push({ creatorId, methods });
    return Promise.resolve(this.held);
  }
}

async function errorOf(promise: Promise<unknown>): Promise<AppError> {
  try {
    await promise;
  } catch (error) {
    return error as AppError;
  }
  throw new Error('오류가 나야 해요.');
}

describe('InstagramService', () => {
  let repo: FakeInstagramRepository;
  let users: FakeUsers;
  let creators: FakeCreators;
  let collaborations: FakeCollaborations;
  let clock: FakeClock;
  let box: SecretBox;
  let service: InstagramService;

  function build(secretBox: SecretBox): InstagramService {
    return new InstagramService(
      repo,
      new FakeInstagramAdapter(),
      users,
      creators,
      collaborations,
      secretBox,
      clock,
    );
  }

  beforeEach(() => {
    repo = new FakeInstagramRepository();
    users = new FakeUsers();
    creators = new FakeCreators();
    collaborations = new FakeCollaborations();
    clock = new FakeClock(T0);
    box = new SecretBox(KEY);
    service = build(box);
  });

  it('begins a connect with the fake deep link', async () => {
    await expect(service.begin(CREATOR)).resolves.toEqual({
      connectUrl: 'cora-dev://fake-instagram',
    });
  });

  it('connects the typed handle, seals the token and overwrites the profile handle', async () => {
    const result = await service.complete(CREATOR, 'haru_cafe');
    expect(result).toEqual({ handle: 'haru_cafe', followers: 2100 });
    const row = repo.rows.get(CREATOR)!;
    expect(row.followers).toBe(2100);
    expect(row.refreshedAt).toEqual(T0);
    expect(row.tokenEnc).not.toBeNull();
    expect(row.tokenEnc).not.toContain('fake-instagram-token');
    expect(box.open(row.tokenEnc!)).toBe('fake-instagram-token-haru_cafe');
    expect(creators.overwritten).toEqual([
      { userId: CREATOR, handle: 'haru_cafe' },
    ]);
    expect(await service.getConnection(CREATOR)).toEqual({
      handle: 'haru_cafe',
      followers: 2100,
    });
  });

  it('strips one leading @ and surrounding spaces from the typed handle', async () => {
    const result = await service.complete(CREATOR, ' @haru_cafe ');
    expect(result.handle).toBe('haru_cafe');
  });

  it('stores a null token with a warning when the key is not configured', async () => {
    const warn = jest
      .spyOn(Logger.prototype, 'warn')
      .mockImplementation(() => undefined);
    const result = await build(new SecretBox(undefined)).complete(
      CREATOR,
      'haru_cafe',
    );
    expect(result.handle).toBe('haru_cafe');
    expect(repo.rows.get(CREATOR)!.tokenEnc).toBeNull();
    expect(JSON.stringify(warn.mock.calls)).toContain('PAYOUT_ACCOUNT_KEY');
    expect(JSON.stringify(warn.mock.calls)).not.toContain(
      'fake-instagram-token',
    );
    warn.mockRestore();
  });

  it('rejects a handle another creator already connected', async () => {
    await service.complete(OTHER, 'haru_cafe');
    const error = await errorOf(service.complete(CREATOR, 'haru_cafe'));
    expect(error.code).toBe('CONFLICT');
    expect(repo.rows.has(CREATOR)).toBe(false);
    expect(creators.overwritten).toHaveLength(1);
  });

  it('rejects a handle taken between the read and the write', async () => {
    repo.loseHandleRace = true;
    const error = await errorOf(service.complete(CREATOR, 'haru_cafe'));
    expect(error.code).toBe('CONFLICT');
    expect(creators.overwritten).toHaveLength(0);
  });

  it('lowercases the handle so letter case cannot connect one account twice', async () => {
    const result = await service.complete(OTHER, 'Haru_Cafe');
    expect(result.handle).toBe('haru_cafe');
    expect((await errorOf(service.complete(CREATOR, 'haru_cafe'))).code).toBe(
      'CONFLICT',
    );
    expect((await errorOf(service.complete(CREATOR, 'HARU_CAFE'))).code).toBe(
      'CONFLICT',
    );
  });

  it('rejects a handle in a bad format from the provider', async () => {
    expect((await errorOf(service.complete(CREATOR, 'haru cafe!'))).code).toBe(
      'VALIDATION_FAILED',
    );
    expect(repo.rows.size).toBe(0);
  });

  it('lets the same creator connect again with the same or another handle', async () => {
    await service.complete(CREATOR, 'haru_cafe');
    await expect(service.complete(CREATOR, 'haru_cafe')).resolves.toMatchObject(
      { handle: 'haru_cafe' },
    );
    await expect(service.complete(CREATOR, 'haru_two')).resolves.toMatchObject({
      handle: 'haru_two',
    });
    expect(repo.rows.size).toBe(1);
  });

  it('returns null from getConnection when nothing is connected', async () => {
    expect(await service.getConnection(CREATOR)).toBeNull();
  });

  it('disconnects when no per-view collaboration is in progress', async () => {
    await service.complete(CREATOR, 'haru_cafe');
    collaborations.held = [
      { kind: 'STORE_OFFER', stage: 'SETTLED' },
      { kind: 'STORE_OFFER', stage: 'CANCELLED' },
    ];
    await service.disconnect(CREATOR);
    expect(repo.rows.has(CREATOR)).toBe(false);
    expect(collaborations.asked).toEqual([
      { creatorId: CREATOR, methods: ['PER_VIEW', 'FIXED_AND_PER_VIEW'] },
    ]);
  });

  it.each(['FUNDED', 'COUNTING', 'HALTED'] as const)(
    'refuses to disconnect while a per-view collaboration is %s',
    async (stage) => {
      await service.complete(CREATOR, 'haru_cafe');
      collaborations.held = [{ kind: 'STORE_OFFER', stage }];
      const error = await errorOf(service.disconnect(CREATOR));
      expect(error.code).toBe('CONFLICT');
      expect(repo.rows.has(CREATOR)).toBe(true);
    },
  );

  it('refuses to disconnect while a per-view collaboration awaits payment', async () => {
    await service.complete(CREATOR, 'haru_cafe');
    collaborations.held = [{ kind: 'STORE_OFFER', stage: 'AWAITING_PAYMENT' }];
    expect((await errorOf(service.disconnect(CREATOR))).code).toBe('CONFLICT');
    expect(repo.rows.has(CREATOR)).toBe(true);
  });

  it.each(['AWAITING_PAYMENT', 'FUNDED', 'COUNTING', 'HALTED'] as const)(
    'refuses to switch to another handle while a per-view collaboration is %s',
    async (stage) => {
      await service.complete(CREATOR, 'haru_cafe');
      collaborations.held = [{ kind: 'STORE_OFFER', stage }];
      const error = await errorOf(service.complete(CREATOR, 'haru_two'));
      expect(error.code).toBe('CONFLICT');
      expect(repo.rows.get(CREATOR)!.handle).toBe('haru_cafe');
    },
  );

  it('still lets the creator reconnect the same handle (token refresh) while per-view money is held', async () => {
    await service.complete(CREATOR, 'haru_cafe');
    collaborations.held = [
      { kind: 'STORE_OFFER', stage: 'COUNTING' },
      { kind: 'STORE_OFFER', stage: 'AWAITING_PAYMENT' },
    ];
    await expect(service.complete(CREATOR, '@Haru_Cafe')).resolves.toEqual({
      handle: 'haru_cafe',
      followers: 2100,
    });
  });

  it('lets the creator switch handle when no per-view collaboration is in progress', async () => {
    await service.complete(CREATOR, 'haru_cafe');
    collaborations.held = [{ kind: 'STORE_OFFER', stage: 'SETTLED' }];
    await expect(service.complete(CREATOR, 'haru_two')).resolves.toMatchObject({
      handle: 'haru_two',
    });
  });

  it('treats disconnecting with nothing connected as done', async () => {
    await expect(service.disconnect(CREATOR)).resolves.toBeUndefined();
  });

  it('allows only creators to use the connection endpoints', async () => {
    for (const role of ['STORE', null] as const) {
      users.role = role;
      for (const run of [
        () => service.begin(CREATOR),
        () => service.complete(CREATOR, 'haru_cafe'),
        () => service.getMine(CREATOR),
        () => service.disconnect(CREATOR),
      ]) {
        expect((await errorOf(run())).code).toBe('FORBIDDEN');
      }
    }
    expect(repo.rows.size).toBe(0);
  });

  it('throws NOT_FOUND from getMine before connecting', async () => {
    expect((await errorOf(service.getMine(CREATOR))).code).toBe('NOT_FOUND');
    await service.complete(CREATOR, 'haru_cafe');
    expect(await service.getMine(CREATOR)).toEqual({
      handle: 'haru_cafe',
      followers: 2100,
    });
  });
});
