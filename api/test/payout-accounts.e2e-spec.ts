import { randomUUID } from 'node:crypto';
import { INestApplication } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';
import request from 'supertest';
import { SecretBox } from '../src/common/crypto/secret-box';
import { createTestApp, httpOf } from './helpers/create-test-app';
import { truncateTestDb } from './helpers/truncate-test-db';
import { USER_A } from './support/fake-token-verifier';

const auth = { Authorization: 'Bearer user-a' };
const NUMBER = '110123456789';

interface AccountBody {
  bankCode: string;
  bankName: string;
  bankFullName: string;
  accountLast4: string;
  holderName: string;
}
interface BankBody {
  code: string;
  name: string;
  fullName: string;
}
const codeOf = (res: request.Response) =>
  (res.body as { error: { code: string } }).error.code;

describe('payout accounts', () => {
  let app: INestApplication;
  let prisma: PrismaClient;
  let server: ReturnType<typeof httpOf>;

  const setRole = (role: 'STORE' | 'CREATOR' | 'BRAND') =>
    request(server).patch('/me/role').set(auth).send({ role }).expect(200);
  const put = (body: unknown) =>
    request(server)
      .put('/payout-account')
      .set(auth)
      .send(body as object);
  const valid = {
    bankCode: '004',
    accountNumber: NUMBER,
    holderName: '김민지',
  };

  beforeAll(async () => {
    prisma = new PrismaClient();
    app = await createTestApp();
    server = httpOf(app);
  });
  beforeEach(async () => {
    await truncateTestDb(prisma);
    await setRole('CREATOR');
  });
  afterEach(() => jest.restoreAllMocks());
  afterAll(async () => {
    await app.close();
    await prisma.$disconnect();
  });

  it('rejects requests with no token', async () => {
    await request(server).get('/payout-account/banks').expect(401);
    await request(server).get('/payout-account').expect(401);
    await request(server).put('/payout-account').send(valid).expect(401);
  });

  it('lists the banks with codes and display names', async () => {
    const res = await request(server)
      .get('/payout-account/banks')
      .set(auth)
      .expect(200);
    const banks = res.body as BankBody[];
    expect(banks).toHaveLength(20);
    expect(banks[0]).toEqual({
      code: '004',
      name: '국민',
      fullName: '국민은행',
    });
    expect(banks.map((b) => b.code)).toContain('090');
  });

  it('returns 404 before an account is registered', async () => {
    const res = await request(server)
      .get('/payout-account')
      .set(auth)
      .expect(404);
    expect(codeOf(res)).toBe('NOT_FOUND');
  });

  it('returns only the last four digits', async () => {
    const res = await put(valid).expect(200);
    expect(res.body as AccountBody).toEqual({
      bankCode: '004',
      bankName: '국민',
      bankFullName: '국민은행',
      accountLast4: '6789',
      holderName: '김민지',
    });
    const read = await request(server)
      .get('/payout-account')
      .set(auth)
      .expect(200);
    expect(read.body as AccountBody).toEqual(res.body);
    expect(JSON.stringify(res.body)).not.toContain(NUMBER);
    expect(JSON.stringify(read.body)).not.toContain(NUMBER);
  });

  it('stores the account number encrypted', async () => {
    await put(valid).expect(200);
    const row = await prisma.payoutAccount.findUniqueOrThrow({
      where: { creatorId: USER_A },
    });
    expect(row.accountNumberEnc).not.toContain(NUMBER);
    expect(row.accountNumberEnc).not.toContain('6789');
    expect(row.accountLast4).toBe('6789');
    expect(app.get(SecretBox).open(row.accountNumberEnc)).toBe(NUMBER);
  });

  it('strips hyphens and rejects non-digits', async () => {
    await put({ ...valid, accountNumber: '110-1234-56789' }).expect(200);
    const row = await prisma.payoutAccount.findUniqueOrThrow({
      where: { creatorId: USER_A },
    });
    expect(app.get(SecretBox).open(row.accountNumberEnc)).toBe('110123456789');
    for (const accountNumber of [
      '11012345678a',
      '110 123 456789',
      '123456789', // 9자리
      '123456789012345', // 15자리
      '',
      1234567890,
    ]) {
      const res = await put({ ...valid, accountNumber }).expect(400);
      expect(codeOf(res)).toBe('VALIDATION_FAILED');
    }
  });

  it('rejects an unknown bank code', async () => {
    const res = await put({ ...valid, bankCode: '999' }).expect(400);
    expect(codeOf(res)).toBe('VALIDATION_FAILED');
    expect(await prisma.payoutAccount.count()).toBe(0);
  });

  it('validates the holder name length', async () => {
    await put({ ...valid, holderName: '' }).expect(400);
    await put({ ...valid, holderName: '   ' }).expect(400);
    await put({ ...valid, holderName: '가'.repeat(21) }).expect(400);
    await put({ ...valid, holderName: '가'.repeat(20) }).expect(200);
  });

  it('replaces the account when registered again', async () => {
    await put(valid).expect(200);
    const res = await put({
      bankCode: '090',
      accountNumber: '3333012345678',
      holderName: '김민지',
    }).expect(200);
    expect(res.body as AccountBody).toMatchObject({
      bankCode: '090',
      bankFullName: '카카오뱅크',
      accountLast4: '5678',
    });
    expect(await prisma.payoutAccount.count()).toBe(1);
  });

  it('requires the CREATOR role', async () => {
    await setRole('STORE');
    expect(codeOf(await put(valid).expect(403))).toBe('FORBIDDEN');
    await request(server).get('/payout-account').set(auth).expect(403);
    expect(await prisma.payoutAccount.count()).toBe(0);
  });

  it('does not let one creator read another creators account', async () => {
    const other = randomUUID();
    await prisma.user.create({ data: { id: other, role: 'CREATOR' } });
    await prisma.payoutAccount.create({
      data: {
        creatorId: other,
        bankCode: '004',
        accountNumberEnc: app.get(SecretBox).seal(NUMBER),
        accountLast4: '6789',
        holderName: '타인',
      },
    });
    await request(server).get('/payout-account').set(auth).expect(404);
  });

  it('fails cleanly when the encryption key is missing: no row, generic error, server keeps running', async () => {
    jest.spyOn(app.get(SecretBox), 'isConfigured').mockReturnValue(false);
    const res = await put(valid).expect(500);
    expect(codeOf(res)).toBe('INTERNAL');
    expect(JSON.stringify(res.body)).not.toContain('PAYOUT_ACCOUNT_KEY');
    expect(JSON.stringify(res.body)).not.toContain(NUMBER);
    expect(await prisma.payoutAccount.count()).toBe(0);
    await request(server).get('/payout-account/banks').set(auth).expect(200);
  });
});
