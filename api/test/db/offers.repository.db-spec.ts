import { OfferVersionsRepository } from '../../src/offers/offer-versions.repository';
import { OffersRepository } from '../../src/offers/offers.repository';
import { termsModelOf } from '../../src/stores/reward-terms';
import { createOffer } from '../helpers/create-offer';
import { prisma } from './setup-db';

const OWNER = '55555555-5555-4555-8555-555555555551';
const OTHER_OWNER = '55555555-5555-4555-8555-555555555552';
const CREATOR = '55555555-5555-4555-8555-555555555553';
const T0 = new Date('2026-12-01T00:00:00.000Z');
const SECOND = 1000;
const DAY = 24 * 60 * 60 * SECOND;
const at = (ms: number) => new Date(T0.getTime() + ms);

let storeId: string;
let otherStoreId: string;

describe('OffersRepository', () => {
  const repo = new OffersRepository(
    prisma as never,
    new OfferVersionsRepository(),
  );

  beforeEach(async () => {
    await prisma.user.createMany({
      data: [
        { id: OWNER, role: 'STORE' },
        { id: OTHER_OWNER, role: 'STORE' },
        { id: CREATOR, role: 'CREATOR' },
      ],
    });
    storeId = (await prisma.store.create({ data: { ownerId: OWNER } })).id;
    otherStoreId = (
      await prisma.store.create({ data: { ownerId: OTHER_OWNER } })
    ).id;
  });

  const base = (over: { storeId?: string } = {}) => ({
    storeId: over.storeId ?? storeId,
    creatorId: CREATOR,
    applicationId: null,
    terms: termsModelOf(
      'REELS',
      {
        voucherName: '식사권',
        voucherValue: 40000,
        voucherPeople: 2,
        fixedCash: 0,
        viewRatePerThousand: null,
        perViewCap: null,
      },
      'STORE_REPOST_3M',
    ),
    createdAt: T0,
    expiresAt: at(7 * DAY),
  });
  const statusOf = async (id: string) =>
    (await prisma.offer.findUniqueOrThrow({ where: { id } })).status;

  it('returns null instead of throwing when an open offer already exists', async () => {
    expect(await repo.create(base())).not.toBeNull();
    expect(await repo.create(base())).toBeNull();
    expect(await prisma.offer.count()).toBe(1);
  });

  it('lets only one of two concurrent creates win', async () => {
    const results = await Promise.all([
      repo.create(base()),
      repo.create(base()),
    ]);
    expect(results.filter((r) => r !== null)).toHaveLength(1);
  });

  it('hides another store or creator offer behind the owner condition', async () => {
    const offer = (await repo.create(base()))!;
    expect(await repo.findForStore(offer.id, otherStoreId)).toBeNull();
    expect(await repo.findForStore(offer.id, storeId)).not.toBeNull();
    expect(await repo.findForCreator(offer.id, OWNER)).toBeNull();
    expect(await repo.findForCreator(offer.id, CREATOR)).not.toBeNull();
  });

  it('accepts only once, and only before the deadline', async () => {
    const offer = (await repo.create(base()))!;
    expect(
      await repo.accept(offer.id, CREATOR, 1, at(7 * DAY), at(10 * DAY)),
    ).toBe(false);
    expect(await repo.accept(offer.id, CREATOR, 1, at(DAY), at(4 * DAY))).toBe(
      true,
    );
    expect(await repo.accept(offer.id, CREATOR, 1, at(DAY), at(4 * DAY))).toBe(
      false,
    );
    expect(
      await prisma.offer.findUniqueOrThrow({ where: { id: offer.id } }),
    ).toMatchObject({
      status: 'ACCEPTED',
      acceptedAt: at(DAY),
      paymentDueAt: at(4 * DAY),
    });
  });

  it('refuses to accept a version number that is not the latest', async () => {
    const offer = (await repo.create(base()))!;
    expect(await repo.accept(offer.id, CREATOR, 2, T0, at(3 * DAY))).toBe(
      false,
    );
    // 새 판본이 나오면(번호가 올라가면) 옛 번호의 수락은 0행이다. 읽은 뒤 판본이 나온 경쟁을 흉내 낸다.
    await prisma.offer.update({
      where: { id: offer.id },
      data: { latestVersion: 2 },
    });
    expect(await repo.accept(offer.id, CREATOR, 1, T0, at(3 * DAY))).toBe(
      false,
    );
    expect(await statusOf(offer.id)).toBe('SENT');
    expect(await repo.accept(offer.id, CREATOR, 2, T0, at(3 * DAY))).toBe(true);
  });

  it('creates the offer and version 1 together', async () => {
    const offer = (await repo.create(base()))!;
    expect(offer).toMatchObject({
      latestVersion: 1,
      turn: 'CREATOR',
      initiatedBy: 'STORE',
    });
    expect(offer.versions).toHaveLength(1);
    expect(offer.versions[0]).toMatchObject({
      number: 1,
      authorParty: 'STORE',
      voucherName: '식사권',
      createdAt: T0,
    });
  });

  it('refuses a response from someone who is not the recipient', async () => {
    const offer = (await repo.create(base()))!;
    expect(await repo.accept(offer.id, OWNER, 1, T0, at(3 * DAY))).toBe(false);
    expect(await repo.decline(offer.id, OWNER, T0)).toBe(false);
    expect(await statusOf(offer.id)).toBe('SENT');
  });

  it('lets exactly one of accept and decline win', async () => {
    const offer = (await repo.create(base()))!;
    const results = await Promise.all([
      repo.accept(offer.id, CREATOR, 1, T0, at(3 * DAY)),
      repo.decline(offer.id, CREATOR, T0),
    ]);
    expect(results.filter(Boolean)).toHaveLength(1);
  });

  it('undoes a decline only inside the 30 second window', async () => {
    const offer = (await repo.create(base()))!;
    await repo.decline(offer.id, CREATOR, T0);
    expect(await repo.undoDecline(offer.id, CREATOR, at(30 * SECOND))).toBe(
      false,
    );
    expect(await repo.undoDecline(offer.id, CREATOR, at(29 * SECOND))).toBe(
      true,
    );
    expect(
      await prisma.offer.findUniqueOrThrow({ where: { id: offer.id } }),
    ).toMatchObject({ status: 'SENT', declinedAt: null, respondedAt: null });
  });

  it('refuses an undo that would collide with a newer open offer', async () => {
    const first = (await repo.create(base()))!;
    await repo.decline(first.id, CREATOR, T0);
    // 이 저장소는 되돌리기 중인 거절을 열린 것으로 보지 않는 직접 삽입 경로(서비스 밖)도 막아야 한다.
    await createOffer(prisma, {
      storeId,
      creatorId: CREATOR,
      format: 'REELS',
      status: 'SENT',
      createdAt: T0,
      expiresAt: at(7 * DAY),
    });
    expect(await repo.undoDecline(first.id, CREATOR, at(SECOND))).toBe(false);
    expect(await statusOf(first.id)).toBe('DECLINED');
  });

  it('cancels only from the expected status and before its deadline', async () => {
    const offer = (await repo.create(base()))!;
    expect(await repo.cancel(offer.id, otherStoreId, 'SENT', T0)).toBe(false);
    expect(await repo.cancel(offer.id, storeId, 'ACCEPTED', T0)).toBe(false);
    expect(await repo.cancel(offer.id, storeId, 'SENT', at(7 * DAY))).toBe(
      false,
    );
    expect(await repo.cancel(offer.id, storeId, 'SENT', T0)).toBe(true);
    expect(await repo.cancel(offer.id, storeId, 'SENT', T0)).toBe(false);
    expect(await statusOf(offer.id)).toBe('CANCELLED');
  });

  it('cancels an accepted offer only before its payment deadline', async () => {
    const offer = (await repo.create(base()))!;
    await repo.accept(offer.id, CREATOR, 1, T0, at(3 * DAY));
    expect(await repo.cancel(offer.id, storeId, 'ACCEPTED', at(3 * DAY))).toBe(
      false,
    );
    expect(await repo.cancel(offer.id, storeId, 'ACCEPTED', at(2 * DAY))).toBe(
      true,
    );
  });

  it('expires only when the stored status is still the one that was read', async () => {
    const offer = (await repo.create(base()))!;
    expect(await repo.expire(offer.id, 'ACCEPTED')).toBe(false);
    expect(await repo.expire(offer.id, 'SENT')).toBe(true);
    expect(await repo.expire(offer.id, 'SENT')).toBe(false);
    expect(await statusOf(offer.id)).toBe('EXPIRED');
  });

  it('finds open offers including an undoable decline', async () => {
    const offer = (await repo.create(base()))!;
    await repo.decline(offer.id, CREATOR, T0);
    expect(await repo.findOpen(storeId, CREATOR, at(29 * SECOND))).toHaveLength(
      1,
    );
    expect(await repo.findOpen(storeId, CREATOR, at(30 * SECOND))).toHaveLength(
      0,
    );
  });

  it('lists the store offers most recent first and the creator offers in arrival order', async () => {
    const first = (await repo.create({ ...base(), createdAt: at(0) }))!;
    await repo.cancel(first.id, storeId, 'SENT', T0);
    const second = (await repo.create({ ...base(), createdAt: at(DAY) }))!;
    expect((await repo.listForStore(storeId)).map((o) => o.id)).toEqual([
      second.id,
      first.id,
    ]);
    // 받은 오퍼 목록은 취소된 것을 읽지 않는다.
    expect((await repo.listForCreator(CREATOR)).map((o) => o.id)).toEqual([
      second.id,
    ]);
  });

  describe('proposing versions and ending', () => {
    const proposal = (
      offerId: string,
      over: Partial<Parameters<typeof repo.propose>[0]> = {},
    ) => ({
      offerId,
      author: 'CREATOR' as const,
      readVersion: 1,
      terms: base().terms,
      idea: null,
      principles: [],
      now: at(DAY),
      expiresAt: at(8 * DAY),
      ...over,
    });
    const offerOf = (id: string) =>
      prisma.offer.findUniqueOrThrow({ where: { id } });

    it('raises the number, passes the turn and restarts the deadline in one step', async () => {
      const offer = (await repo.create(base()))!;
      const created = await repo.propose(proposal(offer.id));
      expect(created).toMatchObject({
        number: 2,
        authorParty: 'CREATOR',
        createdAt: at(DAY),
      });
      expect(await offerOf(offer.id)).toMatchObject({
        latestVersion: 2,
        turn: 'STORE',
        expiresAt: at(8 * DAY),
      });
    });

    it('returns null and adds no version when the read number is stale', async () => {
      const offer = (await repo.create(base()))!;
      expect(await repo.propose(proposal(offer.id))).not.toBeNull();
      expect(
        await repo.propose(proposal(offer.id, { author: 'STORE' })),
      ).toBeNull();
      expect(await prisma.offerVersion.count()).toBe(2);
    });

    it('returns null when it is not the turn of the author', async () => {
      const offer = (await repo.create(base()))!;
      expect(
        await repo.propose(proposal(offer.id, { author: 'STORE' })),
      ).toBeNull();
    });

    it('returns null once the offer is accepted, and the accept loses to a newer version', async () => {
      const accepted = (await repo.create(base()))!;
      expect(await repo.accept(accepted.id, CREATOR, 1, at(DAY), null)).toBe(
        true,
      );
      expect(await repo.propose(proposal(accepted.id))).toBeNull();
      expect(await prisma.offerVersion.count()).toBe(1);

      await prisma.offer.update({
        where: { id: accepted.id },
        data: { status: 'CANCELLED' },
      });
      const offer = (await repo.create(base()))!;
      expect(await repo.propose(proposal(offer.id))).not.toBeNull();
      expect(await repo.accept(offer.id, CREATOR, 1, at(DAY), null)).toBe(
        false,
      );
    });

    it('does not propose after the deadline', async () => {
      const offer = (await repo.create(base()))!;
      expect(
        await repo.propose(proposal(offer.id, { now: at(7 * DAY) })),
      ).toBeNull();
    });

    it('ends with the reason and the party, only for the version that was read', async () => {
      const offer = (await repo.create(base()))!;
      expect(
        await repo.end(offer.id, 'CREATOR', 'DECLINED', 'TERMS', 2, at(DAY)),
      ).toBe(false);
      expect(
        await repo.end(offer.id, 'CREATOR', 'DECLINED', 'TERMS', 1, at(DAY)),
      ).toBe(true);
      expect(await offerOf(offer.id)).toMatchObject({
        status: 'DECLINED',
        endReason: 'TERMS',
        endedBy: 'CREATOR',
        declinedAt: null,
        respondedAt: at(DAY),
      });
      expect(
        await repo.end(offer.id, 'CREATOR', 'DECLINED', 'TERMS', 1, at(DAY)),
      ).toBe(false);
    });

    it('refuses to cancel a sent offer once the creator wrote the latest version', async () => {
      const offer = (await repo.create(base()))!;
      expect(await repo.propose(proposal(offer.id))).not.toBeNull();
      expect(await repo.cancel(offer.id, storeId, 'SENT', at(DAY))).toBe(false);
      expect(await statusOf(offer.id)).toBe('SENT');
    });

    it('declines only on the creator turn and stores NO_REASON', async () => {
      const offer = (await repo.create(base()))!;
      await repo.propose(proposal(offer.id));
      expect(await repo.decline(offer.id, CREATOR, at(DAY))).toBe(false);
      const other = (await repo.create({ ...base(), storeId: otherStoreId }))!;
      expect(await repo.decline(other.id, CREATOR, at(DAY))).toBe(true);
      expect(await offerOf(other.id)).toMatchObject({
        endReason: 'NO_REASON',
        endedBy: 'CREATOR',
      });
    });
  });
});
