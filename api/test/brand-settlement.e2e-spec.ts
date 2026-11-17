import { INestApplication } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';
import request from 'supertest';
import { Clock } from '../src/common/clock';
import { OperatorAlertPort } from '../src/integrations/operator-alert/operator-alert.port';
import { JobScheduler } from '../src/jobs/job-scheduler';
import { OpsRunner } from '../src/ops/ops.runner';
import { RealtimePublisher } from '../src/realtime/realtime-publisher';
import { SettlementsService } from '../src/settlements/settlements.service';
import { createTestApp, httpOf } from './helpers/create-test-app';
import { flushMessages } from './helpers/flush-messages';
import { truncateTestDb } from './helpers/truncate-test-db';
import { FakeClock } from './support/fake-clock';
import { FakeJobScheduler } from './support/fake-job-scheduler';
import { FakePushPort } from './support/fake-push.port';
import { FakeRealtimePublisher } from './support/fake-realtime-publisher';
import { OTHER, USER_A } from './support/fake-token-verifier';
import { PushPort } from '../src/integrations/push/push.port';

jest.setTimeout(60000);

// user-a는 브랜드, user-b는 크리에이터다. 계약 체결까지는 계약 e2e와 같은 길(HTTP)로 만들고,
// 제작·검토 단계는 아직 이 서버에 길이 없어서 협업 단계를 APPROVED로 직접 옮겨 두고 시작한다.
const authBrand = { Authorization: 'Bearer user-a' };
const authCreator = { Authorization: 'Bearer user-b' };
const REGION = { regionSido: '서울특별시', regionSigungu: '성동구' };
const CAMPAIGN = {
  headline: '나만의 아침 루틴 속 작은 포인트',
  fee: 350000,
  budget: 1000000,
  productProvided: true,
  format: 'REELS',
  startFrom: '2026-11-20',
  trialDays: 'D7',
  mustInclude: ['제품 로고가 보이게'],
  notRequired: ['FACE'],
};
const PRINCIPLES = {
  fields: ['ACCESSORY'],
  blockedIndustries: [] as string[],
  faceOk: true,
  scriptOk: true,
  honestReview: true,
  feeBand: 'W300K',
  trialDays: 'ANY',
};
const PERFORMANCE = { ratePer1000: 2000, cap: 60000 };
const REEL = 'https://www.instagram.com/reel/Cabc123xyz/';
const NOON = new Date('2026-11-11T03:00:00.000Z');
const MINUTE = 60_000;
const DAY = 24 * 60 * MINUTE;
const WHO = ['--operator', '김운영', '--reason', '운영 확인 후 처리'];

describe('brand contract fixed payout and the 60 day halt check', () => {
  let app: INestApplication;
  let prisma: PrismaClient;
  let server: ReturnType<typeof httpOf>;
  let clock: FakeClock;
  let push: FakePushPort;
  let realtime: FakeRealtimePublisher;
  let scheduler: FakeJobScheduler;
  let alert: jest.SpyInstance;

  const codeOf = (res: request.Response) =>
    (res.body as { error: { code: string } }).error.code;
  const setRole = (auth: Record<string, string>, role: string) =>
    request(server).patch('/me/role').set(auth).send({ role }).expect(200);
  const decide = (auth: Record<string, string>, body: object) =>
    request(server).put('/discovery/decisions').set(auth).send(body);
  const confirm = (auth: Record<string, string>, id: string, version: number) =>
    request(server)
      .post(`/collaborations/${id}/terms/${version}/confirm`)
      .set(auth);
  const propose = (id: string, body: Record<string, unknown>) =>
    request(server)
      .post(`/collaborations/${id}/terms`)
      .set(authBrand)
      .send(body);
  const getContract = (auth: Record<string, string>, id: string) =>
    request(server).get(`/collaborations/${id}/contract`).set(auth);
  const approve = (paymentId: string) =>
    request(server)
      .post(`/dev/fake-payments/${paymentId}/approve`)
      .set(authBrand)
      .send();
  const submit = (id: string, url: string, auth = authCreator) =>
    request(server)
      .post(`/collaborations/${id}/submission`)
      .set(auth)
      .send({ url });
  const collaborationOf = (id: string) =>
    prisma.collaboration.findUniqueOrThrow({ where: { id } });
  const ledgerOf = (id: string) =>
    prisma.ledgerEntry.findMany({ where: { collaborationId: id } });
  const balanceOf = async (id: string) => {
    const sum: Record<string, number> = {};
    for (const e of await ledgerOf(id)) {
      sum[e.creditAccount] = (sum[e.creditAccount] ?? 0) + e.amount;
      sum[e.debitAccount] = (sum[e.debitAccount] ?? 0) - e.amount;
    }
    return sum;
  };
  const notificationTexts = async (auth: Record<string, string>) =>
    (
      (await request(server).get('/notifications').set(auth).expect(200))
        .body as { items: { text: string }[] }
    ).items.map((i) => i.text);
  const jobsOf = (key: string) =>
    scheduler.jobs.filter((j) => j.jobKey === key);
  const ops = (...args: string[]) => app.get(OpsRunner).run([...args, ...WHO]);

  // 서로 관심 → 판본 1(제작비 350,000원, 지급 7일)을 양쪽이 확인해 합의한 상태(AGREED)까지 만든다.
  // 지급 조건이나 성과 추가를 바꾸려면 브랜드가 판본 2를 내고 크리에이터가 확인한다.
  async function agreed(
    opts: { payoutDays?: number; performance?: boolean } = {},
  ): Promise<string> {
    await setRole(authBrand, 'BRAND');
    await request(server)
      .put('/brands/me')
      .set(authBrand)
      .send({
        name: '느린결',
        tagline: '천천히 쓰는 물건',
        industry: 'ACCESSORY',
      })
      .expect(200);
    const created = await request(server)
      .post('/campaigns')
      .set(authBrand)
      .send(CAMPAIGN)
      .expect(201);
    await setRole(authCreator, 'CREATOR');
    await request(server)
      .put('/creators/me')
      .set(authCreator)
      .send({ displayName: '하루 한 컵', ...REGION })
      .expect(200);
    await request(server)
      .put('/creators/me/principles')
      .set(authCreator)
      .send(PRINCIPLES)
      .expect(200);
    await decide(authCreator, {
      targetKind: 'CAMPAIGN',
      targetId: (created.body as { id: string }).id,
      decision: 'LIKE',
      note: '아침 한 컵',
    }).expect(200);
    const res = await decide(authBrand, {
      targetKind: 'CREATOR',
      targetId: OTHER,
      decision: 'LIKE',
    }).expect(200);
    const id = (res.body as { collaborationId: string }).collaborationId;
    // 판본 1의 지급 조건은 7일이다. 같은 값으로는 새 판본을 낼 수 없다.
    if ((opts.payoutDays ?? 7) === 7 && !opts.performance) {
      await confirm(authBrand, id, 1).expect(200);
      await confirm(authCreator, id, 1).expect(200);
      return id;
    }
    if (opts.performance) {
      await prisma.instagramConnection.create({
        data: {
          creatorId: OTHER,
          handle: 'haru_cup',
          followers: 12400,
          refreshedAt: NOON,
        },
      });
    }
    await propose(id, {
      baseVersion: 1,
      fee: 350000,
      productProvided: true,
      performance: opts.performance ? PERFORMANCE : null,
      ...(opts.payoutDays ? { payoutDays: opts.payoutDays } : {}),
    }).expect(201);
    await confirm(authCreator, id, 2).expect(200);
    return id;
  }

  // 계약을 체결(결제 승인)하고 협업을 APPROVED로 옮겨 둔다. 체결 시각은 NOON이다.
  async function approvedContract(
    opts: { payoutDays?: number; performance?: boolean } = {},
  ): Promise<string> {
    const id = await agreed(opts);
    const version = (
      (await getContract(authCreator, id).expect(200)).body as {
        termsVersion: number;
        myConsentTexts: string[];
      }
    ).termsVersion;
    const creatorTexts = (
      (await getContract(authCreator, id).expect(200)).body as {
        myConsentTexts: string[];
      }
    ).myConsentTexts;
    await request(server)
      .post(`/collaborations/${id}/contract/creator-consent`)
      .set(authCreator)
      .send({ termsVersion: version, accepted: creatorTexts })
      .expect(200);
    const brandTexts = (
      (await getContract(authBrand, id).expect(200)).body as {
        myConsentTexts: string[];
      }
    ).myConsentTexts;
    const paid = await request(server)
      .post(`/collaborations/${id}/contract/brand-consent`)
      .set(authBrand)
      .send({ termsVersion: version, accepted: brandTexts, method: 'CARD' })
      .expect(201);
    await approve((paid.body as { paymentId: string }).paymentId).expect(200);
    expect((await collaborationOf(id)).stage).toBe('CONTRACTED');
    await prisma.collaboration.update({
      where: { id },
      data: { stage: 'APPROVED' },
    });
    return id;
  }

  const registerAccount = () =>
    request(server)
      .put('/payout-account')
      .set(authCreator)
      .send({
        bankCode: '004',
        accountNumber: '110123456789',
        holderName: '김민지',
      })
      .expect(200);

  beforeAll(async () => {
    prisma = new PrismaClient();
    app = await createTestApp([], { fakeRealtime: true });
    server = httpOf(app);
    clock = app.get<FakeClock>(Clock);
    push = app.get<FakePushPort>(PushPort);
    realtime = app.get<FakeRealtimePublisher>(RealtimePublisher);
    scheduler = app.get<FakeJobScheduler>(JobScheduler);
    alert = jest
      .spyOn(app.get(OperatorAlertPort), 'alert')
      .mockResolvedValue(undefined);
  });
  beforeEach(async () => {
    await truncateTestDb(prisma);
    clock.set(NOON);
    push.sent.length = 0;
    realtime.sent.length = 0;
    scheduler.jobs.length = 0;
    alert.mockClear();
  });
  afterAll(async () => {
    alert.mockRestore();
    await app.close();
    await prisma.$disconnect();
  });

  describe('link submission', () => {
    it('accepts a link only at APPROVED and moves to PUBLISHED with the payout time', async () => {
      const id = await approvedContract({ payoutDays: 14 });
      // 링크를 낼 수 있는 단계는 APPROVED뿐이다(체결 직후와 검토 중에는 받지 않는다).
      for (const stage of ['CONTRACTED', 'GUIDED', 'REVIEWING'] as const) {
        await prisma.collaboration.update({ where: { id }, data: { stage } });
        const res = await submit(id, REEL).expect(409);
        expect(codeOf(res)).toBe('CONFLICT');
      }
      await prisma.collaboration.update({
        where: { id },
        data: { stage: 'APPROVED' },
      });

      clock.set(new Date(NOON.getTime() + 10 * DAY));
      const res = await submit(id, REEL).expect(200);
      const dueAt = new Date(NOON.getTime() + 24 * DAY);
      expect(res.body).toMatchObject({
        id,
        stage: 'PUBLISHED',
        submittedUrl: REEL,
        countingEndsAt: dueAt.toISOString(),
      });
      expect(await collaborationOf(id)).toMatchObject({
        stage: 'PUBLISHED',
        submittedUrl: REEL,
        submittedAt: clock.now(),
        countingEndsAt: dueAt,
      });
      // 지급 작업은 링크를 낸 날 + 지급 조건에 올라가고, 60일 점검은 지워진다.
      expect(jobsOf(`settle-fixed:${id}`)).toEqual([
        expect.objectContaining({
          name: 'settle-fixed',
          payload: { collaborationId: id },
          runAt: dueAt,
          status: 'pending',
        }),
      ]);
      expect(jobsOf(`brand-halt:${id}`)).toHaveLength(0);
      // 브랜드에게 알린다.
      expect(await notificationTexts(authBrand)).toContain(
        '하루 한 컵님이 콘텐츠를 올렸어요.',
      );
    });

    it('answers 409 for a collaboration that has no concluded contract yet', async () => {
      const id = await agreed();
      expect(codeOf(await submit(id, REEL).expect(409))).toBe('CONFLICT');
    });

    it('takes the link format from the contract snapshot and keeps the brand out', async () => {
      const id = await approvedContract();
      await submit(id, 'https://www.youtube.com/shorts/abc123').expect(400);
      await submit(id, 'https://blog.naver.com/someone/1').expect(400);
      expect((await submit(id, REEL, authBrand).expect(403)).status).toBe(403);
      expect((await collaborationOf(id)).stage).toBe('APPROVED');
      await submit(id, REEL).expect(200);
      // 같은 제출이 다시 오면 409이고 아무것도 바뀌지 않는다.
      await submit(id, REEL).expect(409);
      expect(jobsOf(`settle-fixed:${id}`)).toHaveLength(1);
    });
  });

  describe('fixed payout (no performance bonus)', () => {
    it('does not pay one minute before N days after submission', async () => {
      const id = await approvedContract({ payoutDays: 7 });
      await submit(id, REEL).expect(200);
      const dueAt = new Date(NOON.getTime() + 7 * DAY);

      clock.set(new Date(dueAt.getTime() - MINUTE));
      await scheduler.runDue(clock.now());
      expect((await collaborationOf(id)).stage).toBe('PUBLISHED');
      expect(await prisma.settlement.count()).toBe(0);
      expect(await prisma.payout.count()).toBe(0);
      expect(await balanceOf(id)).toMatchObject({ ESCROW: 350000 });
      // 일찍 도는 작업이 있어도 지급하지 않고 던진다(큐가 나중에 다시 시도한다).
      await expect(
        app.get(SettlementsService).settleFixed(id, `settle:${id}`),
      ).rejects.toThrow('아직 지급 시각이 아니에요');
      expect(await prisma.settlement.count()).toBe(0);
      expect((await collaborationOf(id)).stage).toBe('PUBLISHED');
    });

    it('pays the full fee exactly N days after submission with no refund', async () => {
      const id = await approvedContract({ payoutDays: 14 });
      await submit(id, REEL).expect(200);
      const dueAt = new Date(NOON.getTime() + 14 * DAY);
      await flushMessages(app);
      push.sent.length = 0;

      clock.set(dueAt);
      await scheduler.runDue(clock.now());

      expect((await collaborationOf(id)).stage).toBe('SETTLED');
      expect(await prisma.settlement.findFirstOrThrow({})).toMatchObject({
        collaborationId: id,
        finalViews: null,
        payoutAmount: 350000,
        refundAmount: 0,
        fixedCashAmount: 350000,
        viewPayAmount: 0,
        status: 'CONFIRMED',
        confirmedBy: 'NOT_NEEDED',
      });
      expect(await prisma.refund.count()).toBe(0);
      const payout = await prisma.payout.findFirstOrThrow({});
      expect(payout).toMatchObject({
        collaborationId: id,
        amount: 350000,
        status: 'PENDING',
      });
      // 송금은 정산이 확정된 주의 다음 주 수요일 10시(한국 시간)에 나간다.
      expect(payout.scheduledFor.toISOString()).toBe(
        '2026-12-02T01:00:00.000Z',
      );
      expect(jobsOf(`payout:${payout.id}`)).toHaveLength(1);
      // 장부: 에스크로가 비고 제작비는 지급 예정으로, 수수료는 수익으로 남는다.
      expect(await balanceOf(id)).toEqual({
        PG_IN: -385000,
        ESCROW: 0,
        CREATOR_PAYABLE: 350000,
        FEE_REVENUE: 35000,
      });
      expect(await notificationTexts(authCreator)).toContain(
        '정산 350,000원이 다음 주 수요일에 들어와요.',
      );
    });

    it('pays once when the settle-fixed job runs twice', async () => {
      const id = await approvedContract({ payoutDays: 7 });
      await submit(id, REEL).expect(200);
      clock.set(new Date(NOON.getTime() + 7 * DAY));
      await scheduler.runDue(clock.now());
      const entries = (await ledgerOf(id)).length;
      const settlements = app.get(SettlementsService);
      // 커밋 뒤 지급 작업 등록 전에 죽은 것처럼 작업을 지워 둔다: 다시 돌면 남은 단계를 마친다.
      const payout = await prisma.payout.findFirstOrThrow({});
      scheduler.jobs.splice(
        0,
        scheduler.jobs.length,
        ...scheduler.jobs.filter((j) => j.jobKey !== `payout:${payout.id}`),
      );
      // 다시 돌고(순차), 동시에 두 번 돌아도 한 번이다.
      await settlements.settleFixed(id, `settle:${id}`);
      await Promise.all([
        settlements.settleFixed(id, `settle:${id}`),
        settlements.settleFixed(id, `settle:${id}`),
      ]);

      expect(await prisma.settlement.count()).toBe(1);
      expect(await prisma.payout.count()).toBe(1);
      expect(await prisma.refund.count()).toBe(0);
      expect(await ledgerOf(id)).toHaveLength(entries);
      expect(
        (await notificationTexts(authCreator)).filter((t) =>
          t.startsWith('정산 350,000원'),
        ),
      ).toHaveLength(1);
      expect(jobsOf(`settle-fixed:${id}`)).toHaveLength(1);
      expect(jobsOf(`payout:${payout.id}`)).toHaveLength(1);
    });

    it('tells the creator on the payout day and the brand that the fee was paid', async () => {
      const id = await approvedContract({ payoutDays: 7 });
      await registerAccount();
      await submit(id, REEL).expect(200);
      clock.set(new Date(NOON.getTime() + 7 * DAY));
      await scheduler.runDue(clock.now());
      const payout = await prisma.payout.findFirstOrThrow({});

      clock.set(payout.scheduledFor);
      await scheduler.runDue(clock.now());
      expect(
        (await prisma.payout.findUniqueOrThrow({ where: { id: payout.id } }))
          .status,
      ).toBe('DONE');
      expect(await notificationTexts(authCreator)).toContain(
        '350,000원이 지급됐어요.',
      );
      expect(await notificationTexts(authBrand)).toContain(
        '제작비 350,000원을 크리에이터에게 지급했어요.',
      );
      // 같은 송금 작업이 다시 돌아도 알림은 한 건씩이다.
      await scheduler.registry.run('payout-send', { payoutId: payout.id });
      expect(
        (await notificationTexts(authBrand)).filter((t) =>
          t.startsWith('제작비'),
        ),
      ).toHaveLength(1);
    });

    it('keeps every brand collaboration ledger balanced', async () => {
      const id = await approvedContract({ payoutDays: 7 });
      await submit(id, REEL).expect(200);
      const before = await balanceOf(id);
      expect(Object.values(before).reduce((a, b) => a + b, 0)).toBe(0);
      clock.set(new Date(NOON.getTime() + 7 * DAY));
      await scheduler.runDue(clock.now());
      const after = await balanceOf(id);
      expect(Object.values(after).reduce((a, b) => a + b, 0)).toBe(0);
      expect(after.ESCROW).toBe(0);
    });
  });

  describe('a contract with a performance bonus', () => {
    it('is published on submission but is never paid by settle-fixed', async () => {
      const id = await approvedContract({ performance: true, payoutDays: 7 });
      await submit(id, 'https://www.instagram.com/reel/notmine1/').expect(409);
      expect((await collaborationOf(id)).stage).toBe('APPROVED');

      await submit(id, REEL).expect(200);
      expect(await collaborationOf(id)).toMatchObject({
        stage: 'PUBLISHED',
        countingEndsAt: new Date(NOON.getTime() + 7 * DAY),
      });
      // 지급 작업을 올리지 않는다.
      expect(jobsOf(`settle-fixed:${id}`)).toHaveLength(0);
      expect(jobsOf(`brand-halt:${id}`)).toHaveLength(0);

      clock.set(new Date(NOON.getTime() + 30 * DAY));
      await scheduler.runDue(clock.now());
      // 작업이 잘못 올라가 직접 돌아도 지급하지 않는다.
      await app.get(SettlementsService).settleFixed(id, `settle:${id}`);
      await scheduler.registry.run('settle-fixed', { collaborationId: id });
      expect((await collaborationOf(id)).stage).toBe('PUBLISHED');
      expect(await prisma.settlement.count()).toBe(0);
      expect(await prisma.payout.count()).toBe(0);
      expect(await balanceOf(id)).toMatchObject({
        ESCROW: 410000,
        FEE_REVENUE: 41000,
      });
    });
  });

  describe('60 day halt check', () => {
    it('halts and alerts the operator 60 days after the contract without a link', async () => {
      const id = await approvedContract();
      await flushMessages(app);
      push.sent.length = 0;
      realtime.sent.length = 0;
      const check = jobsOf(`brand-halt:${id}`);
      expect(check).toHaveLength(1);
      expect(check[0].runAt).toEqual(new Date(NOON.getTime() + 60 * DAY));

      clock.set(new Date(NOON.getTime() + 60 * DAY - MINUTE));
      await scheduler.runDue(clock.now());
      expect((await collaborationOf(id)).stage).toBe('APPROVED');

      clock.set(new Date(NOON.getTime() + 60 * DAY));
      await scheduler.runDue(clock.now());
      expect(await collaborationOf(id)).toMatchObject({
        stage: 'HALTED',
        stageBeforeHalt: 'APPROVED',
        haltedReason: 'NO_LINK_60_DAYS',
      });
      expect(alert).toHaveBeenCalledTimes(1);
      expect(alert).toHaveBeenCalledWith(
        expect.objectContaining({
          subject: '[Cora] 협업 멈춤 · 60일 동안 링크 없음',
        }),
      );
      for (const auth of [authBrand, authCreator]) {
        expect(await notificationTexts(auth)).toContain(
          '협업이 잠시 멈췄어요. 운영팀이 확인하고 연락드릴게요.',
        );
      }
      // 돈은 에스크로에 그대로 있다. 작업 처리기는 API 프로세스에서 돌아 게이트웨이로 양쪽 화면에 알린다.
      expect(await balanceOf(id)).toMatchObject({ ESCROW: 350000 });
      const room = await prisma.conversation.findUniqueOrThrow({
        where: { collaborationId: id },
      });
      for (const userId of [USER_A, OTHER]) {
        expect(realtime.receivedBy(userId, 'conversation.updated')).toEqual([
          expect.objectContaining({
            payload: { conversationId: room.id, reason: 'STATUS' },
          }),
        ]);
      }
    });

    it('halts from every stage before the link and only once', async () => {
      for (const stage of ['CONTRACTED', 'GUIDED', 'REVIEWING'] as const) {
        await truncateTestDb(prisma);
        scheduler.jobs.length = 0;
        clock.set(NOON);
        const id = await approvedContract();
        await prisma.collaboration.update({ where: { id }, data: { stage } });
        clock.set(new Date(NOON.getTime() + 60 * DAY));
        await scheduler.runDue(clock.now());
        expect(await collaborationOf(id)).toMatchObject({
          stage: 'HALTED',
          stageBeforeHalt: stage,
        });
        // 같은 작업이 다시 돌아도 알림은 한 건씩이다.
        await scheduler.registry.run('brand-halt-check', {
          collaborationId: id,
        });
        expect(
          (await notificationTexts(authCreator)).filter((t) =>
            t.startsWith('협업이 잠시'),
          ),
        ).toHaveLength(1);
      }
    });

    it('does nothing at 60 days when the link was already submitted', async () => {
      const id = await approvedContract({ payoutDays: 14 });
      clock.set(new Date(NOON.getTime() + 50 * DAY));
      await submit(id, REEL).expect(200);
      // 링크를 내면 점검 작업이 지워진다.
      expect(jobsOf(`brand-halt:${id}`)).toHaveLength(0);
      // 취소가 실패한 것처럼 작업이 남아 있어도 단계를 보고 건너뛴다.
      await scheduler.schedule(
        'brand-halt-check',
        { collaborationId: id },
        new Date(NOON.getTime() + 60 * DAY),
        `brand-halt:${id}`,
      );
      clock.set(new Date(NOON.getTime() + 60 * DAY));
      const ran = await scheduler.runDue(clock.now());
      expect(ran.map((j) => j.name)).toContain('brand-halt-check');
      expect(ran.map((j) => j.name)).not.toContain('settle-fixed');
      expect((await collaborationOf(id)).stage).toBe('PUBLISHED');
      expect(alert).not.toHaveBeenCalled();
      expect(
        (await notificationTexts(authCreator)).filter((t) =>
          t.startsWith('협업이 잠시'),
        ),
      ).toHaveLength(0);
    });
  });

  describe('operator commands', () => {
    it('cancels a pending settle-fixed job when the collaboration is halted', async () => {
      const id = await approvedContract({ payoutDays: 7 });
      await submit(id, REEL).expect(200);
      expect(jobsOf(`settle-fixed:${id}`)).toHaveLength(1);

      const halted = await ops('halt', '--collaboration', id);
      expect(halted.exitCode).toBe(0);
      expect(scheduler.pending().map((j) => j.jobKey)).not.toContain(
        `settle-fixed:${id}`,
      );
      // 멈춘 동안에는 지급 시각이 지나도 돈이 움직이지 않는다.
      clock.set(new Date(NOON.getTime() + 8 * DAY));
      await scheduler.runDue(clock.now());
      expect((await collaborationOf(id)).stage).toBe('HALTED');
      expect(await prisma.settlement.count()).toBe(0);
    });

    it('resumes a published collaboration without paying before the payout time', async () => {
      const id = await approvedContract({ payoutDays: 14 });
      await submit(id, REEL).expect(200);
      await ops('halt', '--collaboration', id);
      clock.set(new Date(NOON.getTime() + 3 * DAY));
      const resumed = await ops('resume', '--collaboration', id);
      expect(resumed.exitCode).toBe(0);
      expect((await collaborationOf(id)).stage).toBe('PUBLISHED');
      const job = jobsOf(`settle-fixed:${id}`);
      expect(job).toHaveLength(1);
      expect(job[0].runAt).toEqual(new Date(NOON.getTime() + 14 * DAY));

      clock.set(new Date(NOON.getTime() + 14 * DAY - MINUTE));
      await scheduler.runDue(clock.now());
      expect(await prisma.settlement.count()).toBe(0);
      clock.set(new Date(NOON.getTime() + 14 * DAY));
      await scheduler.runDue(clock.now());
      expect((await collaborationOf(id)).stage).toBe('SETTLED');
    });

    it('pays right away when a published collaboration resumes after its payout time', async () => {
      const id = await approvedContract({ payoutDays: 7 });
      await submit(id, REEL).expect(200);
      await ops('halt', '--collaboration', id);
      clock.set(new Date(NOON.getTime() + 20 * DAY));
      await ops('resume', '--collaboration', id);
      expect(jobsOf(`settle-fixed:${id}`)[0].runAt).toEqual(clock.now());
      await scheduler.runDue(clock.now());
      expect((await collaborationOf(id)).stage).toBe('SETTLED');
      expect(await prisma.payout.count()).toBe(1);
    });

    it('re-registers the 60 day check from now when a collaboration halted for no link resumes', async () => {
      const id = await approvedContract();
      clock.set(new Date(NOON.getTime() + 60 * DAY));
      await scheduler.runDue(clock.now());
      expect((await collaborationOf(id)).haltedReason).toBe('NO_LINK_60_DAYS');

      clock.set(new Date(NOON.getTime() + 62 * DAY));
      const resumed = await ops('resume', '--collaboration', id);
      expect(resumed.exitCode).toBe(0);
      expect(await collaborationOf(id)).toMatchObject({
        stage: 'APPROVED',
        haltedReason: null,
        stageBeforeHalt: null,
      });
      const check = jobsOf(`brand-halt:${id}`).filter(
        (j) => j.status === 'pending',
      );
      expect(check).toHaveLength(1);
      expect(check[0].runAt).toEqual(
        new Date(clock.now().getTime() + 60 * DAY),
      );
    });

    it('leaves a resumed performance bonus contract published without a payout job', async () => {
      const id = await approvedContract({ performance: true, payoutDays: 7 });
      await submit(id, REEL).expect(200);
      await ops('halt', '--collaboration', id);
      clock.set(new Date(NOON.getTime() + 10 * DAY));
      await ops('resume', '--collaboration', id);
      expect((await collaborationOf(id)).stage).toBe('PUBLISHED');
      expect(
        jobsOf(`settle-fixed:${id}`).filter((j) => j.status === 'pending'),
      ).toHaveLength(0);
      await scheduler.runDue(clock.now());
      expect(await prisma.settlement.count()).toBe(0);
    });
  });
});
