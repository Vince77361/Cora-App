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
import { FeaturedPostsService } from '../creators/featured-posts.service';
import { FakeInstagramAdapter } from '../integrations/instagram/fake-instagram.adapter';
import {
  InstagramMediaPart,
  InstagramPort,
  InstagramPost,
} from '../integrations/instagram/instagram.port';
import { UsersService } from '../users/users.service';
import { FakeClock } from '../../test/support/fake-clock';
import { FakeStoragePort } from '../../test/support/fake-storage.port';
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
    super(
      null as never,
      null as never,
      null as never,
      null as never,
      null as never,
    );
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
    super(null as never, null as never);
  }
  listForCreator(creatorId: string, methods: SettlementMethod[]) {
    this.asked.push({ creatorId, methods });
    return Promise.resolve(this.held);
  }
}

class FakeFeaturedPosts extends FeaturedPostsService {
  mediaIds = new Set<string>();
  constructor() {
    super(
      null as never,
      null as never,
      null as never,
      null as never,
      null as never,
    );
  }
  listInstagramMediaIds() {
    return Promise.resolve(this.mediaIds);
  }
}

const photo = (
  id: string,
  caption: string | null = '사진 글',
): InstagramPost => ({
  id,
  kind: 'PHOTO',
  caption,
  thumbnailUrl: `https://example.test/${id}.jpg`,
  durationSec: null,
  sizeBytes: null,
});
const video = (
  id: string,
  durationSec: number | null = 30,
  sizeBytes: number | null = 8 * 1024 * 1024,
): InstagramPost => ({
  id,
  kind: 'VIDEO',
  caption: '영상 글',
  thumbnailUrl: `https://example.test/${id}.jpg`,
  durationSec,
  sizeBytes,
});

// 게시물 목록과 파일을 정해 둔 대로 돌려주는 손 구현. 어떤 토큰으로 불렸는지 적어 둔다.
class ScriptedInstagram extends InstagramPort {
  posts: InstagramPost[] = [];
  readonly tokens: (string | null)[] = [];
  readonly fetched: { postId: string; part: InstagramMediaPart }[] = [];
  failOn: string | null = null;
  photoType = 'image/jpeg';

  beginConnect(): Promise<{ connectUrl: string }> {
    return Promise.resolve({ connectUrl: 'cora-dev://scripted' });
  }
  completeConnect(...[, code]: [creatorId: string, code: string]) {
    return Promise.resolve({ handle: code, followers: 1, token: 'tok' });
  }
  fetchFollowers(): Promise<number> {
    return Promise.resolve(1);
  }
  listPosts(token: string | null): Promise<InstagramPost[]> {
    this.tokens.push(token);
    return Promise.resolve(this.posts);
  }
  fetchMedia(
    token: string | null,
    postId: string,
    part: InstagramMediaPart = 'MEDIA',
  ) {
    this.fetched.push({ postId, part });
    if (postId === this.failOn) return Promise.reject(new Error('network'));
    return Promise.resolve({
      bytes: Buffer.from(`${postId}-${part}`),
      contentType: this.photoType,
    });
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
  let storage: FakeStoragePort;
  let featured: FakeFeaturedPosts;
  let service: InstagramService;

  function build(
    secretBox: SecretBox,
    port: InstagramPort = new FakeInstagramAdapter(),
  ): InstagramService {
    return new InstagramService(
      repo,
      port,
      users,
      creators,
      collaborations,
      secretBox,
      clock,
      storage,
      featured,
    );
  }

  beforeEach(() => {
    repo = new FakeInstagramRepository();
    users = new FakeUsers();
    creators = new FakeCreators();
    collaborations = new FakeCollaborations();
    clock = new FakeClock(T0);
    storage = new FakeStoragePort();
    featured = new FakeFeaturedPosts();
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

  it('maps the personal account error to 409 with the guidance sentence', async () => {
    const error = await errorOf(service.complete(CREATOR, 'personal_minji'));
    expect(error.code).toBe('CONFLICT');
    expect(error.message).toBe(
      '개인 계정은 연동할 수 없어요. 인스타그램 앱에서 프로페셔널 계정으로 바꾼 뒤 다시 연동해 주세요.',
    );
    expect(repo.rows.size).toBe(0);
    expect(creators.overwritten).toHaveLength(0);
  });

  describe('instagram posts', () => {
    let port: ScriptedInstagram;

    beforeEach(async () => {
      port = new ScriptedInstagram();
      port.posts = [photo('p1'), video('v1'), photo('p2'), video('v2')];
      service = build(box, port);
      await service.complete(CREATOR, 'haru_cafe');
    });

    it('lists the posts of the connected account with the unsealed token', async () => {
      const posts = await service.listPosts(CREATOR);
      expect(posts.map((p) => p.id)).toEqual(['p1', 'v1', 'p2', 'v2']);
      expect(posts[1]).toEqual({
        id: 'v1',
        kind: 'VIDEO',
        caption: '영상 글',
        thumbnailUrl: 'https://example.test/v1.jpg',
        durationSec: 30,
        sizeBytes: 8 * 1024 * 1024,
      });
      expect(port.tokens).toEqual(['tok']);
    });

    it('passes a null token when the key is not configured', async () => {
      const warn = jest
        .spyOn(Logger.prototype, 'warn')
        .mockImplementation(() => undefined);
      service = build(new SecretBox(undefined), port);
      await service.complete(CREATOR, 'haru_cafe');
      await service.listPosts(CREATOR);
      expect(port.tokens).toEqual([null]);
      warn.mockRestore();
    });

    it("copies a photo post into storage under the creator's folder", async () => {
      const [draft] = await service.importPosts(CREATOR, ['p1']);
      expect(draft).toMatchObject({
        source: 'INSTAGRAM',
        kind: 'PHOTO',
        thumbnailPath: null,
        caption: '사진 글',
        instagramMediaId: 'p1',
      });
      expect(draft.mediaPath).toMatch(
        new RegExp(`^featured-posts/${CREATOR}/[0-9a-f-]{36}\\.jpg$`),
      );
      expect(storage.uploaded).toHaveLength(1);
      expect(storage.uploaded[0]).toMatchObject({
        path: draft.mediaPath,
        contentType: 'image/jpeg',
      });
      expect(storage.uploaded[0].bytes.toString()).toBe('p1-MEDIA');
      expect(draft.photoUrl).toBe(storage.publicUrl(draft.mediaPath));
    });

    it('copies only the first frame of a video and points both paths at it', async () => {
      const [draft] = await service.importPosts(CREATOR, ['v1']);
      expect(draft).toMatchObject({
        source: 'INSTAGRAM',
        kind: 'VIDEO',
        caption: '영상 글',
        instagramMediaId: 'v1',
      });
      expect(draft.mediaPath).toMatch(
        new RegExp(`^featured-posts/${CREATOR}/[0-9a-f-]{36}\\.jpg$`),
      );
      expect(draft.thumbnailPath).toBe(draft.mediaPath);
      // 사진 버킷은 5MB·이미지만 받으므로 영상 파일은 받지도 올리지도 않는다.
      expect(port.fetched).toEqual([{ postId: 'v1', part: 'THUMBNAIL' }]);
      expect(storage.uploaded.map((u) => u.contentType)).toEqual([
        'image/jpeg',
      ]);
      expect(draft.photoUrl).toBe(storage.publicUrl(draft.mediaPath));
    });

    it('keeps the order of the picked posts', async () => {
      const drafts = await service.importPosts(CREATOR, ['v2', 'p2']);
      expect(drafts.map((d) => d.instagramMediaId)).toEqual(['v2', 'p2']);
    });

    it('cuts the caption to its first line of at most 40 characters', async () => {
      port.posts = [
        photo('long', `${'가'.repeat(50)}\n둘째 줄`),
        photo('blank', null),
        photo('lines', '\n  첫 줄이에요  \n둘째 줄'),
      ];
      const drafts = await service.importPosts(CREATOR, [
        'long',
        'blank',
        'lines',
      ]);
      expect(drafts.map((d) => d.caption)).toEqual([
        '가'.repeat(40),
        null,
        '첫 줄이에요',
      ]);
    });

    it.each([
      ['over 60 seconds', video('long', 61)],
      ['over 100MB', video('big', 30, 100 * 1024 * 1024 + 1)],
    ])('refuses a video %s without copying anything', async (_name, post) => {
      port.posts = [photo('p1'), post];
      const error = await errorOf(
        service.importPosts(CREATOR, ['p1', post.id]),
      );
      expect(error.code).toBe('CONFLICT');
      expect(error.message).toBe('60초가 넘는 영상은 가져올 수 없어요.');
      expect(storage.uploaded).toHaveLength(0);
      expect(port.fetched).toHaveLength(0);
    });

    it('accepts a video of exactly 60 seconds and 100MB', async () => {
      port.posts = [video('edge', 60, 100 * 1024 * 1024)];
      await expect(
        service.importPosts(CREATOR, ['edge']),
      ).resolves.toHaveLength(1);
    });

    it('returns 404 for a post id that is not in the connected account', async () => {
      const error = await errorOf(service.importPosts(CREATOR, ['p1', 'nope']));
      expect(error.code).toBe('NOT_FOUND');
      expect(storage.uploaded).toHaveLength(0);
    });

    it('returns 409 for a post that is already a featured post', async () => {
      featured.mediaIds = new Set(['p2']);
      const error = await errorOf(service.importPosts(CREATOR, ['p1', 'p2']));
      expect(error.code).toBe('CONFLICT');
      expect(storage.uploaded).toHaveLength(0);
    });

    it('refuses a file type that cannot be a featured post', async () => {
      port.photoType = 'image/webp';
      const error = await errorOf(service.importPosts(CREATOR, ['p1']));
      expect(error.code).toBe('CONFLICT');
      expect(storage.uploaded).toHaveLength(0);
    });

    it('fails the whole import when a later copy fails and leaves the earlier file as an orphan', async () => {
      const warn = jest
        .spyOn(Logger.prototype, 'warn')
        .mockImplementation(() => undefined);
      port.failOn = 'p2';
      const error = await errorOf(service.importPosts(CREATOR, ['p1', 'p2']));
      expect(error.code).toBe('INTERNAL');
      expect(storage.uploaded).toHaveLength(1);
      warn.mockRestore();
    });

    it('does not list or import without a connection', async () => {
      await service.disconnect(CREATOR);
      expect((await errorOf(service.listPosts(CREATOR))).code).toBe(
        'NOT_FOUND',
      );
      expect((await errorOf(service.importPosts(CREATOR, ['p1']))).code).toBe(
        'NOT_FOUND',
      );
      expect(storage.uploaded).toHaveLength(0);
    });

    it('allows only creators to list or import', async () => {
      users.role = 'STORE';
      expect((await errorOf(service.listPosts(CREATOR))).code).toBe(
        'FORBIDDEN',
      );
      expect((await errorOf(service.importPosts(CREATOR, ['p1']))).code).toBe(
        'FORBIDDEN',
      );
    });
  });
});
