import { INestApplication, Logger } from '@nestjs/common';
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
import { CollaborationsRepository } from '../src/collaborations/collaborations.repository';
import { ConversationsService } from '../src/conversations/conversations.service';
import { SubmissionsService } from '../src/settlements/submissions.service';

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
// 가짜 조회수는 주소의 views 값을 그대로 읽는다(12,500회 × 1,000회당 2,000원 = 25,000원).
const REEL_12500 = `${REEL}?views=12500`;
const authStranger = { Authorization: 'Bearer user-c' };
const NOON = new Date('2026-11-11T03:00:00.000Z');
const MINUTE = 60_000;
const DAY = 24 * 60 * MINUTE;
const WHO = ['--operator', '김운영', '--reason', '운영 확인 후 처리'];
const HOUR = 60 * MINUTE;

describe('brand contract settlement', () => {
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
  const report = (auth: Record<string, string>, id: string) =>
    request(server).get(`/collaborations/${id}/view-report`).set(auth);
  const confirmReport = (auth: Record<string, string>, id: string) =>
    request(server).post(`/collaborations/${id}/view-report/confirm`).set(auth);
  const dispute = (auth: Record<string, string>, id: string) =>
    request(server)
      .post(`/collaborations/${id}/view-report/dispute`)
      .set(auth)
      .send({ reason: '조회수가 실제와 달라요' });
  const collaborationModel = async (auth: Record<string, string>, id: string) =>
    (await request(server).get(`/collaborations/${id}`).set(auth).expect(200))
      .body as Record<string, unknown>;
  const walletOf = async () =>
    (await request(server).get('/wallet').set(authCreator).expect(200))
      .body as {
      heldAmount: number;
      nextPayout: { date: string; amount: number } | null;
      entries: Record<string, unknown>[];
    };
  // 한 협업의 장부는 언제나 합이 0이다(들어온 돈과 나간 돈이 같다).
  const expectBalanced = async (id: string) => {
    const sum = Object.values(await balanceOf(id)).reduce((a, b) => a + b, 0);
    expect(sum).toBe(0);
  };
  // 제출한 날(NOON)부터 하루씩 지정한 날까지 작업을 돌린다.
  async function runDays(from: number, to: number): Promise<void> {
    for (let day = from; day <= to; day += 1) {
      clock.set(new Date(NOON.getTime() + day * DAY));
      await scheduler.runDue(clock.now());
    }
  }
  // 성과 추가가 있는 계약(지급 조건 14일)을 링크 제출부터 측정 기간 끝(계산 만들기)까지 진행한다.
  async function calculated(
    opts: { payoutDays?: number; url?: string } = {},
  ): Promise<string> {
    const id = await approvedContract({
      performance: true,
      payoutDays: opts.payoutDays ?? 14,
    });
    await submit(id, opts.url ?? REEL_12500).expect(200);
    await runDays(0, opts.payoutDays ?? 14);
    return id;
  }

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

    it('pushes conversation.updated to both sides once the link is saved', async () => {
      const id = await approvedContract({ payoutDays: 7 });
      const room = await prisma.conversation.findUniqueOrThrow({
        where: { collaborationId: id },
      });
      realtime.sent.length = 0;
      // 받지 않은 제출에는 아무것도 가지 않는다.
      await submit(id, 'https://blog.naver.com/someone/1').expect(400);
      expect(realtime.receivedBy(USER_A, 'conversation.updated')).toEqual([]);
      await submit(id, REEL).expect(200);
      for (const userId of [USER_A, OTHER]) {
        expect(realtime.receivedBy(userId, 'conversation.updated')).toEqual([
          expect.objectContaining({
            payload: { conversationId: room.id, reason: 'STATUS' },
          }),
        ]);
      }
    });

    it('keeps a saved submission a 200 when refreshing the room fails', async () => {
      const id = await approvedContract({ payoutDays: 7 });
      const quiet = jest
        .spyOn(Logger.prototype, 'warn')
        .mockImplementation(() => undefined);
      const lookup = jest
        .spyOn(app.get(ConversationsService), 'idForCollaboration')
        .mockRejectedValueOnce(new Error('방을 찾지 못했어요'));
      await submit(id, REEL).expect(200);
      lookup.mockRestore();
      quiet.mockRestore();
      expect((await collaborationOf(id)).stage).toBe('PUBLISHED');
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
    it('schedules the measurement jobs at link submission instead of leaving the contract jobless', async () => {
      const id = await approvedContract({ performance: true, payoutDays: 14 });
      await submit(id, REEL_12500).expect(200);
      expect(await collaborationOf(id)).toMatchObject({
        stage: 'PUBLISHED',
        countingEndsAt: new Date(NOON.getTime() + 14 * DAY),
      });
      // 조회수는 0일째(지금)부터 14일째까지 하루 간격으로 읽고, 측정이 끝나는 시각에 정산 작업이 돈다.
      const snapshots = scheduler.jobs.filter(
        (j) => j.name === 'view-snapshot',
      );
      expect(snapshots).toHaveLength(15);
      for (const job of snapshots) {
        const day = (job.payload as { dayIndex: number }).dayIndex;
        expect(job.jobKey).toBe(`view-snapshot:${id}:${day}`);
        expect(job.runAt).toEqual(new Date(NOON.getTime() + day * DAY));
      }
      expect(jobsOf(`settle:${id}`)).toEqual([
        expect.objectContaining({
          name: 'settle',
          payload: { collaborationId: id },
          runAt: new Date(NOON.getTime() + 14 * DAY),
          status: 'pending',
        }),
      ]);
      // 지급 작업(settle-fixed)과 60일 점검은 올라가지 않는다.
      expect(jobsOf(`settle-fixed:${id}`)).toHaveLength(0);
      expect(jobsOf(`brand-halt:${id}`)).toHaveLength(0);
      // 작업이 잘못 올라가 직접 돌아도 settle-fixed는 지급하지 않는다.
      await app.get(SettlementsService).settleFixed(id, `settle:${id}`);
      expect((await collaborationOf(id)).stage).toBe('PUBLISHED');
      expect(await prisma.settlement.count()).toBe(0);
    });

    it('rejects a reels link that is not owned by the linked account when a bonus is agreed', async () => {
      const id = await approvedContract({ performance: true, payoutDays: 7 });
      const res = await submit(id, 'https://www.instagram.com/reel/notmine1/');
      expect(res.status).toBe(409);
      expect(codeOf(res)).toBe('CONFLICT');
      expect((await collaborationOf(id)).stage).toBe('APPROVED');
      // 측정·지급 작업은 하나도 올라가지 않는다.
      expect(
        scheduler.jobs.filter((j) =>
          ['view-snapshot', 'settle', 'settle-fixed'].includes(j.name),
        ),
      ).toEqual([]);
    });

    it('creates an unconfirmed calculation at the end of a 14 day measurement and moves no money', async () => {
      const id = await approvedContract({ performance: true, payoutDays: 14 });
      await submit(id, REEL_12500).expect(200);
      await runDays(0, 13);
      // 측정 중에는 계산이 없다: 집계 중이고 지금까지의 값만 보인다.
      expect(await prisma.settlement.count()).toBe(0);
      expect((await report(authBrand, id).expect(200)).body).toMatchObject({
        status: 'COUNTING',
        views: 12500,
        calc: null,
        canConfirm: false,
      });
      const before = await balanceOf(id);
      expect(before).toMatchObject({ ESCROW: 410000, FEE_REVENUE: 41000 });

      await runDays(14, 14);
      expect(await prisma.settlement.findFirstOrThrow({})).toMatchObject({
        collaborationId: id,
        status: 'UNCONFIRMED',
        evidenceSource: 'CONNECTED_ACCOUNT',
        finalViews: 12500,
        fixedCashAmount: 350000,
        viewPayAmount: 25000,
        payoutAmount: 375000,
        refundAmount: 35000,
        confirmDueAt: new Date(NOON.getTime() + 14 * DAY + 48 * HOUR),
        settledAt: null,
        confirmedBy: null,
      });
      // 장부와 단계는 그대로이고 지급·환급 행도 없다.
      expect(await balanceOf(id)).toEqual(before);
      expect((await collaborationOf(id)).stage).toBe('PUBLISHED');
      expect(await prisma.payout.count()).toBe(0);
      expect(await prisma.refund.count()).toBe(0);
      expect(await prisma.viewSnapshot.count()).toBe(15);
      expect(jobsOf(`auto-confirm:${id}`)).toEqual([
        expect.objectContaining({
          runAt: new Date(NOON.getTime() + 14 * DAY + 48 * HOUR),
        }),
      ]);
      expect((await report(authBrand, id).expect(200)).body).toMatchObject({
        kind: 'BRAND_CONTRACT',
        status: 'UNCONFIRMED',
        views: 12500,
        source: 'CONNECTED_ACCOUNT',
        calc: {
          viewPay: 25000,
          ratePerThousand: 2000,
          cap: 60000,
          capApplied: false,
          fixedCash: 350000,
          refund: 35000,
          payout: 375000,
        },
        canConfirm: true,
        canDispute: true,
      });
      expect((await report(authCreator, id).expect(200)).body).toMatchObject({
        status: 'UNCONFIRMED',
        canConfirm: false,
        canDispute: true,
      });
      expect(await notificationTexts(authBrand)).toContain(
        '조회수 집계가 끝났어요. 자료를 확인해 주세요.',
      );
      expect(await notificationTexts(authCreator)).toContain(
        '조회수 집계가 끝났어요. 계산을 확인해 보세요.',
      );
      await expectBalanced(id);
    });

    it('measures a 7 day period too and creates nothing one minute early', async () => {
      const id = await approvedContract({ performance: true, payoutDays: 7 });
      await submit(id, REEL_12500).expect(200);
      await runDays(0, 6);
      clock.set(new Date(NOON.getTime() + 7 * DAY - MINUTE));
      await scheduler.runDue(clock.now());
      expect(await prisma.settlement.count()).toBe(0);
      expect(await prisma.viewSnapshot.count()).toBe(7);
      clock.set(new Date(NOON.getTime() + 7 * DAY));
      await scheduler.runDue(clock.now());
      expect(await prisma.settlement.findFirstOrThrow({})).toMatchObject({
        status: 'UNCONFIRMED',
        payoutAmount: 375000,
      });
      expect(await prisma.viewSnapshot.count()).toBe(8);
    });

    it('pays the fee plus the earned bonus and refunds the rest of the cap when the brand confirms', async () => {
      const id = await calculated();
      await registerAccount();
      const res = await confirmReport(authBrand, id).expect(200);
      expect(res.body).toMatchObject({
        status: 'CONFIRMED',
        canConfirm: false,
      });

      expect((await collaborationOf(id)).stage).toBe('SETTLED');
      expect(await prisma.settlement.findFirstOrThrow({})).toMatchObject({
        status: 'CONFIRMED',
        confirmedBy: 'COMMISSIONER',
        payoutAmount: 375000,
        refundAmount: 35000,
      });
      const payout = await prisma.payout.findFirstOrThrow({});
      expect(payout).toMatchObject({ amount: 375000, status: 'PENDING' });
      // 송금은 확정된 주의 다음 주 수요일 10시(한국 시간)다.
      expect(payout.scheduledFor.toISOString()).toBe(
        '2026-12-02T01:00:00.000Z',
      );
      // 남은 상한은 돌려보낸다. 수수료는 돌려주지 않는다.
      expect(await prisma.refund.findFirstOrThrow({})).toMatchObject({
        amount: 35000,
        status: 'DONE',
      });
      expect(await balanceOf(id)).toEqual({
        PG_IN: -451000,
        ESCROW: 0,
        CREATOR_PAYABLE: 375000,
        STORE_REFUND: 35000,
        FEE_REVENUE: 41000,
      });
      await expectBalanced(id);
      expect(await notificationTexts(authCreator)).toContain(
        '정산 375,000원이 다음 주 수요일에 들어와요.',
      );
      // 사장님용 결과 알림은 브랜드에게 가지 않는다(브랜드는 송금 뒤 지급 알림을 받는다).
      expect(
        (await notificationTexts(authBrand)).filter((t) =>
          t.includes('돌려드려요'),
        ),
      ).toHaveLength(0);

      // 같은 확인이 다시 오거나 48시간 작업이 늦게 돌아도 한 번이다.
      await confirmReport(authBrand, id).expect(409);
      clock.set(new Date(NOON.getTime() + 20 * DAY));
      await scheduler.runDue(clock.now());
      expect(await prisma.settlement.count()).toBe(1);
      expect(await prisma.payout.count()).toBe(1);
      expect(await prisma.refund.count()).toBe(1);
      expect(await ledgerOf(id)).toHaveLength(4);

      // 지급일에 송금이 나가고 알림이 간다.
      clock.set(payout.scheduledFor);
      await scheduler.runDue(clock.now());
      expect(
        (await prisma.payout.findUniqueOrThrow({ where: { id: payout.id } }))
          .status,
      ).toBe('DONE');
      expect(await notificationTexts(authCreator)).toContain(
        '375,000원이 지급됐어요.',
      );
      expect(await notificationTexts(authBrand)).toContain(
        '375,000원을 크리에이터에게 지급했어요. 남은 35,000원은 돌려드려요.',
      );
    });

    it('caps the bonus and refunds nothing when the views reach the cap', async () => {
      const id = await calculated({ url: `${REEL}?views=100000` });
      await confirmReport(authBrand, id).expect(200);
      expect(await prisma.settlement.findFirstOrThrow({})).toMatchObject({
        payoutAmount: 410000,
        refundAmount: 0,
        viewPayAmount: 60000,
      });
      expect(await prisma.refund.count()).toBe(0);
      expect(await balanceOf(id)).toMatchObject({
        ESCROW: 0,
        CREATOR_PAYABLE: 410000,
      });
      await expectBalanced(id);
    });

    it('confirms automatically 48 hours after the calculation without a dispute', async () => {
      const id = await calculated();
      const dueAt = new Date(NOON.getTime() + 14 * DAY + 48 * HOUR);
      clock.set(new Date(dueAt.getTime() - MINUTE));
      await scheduler.runDue(clock.now());
      expect((await collaborationOf(id)).stage).toBe('PUBLISHED');
      expect(await prisma.payout.count()).toBe(0);

      clock.set(dueAt);
      await scheduler.runDue(clock.now());
      expect((await collaborationOf(id)).stage).toBe('SETTLED');
      expect(await prisma.settlement.findFirstOrThrow({})).toMatchObject({
        status: 'CONFIRMED',
        confirmedBy: 'AUTO',
        payoutAmount: 375000,
        refundAmount: 35000,
      });
      expect(await prisma.payout.findFirstOrThrow({})).toMatchObject({
        amount: 375000,
      });
      expect(await prisma.refund.findFirstOrThrow({})).toMatchObject({
        amount: 35000,
        status: 'DONE',
      });
      await expectBalanced(id);
    });

    it('lets only the brand confirm', async () => {
      const id = await approvedContract({ performance: true, payoutDays: 14 });
      await submit(id, REEL_12500).expect(200);
      // 측정 중에는 브랜드도 확인할 수 없다.
      expect(codeOf(await confirmReport(authBrand, id).expect(409))).toBe(
        'CONFLICT',
      );
      await runDays(0, 14);
      expect(codeOf(await confirmReport(authCreator, id).expect(403))).toBe(
        'FORBIDDEN',
      );
      expect(await confirmReport(authStranger, id).expect(404)).toBeDefined();
      expect(await report(authStranger, id).expect(404)).toBeDefined();
      expect((await collaborationOf(id)).stage).toBe('PUBLISHED');
      expect(await prisma.payout.count()).toBe(0);
    });

    for (const [label, who, other] of [
      ['the creator', authCreator, authBrand],
      ['the brand', authBrand, authCreator],
    ] as const) {
      it(`halts when ${label} disputes the calculation and keeps the money`, async () => {
        const id = await calculated();
        await flushMessages(app);
        const before = await balanceOf(id);
        const res = await dispute(who, id).expect(200);
        expect(res.body).toMatchObject({
          status: 'DISPUTED',
          canConfirm: false,
        });
        expect(await collaborationOf(id)).toMatchObject({
          stage: 'HALTED',
          stageBeforeHalt: 'PUBLISHED',
          haltedReason: 'SETTLEMENT_DISPUTED',
        });
        expect((await prisma.settlement.findFirstOrThrow({})).status).toBe(
          'DISPUTED',
        );
        expect(await balanceOf(id)).toEqual(before);
        expect(await prisma.payout.count()).toBe(0);
        expect(await prisma.refund.count()).toBe(0);
        // 48시간 작업이 지워지고, 운영자와 상대에게 알린다.
        expect(scheduler.pending().map((j) => j.jobKey)).not.toContain(
          `auto-confirm:${id}`,
        );
        expect(alert).toHaveBeenCalledWith(
          expect.objectContaining({
            subject: '조회 자료에 이의가 제기됐어요. 확인해 주세요.',
          }),
        );
        expect(await notificationTexts(other)).toContain(
          '조회 자료에 이의가 제기됐어요. 운영팀이 확인하고 연락드릴게요.',
        );
        // 시간이 지나도 돈은 움직이지 않고, 브랜드도 더는 확인할 수 없다.
        clock.set(new Date(NOON.getTime() + 20 * DAY));
        await scheduler.runDue(clock.now());
        expect(await prisma.payout.count()).toBe(0);
        await confirmReport(authBrand, id).expect(409);
        await dispute(who, id).expect(409);
        // 풀기 전에는 resume으로도 풀 수 없다(이의 처리가 정산을 끝낸다).
        const resumed = await ops('resume', '--collaboration', id);
        expect(resumed.exitCode).toBe(1);
        expect(resumed.output.join('\n')).toContain(
          '조회 자료 확인이 끝나지 않은',
        );
        await expectBalanced(id);
      });
    }

    it('settles a disputed calculation with the views the operator confirms', async () => {
      const id = await calculated();
      await dispute(authBrand, id).expect(200);
      const resolved = await ops(
        'resolve-dispute',
        '--collaboration',
        id,
        '--views',
        '20000',
      );
      expect(resolved.exitCode).toBe(0);
      expect((await collaborationOf(id)).stage).toBe('SETTLED');
      // 20,000회 × 2,000원 = 40,000원: 제작비 350,000 + 40,000 = 390,000, 상한에서 남은 20,000원 환급.
      expect(await prisma.settlement.findFirstOrThrow({})).toMatchObject({
        status: 'CONFIRMED',
        confirmedBy: 'OPERATOR',
        finalViews: 20000,
        payoutAmount: 390000,
        refundAmount: 20000,
      });
      expect(await prisma.payout.findFirstOrThrow({})).toMatchObject({
        amount: 390000,
      });
      expect(await prisma.refund.findFirstOrThrow({})).toMatchObject({
        amount: 20000,
        status: 'DONE',
      });
      await expectBalanced(id);
      // 끝난 협업은 다시 열 수 없다.
      expect((await ops('resume', '--collaboration', id)).exitCode).toBe(1);
    });

    it('halts when the views cannot be read and settles with the views the operator gives', async () => {
      const id = await approvedContract({ performance: true, payoutDays: 7 });
      await submit(id, `${REEL}?unavailable`).expect(200);
      await runDays(0, 7);
      // 읽지 못해 캡처를 요청하고, 기간이 끝난 뒤 3일까지 기다린다.
      expect(await prisma.settlement.count()).toBe(0);
      expect(await notificationTexts(authCreator)).toContain(
        '조회수를 읽지 못했어요. 인사이트 캡처를 올려 주세요.',
      );
      clock.set(new Date(NOON.getTime() + 10 * DAY));
      await scheduler.runDue(clock.now());
      expect(await collaborationOf(id)).toMatchObject({
        stage: 'HALTED',
        stageBeforeHalt: 'PUBLISHED',
        haltedReason: 'VIEW_COUNT_UNAVAILABLE',
      });
      expect(await notificationTexts(authBrand)).toContain(
        '협업이 잠시 멈췄어요. 운영팀이 확인하고 연락드릴게요.',
      );
      const settled = await ops(
        'resume-settlement',
        '--collaboration',
        id,
        '--views',
        '12500',
      );
      expect(settled.exitCode).toBe(0);
      expect((await collaborationOf(id)).stage).toBe('SETTLED');
      expect(await prisma.settlement.findFirstOrThrow({})).toMatchObject({
        confirmedBy: 'OPERATOR',
        payoutAmount: 375000,
        refundAmount: 35000,
      });
      await expectBalanced(id);
    });

    it('keeps every brand collaboration ledger balanced across halt, resume and the bonus path', async () => {
      const id = await approvedContract({ performance: true, payoutDays: 14 });
      await expectBalanced(id);
      await submit(id, REEL_12500).expect(200);
      await expectBalanced(id);
      await runDays(0, 3);
      expect((await ops('halt', '--collaboration', id)).exitCode).toBe(0);
      await expectBalanced(id);
      clock.set(new Date(NOON.getTime() + 5 * DAY));
      expect((await ops('resume', '--collaboration', id)).exitCode).toBe(0);
      await expectBalanced(id);
      await runDays(5, 14);
      await expectBalanced(id);
      await confirmReport(authBrand, id).expect(200);
      await expectBalanced(id);
      expect(await balanceOf(id)).toMatchObject({ ESCROW: 0 });
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

    it('resumes the measurement of a halted bonus contract without settling early', async () => {
      const id = await approvedContract({ performance: true, payoutDays: 14 });
      await submit(id, REEL_12500).expect(200);
      await runDays(0, 3);
      await ops('halt', '--collaboration', id);
      // 멈추면 조회수·정산 작업이 모두 지워진다.
      expect(scheduler.pending().filter((j) => j.jobKey.includes(id))).toEqual(
        [],
      );
      clock.set(new Date(NOON.getTime() + 5 * DAY));
      const resumed = await ops('resume', '--collaboration', id);
      expect(resumed.exitCode).toBe(0);
      expect((await collaborationOf(id)).stage).toBe('PUBLISHED');
      // 기록되지 않은 날(4~14일째)의 조회수 작업은 원래 시각으로, 정산은 원래 정산 시각으로 다시 올라간다. 지급 작업은 없다.
      const pending = scheduler
        .pending()
        .filter((j) => j.name === 'view-snapshot');
      expect(
        pending.map((j) => (j.payload as { dayIndex: number }).dayIndex),
      ).toEqual(Array.from({ length: 11 }, (_, i) => i + 4));
      expect(jobsOf(`settle:${id}`)[0].runAt).toEqual(
        new Date(NOON.getTime() + 14 * DAY),
      );
      expect(jobsOf(`settle-fixed:${id}`)).toHaveLength(0);
      expect(jobsOf(`brand-halt:${id}`)).toHaveLength(0);

      await runDays(5, 13);
      expect(await prisma.settlement.count()).toBe(0);
      await runDays(14, 14);
      expect(await prisma.settlement.findFirstOrThrow({})).toMatchObject({
        status: 'UNCONFIRMED',
        payoutAmount: 375000,
      });
    });
  });
  describe('what the app reads', () => {
    it('shows the creator and the brand the settlement on the collaboration model', async () => {
      const id = await calculated();
      // 계산이 나왔지만 확인 전이라 정산으로 보이지 않는다.
      expect(await collaborationModel(authBrand, id)).toMatchObject({
        stage: 'PUBLISHED',
        kind: 'BRAND_CONTRACT',
        viewReportStatus: 'UNCONFIRMED',
        settlement: null,
        payoutStatus: 'NONE',
        currentViews: 12500,
        // 결제할 때 맡긴 금액(제작비 + 성과 추가 상한). 지갑의 보관 중 금액과 같다.
        escrowAmount: 410000,
      });
      expect((await walletOf()).heldAmount).toBe(410000);
      await confirmReport(authBrand, id).expect(200);
      // 계좌가 없으면 크리에이터에게만 계좌 등록이 필요하다고 보인다.
      expect(await collaborationModel(authCreator, id)).toMatchObject({
        stage: 'SETTLED',
        viewReportStatus: 'CONFIRMED',
        settlement: {
          finalViews: 12500,
          payoutAmount: 375000,
          refundAmount: 35000,
        },
        payoutStatus: 'NEEDS_ACCOUNT',
        payoutScheduledFor: null,
      });
      expect(await collaborationModel(authBrand, id)).toMatchObject({
        settlement: {
          finalViews: 12500,
          payoutAmount: 375000,
          refundAmount: 35000,
        },
        payoutStatus: 'PENDING',
        payoutScheduledFor: null,
      });
      await registerAccount();
      expect(await collaborationModel(authCreator, id)).toMatchObject({
        payoutStatus: 'PENDING',
        payoutScheduledFor: '2026-12-02T01:00:00.000Z',
      });
      const payout = await prisma.payout.findFirstOrThrow({});
      clock.set(payout.scheduledFor);
      await scheduler.runDue(clock.now());
      expect(await collaborationModel(authCreator, id)).toMatchObject({
        payoutStatus: 'DONE',
      });
    });

    it('shows the live amount to each side while the period runs', async () => {
      const id = await approvedContract({ performance: true, payoutDays: 7 });
      await submit(id, REEL_12500).expect(200);
      await runDays(0, 2);
      expect(await collaborationModel(authCreator, id)).toMatchObject({
        viewReportStatus: 'COUNTING',
        currentViews: 12500,
        earnedSoFar: 375000,
        expectedRefund: null,
      });
      expect(await collaborationModel(authBrand, id)).toMatchObject({
        earnedSoFar: null,
        expectedRefund: 35000,
      });
    });

    it('shows the fixed payout of a contract without a bonus in the same fields', async () => {
      const id = await approvedContract({ payoutDays: 7 });
      await submit(id, REEL).expect(200);
      clock.set(new Date(NOON.getTime() + 7 * DAY));
      await scheduler.runDue(clock.now());
      expect(await collaborationModel(authCreator, id)).toMatchObject({
        viewReportStatus: 'NONE',
        settlement: { finalViews: null, payoutAmount: 350000, refundAmount: 0 },
        payoutStatus: 'NEEDS_ACCOUNT',
      });
    });

    it('lists the brand contract money on the creator wallet', async () => {
      const id = await approvedContract({ performance: true, payoutDays: 14 });
      // 체결 직후부터 보관 중으로 보인다(상한까지 포함한 410,000원).
      let wallet = await walletOf();
      expect(wallet.heldAmount).toBe(410000);
      expect(wallet.entries).toEqual([
        expect.objectContaining({
          collaborationId: id,
          kind: 'HELD',
          amount: 410000,
          counterpartName: '느린결',
          format: 'REELS',
          pieces: 1,
          stage: 'APPROVED',
        }),
      ]);
      await submit(id, REEL_12500).expect(200);
      await runDays(0, 14);
      wallet = await walletOf();
      expect(wallet.entries).toEqual([
        expect.objectContaining({ kind: 'HELD', stage: 'PUBLISHED' }),
      ]);
      await registerAccount();
      await confirmReport(authBrand, id).expect(200);
      wallet = await walletOf();
      expect(wallet.heldAmount).toBe(0);
      expect(wallet.nextPayout).toEqual({ date: '2026-12-02', amount: 375000 });
      expect(wallet.entries).toEqual([
        expect.objectContaining({
          kind: 'PAYOUT_SCHEDULED',
          amount: 375000,
          views: 12500,
          counterpartName: '느린결',
          stage: 'SETTLED',
        }),
      ]);
      const payout = await prisma.payout.findFirstOrThrow({});
      clock.set(payout.scheduledFor);
      await scheduler.runDue(clock.now());
      wallet = await walletOf();
      expect(wallet.entries).toEqual([
        expect.objectContaining({ kind: 'PAYOUT_DONE', amount: 375000 }),
      ]);
    });

    it('answers 404 for the view report of a brand collaboration without a concluded contract', async () => {
      const id = await agreed();
      for (const stage of ['INQUIRY', 'AGREED', 'DROPPED'] as const) {
        await prisma.collaboration.update({ where: { id }, data: { stage } });
        for (const auth of [authBrand, authCreator]) {
          expect(codeOf(await report(auth, id).expect(404))).toBe('NOT_FOUND');
        }
        await confirmReport(authBrand, id).expect(404);
        await dispute(authCreator, id).expect(404);
        await request(server)
          .post(`/collaborations/${id}/view-evidence`)
          .set(authCreator)
          .send({ path: `evidence/${OTHER}/x.jpg`, views: 100 })
          .expect(404);
      }
    });

    it('keeps a brand collaboration without a concluded contract off the wallet', async () => {
      await agreed();
      expect((await walletOf()).entries).toEqual([]);
    });
  });

  describe('operator force commands on a brand contract', () => {
    it('refuses a forced refund until the collaboration is halted, then refunds the fee and the cap', async () => {
      const id = await approvedContract({ performance: true, payoutDays: 14 });
      await submit(id, REEL_12500).expect(200);
      await runDays(0, 2);
      const early = await ops('force-refund', '--collaboration', id);
      expect(early.exitCode).toBe(1);
      expect(early.output.join('\n')).toContain('멈춘(HALTED) 뒤에');
      expect((await collaborationOf(id)).stage).toBe('PUBLISHED');
      await ops('halt', '--collaboration', id);
      const refunded = await ops('force-refund', '--collaboration', id);
      expect(refunded.exitCode).toBe(0);
      expect((await collaborationOf(id)).stage).toBe('REFUNDED');
      expect(await prisma.refund.findFirstOrThrow({})).toMatchObject({
        amount: 451000,
        status: 'DONE',
      });
      expect(await balanceOf(id)).toMatchObject({
        ESCROW: 0,
        FEE_REVENUE: 0,
        STORE_REFUND: 451000,
      });
      await expectBalanced(id);
      expect(await prisma.payout.count()).toBe(0);
    });

    it('forces a payout from a published contract and tells the brand what was paid and returned', async () => {
      const id = await approvedContract({ performance: true, payoutDays: 14 });
      await registerAccount();
      // 링크 전에는 강제 지급도 멈춘 뒤에만 된다.
      const early = await ops(
        'force-payout',
        '--collaboration',
        id,
        '--amount',
        '100000',
      );
      expect(early.exitCode).toBe(1);
      expect(early.output.join('\n')).toContain('PUBLISHED');
      await submit(id, REEL_12500).expect(200);
      await runDays(0, 2);
      const forced = await ops(
        'force-payout',
        '--collaboration',
        id,
        '--amount',
        '200000',
      );
      expect(forced.exitCode).toBe(0);
      expect((await collaborationOf(id)).stage).toBe('SETTLED');
      expect(await prisma.payout.findFirstOrThrow({})).toMatchObject({
        amount: 200000,
        status: 'PENDING',
      });
      expect(await prisma.refund.findFirstOrThrow({})).toMatchObject({
        amount: 210000,
        status: 'DONE',
      });
      expect(await balanceOf(id)).toMatchObject({
        ESCROW: 0,
        CREATOR_PAYABLE: 200000,
        STORE_REFUND: 210000,
        FEE_REVENUE: 41000,
      });
      await expectBalanced(id);
      expect(await notificationTexts(authCreator)).toContain(
        '정산 200,000원이 다음 주 수요일에 들어와요.',
      );
      // 측정 작업은 모두 지워진다.
      expect(scheduler.pending().filter((j) => j.jobKey.includes(id))).toEqual(
        [],
      );
      const payout = await prisma.payout.findFirstOrThrow({});
      clock.set(payout.scheduledFor);
      await scheduler.runDue(clock.now());
      expect(await notificationTexts(authBrand)).toContain(
        '200,000원을 크리에이터에게 지급했어요. 남은 210,000원은 돌려드려요.',
      );
      // 사장님용 결과 알림은 브랜드에게 가지 않는다.
      expect(
        (await notificationTexts(authBrand)).filter((t) =>
          t.startsWith('조회수 집계가 끝났어요'),
        ),
      ).toHaveLength(0);
    });
  });

  describe('forced payout wording', () => {
    it('uses the plain fixed payout copy when the contract had no bonus', async () => {
      const id = await approvedContract({ payoutDays: 7 });
      await registerAccount();
      await submit(id, REEL).expect(200);
      const forced = await ops(
        'force-payout',
        '--collaboration',
        id,
        '--amount',
        '200000',
      );
      expect(forced.exitCode).toBe(0);
      const payout = await prisma.payout.findFirstOrThrow({});
      clock.set(payout.scheduledFor);
      await scheduler.runDue(clock.now());
      const texts = await notificationTexts(authBrand);
      expect(texts).toContain('제작비 200,000원을 크리에이터에게 지급했어요.');
      expect(texts.filter((t) => t.includes('남은'))).toHaveLength(0);
    });
  });

  describe('robustness of the first payout', () => {
    it('pays once when two settle-fixed jobs run at the same time for the first time', async () => {
      const id = await approvedContract({ payoutDays: 7 });
      await submit(id, REEL).expect(200);
      // 지급 시각에 작업 둘이 동시에 처음 돈다(아무도 정산하지 않은 PUBLISHED에서 조건부 갱신을 두고 겨룬다).
      clock.set(new Date(NOON.getTime() + 7 * DAY));
      const settlements = app.get(SettlementsService);
      await Promise.all([
        settlements.settleFixed(id, `settle:${id}`),
        settlements.settleFixed(id, `settle:${id}`),
      ]);
      expect((await collaborationOf(id)).stage).toBe('SETTLED');
      expect(await prisma.settlement.count()).toBe(1);
      expect(await prisma.payout.count()).toBe(1);
      expect(await prisma.refund.count()).toBe(0);
      // 장부: 결제 승인 두 줄 + 정산 한 줄. 정산 줄이 두 번 생기지 않는다.
      expect(await ledgerOf(id)).toHaveLength(3);
      expect(
        (await notificationTexts(authCreator)).filter((t) =>
          t.startsWith('정산 350,000원'),
        ),
      ).toHaveLength(1);
      await expectBalanced(id);
    });

    it('reverts the submission and keeps the original error when the jobs cannot be scheduled', async () => {
      const id = await approvedContract({ performance: true, payoutDays: 7 });
      // 의도한 실패라 Nest 로거의 오류 줄을 조용히 한다.
      const quiet = jest
        .spyOn(Logger.prototype, 'error')
        .mockImplementation(() => undefined);
      const advance = jest.spyOn(app.get(CollaborationsRepository), 'advance');
      const schedule = jest
        .spyOn(scheduler, 'schedule')
        .mockRejectedValueOnce(new Error('큐에 올리지 못했어요'));
      // 되돌리기도 실패하는 최악의 경우: 처음의 오류가 가려지지 않는다.
      advance
        .mockImplementationOnce((...args) =>
          CollaborationsRepository.prototype.advance.apply(
            app.get(CollaborationsRepository),
            args,
          ),
        )
        .mockRejectedValueOnce(new Error('되돌리지 못했어요'));
      await expect(
        app.get(SubmissionsService).submit(OTHER, id, REEL_12500),
      ).rejects.toThrow('큐에 올리지 못했어요');
      advance.mockRestore();
      schedule.mockRestore();
      quiet.mockRestore();
    });

    it('reverts a bonus contract submission to APPROVED so the creator can submit again', async () => {
      const id = await approvedContract({ performance: true, payoutDays: 7 });
      const quiet = jest
        .spyOn(Logger.prototype, 'error')
        .mockImplementation(() => undefined);
      const schedule = jest
        .spyOn(scheduler, 'schedule')
        .mockRejectedValueOnce(new Error('큐에 올리지 못했어요'));
      await request(server)
        .post(`/collaborations/${id}/submission`)
        .set(authCreator)
        .send({ url: REEL_12500 })
        .expect(500);
      schedule.mockRestore();
      quiet.mockRestore();
      expect(await collaborationOf(id)).toMatchObject({
        stage: 'APPROVED',
        submittedUrl: null,
        submittedAt: null,
        countingEndsAt: null,
      });
      await submit(id, REEL_12500).expect(200);
      expect((await collaborationOf(id)).stage).toBe('PUBLISHED');
    });
  });
});
