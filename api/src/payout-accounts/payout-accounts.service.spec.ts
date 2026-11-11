import { Logger } from '@nestjs/common';
import { PayoutAccount } from '@prisma/client';
import { SecretBox } from '../common/crypto/secret-box';
import { AppError } from '../common/errors/app-error';
import { UsersService } from '../users/users.service';
import { BANKS } from './banks';
import {
  PayoutAccountData,
  PayoutAccountsRepository,
} from './payout-accounts.repository';
import { PayoutAccountsService } from './payout-accounts.service';

const CREATOR = '11111111-1111-4111-8111-111111111111';
const KEY = Buffer.alloc(32, 3).toString('base64');
const NOW = new Date('2026-12-01T00:00:00.000Z');
const NUMBER = '110123456789';

// 서비스 규칙만 보려고 메모리에 저장하는 손 구현. 유일 제약(SQL)은 e2e가 확인한다.
class FakeRepository extends PayoutAccountsRepository {
  readonly rows = new Map<string, PayoutAccount>();
  constructor() {
    super(null as never);
  }
  findByCreatorId(creatorId: string) {
    return Promise.resolve(this.rows.get(creatorId) ?? null);
  }
  upsert(creatorId: string, data: PayoutAccountData) {
    const row = {
      id: `id-${creatorId}`,
      creatorId,
      ...data,
      createdAt: NOW,
      updatedAt: NOW,
      deletedAt: null,
    } as PayoutAccount;
    this.rows.set(creatorId, row);
    return Promise.resolve(row);
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

async function errorOf(promise: Promise<unknown>): Promise<AppError> {
  try {
    await promise;
  } catch (error) {
    return error as AppError;
  }
  throw new Error('오류가 나야 해요.');
}

describe('PayoutAccountsService', () => {
  let repo: FakeRepository;
  let users: FakeUsers;
  let box: SecretBox;
  let service: PayoutAccountsService;
  let logged: string[];
  let errorSpy: jest.SpyInstance;

  beforeEach(() => {
    repo = new FakeRepository();
    users = new FakeUsers();
    box = new SecretBox(KEY);
    service = new PayoutAccountsService(repo, users, box);
    logged = [];
    errorSpy = jest
      .spyOn(Logger.prototype, 'error')
      .mockImplementation((message: unknown) => {
        logged.push(String(message));
      });
  });
  afterEach(() => errorSpy.mockRestore());

  const dto = { bankCode: '004', accountNumber: NUMBER, holderName: '김민지' };

  it('stores the number sealed and returns only the last four digits', async () => {
    const model = await service.upsert(CREATOR, dto);
    expect(model).toEqual({
      bankCode: '004',
      bankName: '국민',
      bankFullName: '국민은행',
      accountLast4: '6789',
      holderName: '김민지',
    });
    const row = repo.rows.get(CREATOR)!;
    expect(row.accountNumberEnc).not.toContain(NUMBER);
    expect(box.open(row.accountNumberEnc)).toBe(NUMBER);
    expect(JSON.stringify(model)).not.toContain(NUMBER);
  });

  it('opens the full number only through getForPayout', async () => {
    expect(await service.getForPayout(CREATOR)).toBeNull();
    await service.upsert(CREATOR, dto);
    expect(await service.getForPayout(CREATOR)).toEqual({
      bankCode: '004',
      accountNumber: NUMBER,
      holderName: '김민지',
    });
  });

  it('rejects an unknown bank code', async () => {
    const error = await errorOf(
      service.upsert(CREATOR, { ...dto, bankCode: '999' }),
    );
    expect(error.code).toBe('VALIDATION_FAILED');
    expect(repo.rows.size).toBe(0);
  });

  it('requires the CREATOR role', async () => {
    users.role = 'STORE';
    expect((await errorOf(service.upsert(CREATOR, dto))).code).toBe(
      'FORBIDDEN',
    );
    expect((await errorOf(service.getMine(CREATOR))).code).toBe('FORBIDDEN');
    expect(repo.rows.size).toBe(0);
  });

  it('returns 404 when there is no account', async () => {
    expect((await errorOf(service.getMine(CREATOR))).code).toBe('NOT_FOUND');
  });

  it('lists every bank with a unique three-digit code and full name', () => {
    const banks = service.listBanks();
    expect(banks).toHaveLength(20);
    expect(new Set(banks.map((b) => b.code)).size).toBe(20);
    for (const bank of banks) {
      expect(bank.code).toMatch(/^\d{3}$/);
      expect(bank.fullName.length).toBeGreaterThan(0);
    }
    expect(banks).toEqual(BANKS);
  });

  it('calls registered listeners after saving and survives a failing listener', async () => {
    const calls: string[] = [];
    service.onRegistered(() => Promise.reject(new Error('boom')));
    service.onRegistered((id) => {
      calls.push(id);
      return Promise.resolve();
    });
    const model = await service.upsert(CREATOR, dto);
    expect(model.accountLast4).toBe('6789');
    expect(calls).toEqual([CREATOR]);
    expect(repo.rows.has(CREATOR)).toBe(true);
    expect(logged.join('\n')).toContain('boom');
    expect(logged.join('\n')).not.toContain(NUMBER);
  });

  it('fails cleanly without PAYOUT_ACCOUNT_KEY: no row, log names the key, client message does not', async () => {
    const noKey = new PayoutAccountsService(
      repo,
      users,
      new SecretBox(undefined),
    );
    const error = await errorOf(noKey.upsert(CREATOR, dto));
    expect(error.code).toBe('INTERNAL');
    expect(error.message).not.toContain('PAYOUT_ACCOUNT_KEY');
    expect(repo.rows.size).toBe(0);
    const log = logged.join('\n');
    expect(log).toContain('PAYOUT_ACCOUNT_KEY');
    expect(log).not.toContain(NUMBER);
    expect(log).toContain('6789');
  });

  it('does not call listeners when saving failed', async () => {
    const calls: string[] = [];
    const noKey = new PayoutAccountsService(
      repo,
      users,
      new SecretBox(undefined),
    );
    noKey.onRegistered((id) => {
      calls.push(id);
      return Promise.resolve();
    });
    await errorOf(noKey.upsert(CREATOR, dto));
    expect(calls).toEqual([]);
  });
});
