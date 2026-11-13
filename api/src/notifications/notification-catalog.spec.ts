import { NotificationKind } from '@prisma/client';
import {
  NOTIFICATION_CATALOG,
  missingNotifyInputs,
} from './notification-catalog';

const render = (
  kind: NotificationKind,
  actorName: string | null,
  params: Record<string, string | number> = {},
) => NOTIFICATION_CATALOG[kind].render({ actorName, params });

describe('NOTIFICATION_CATALOG', () => {
  it('renders the canvas offer text', () => {
    expect(
      render('OFFER_RECEIVED', '한그릇 라멘', {
        format: 'REELS',
        pieceCount: 1,
      }),
    ).toBe('한그릇 라멘이 릴스 1편 오퍼를 보냈어요.');
    expect(
      render('OFFER_RECEIVED', '모아 스튜디오', {
        format: 'CARD_NEWS',
        pieceCount: 2,
      }),
    ).toBe('모아 스튜디오가 카드뉴스 2편 오퍼를 보냈어요.');
  });

  it('renders the canvas settlement text', () => {
    expect(render('SETTLEMENT_CONFIRMED', null, { amount: 43200 })).toBe(
      '정산 43,200원이 다음 주 수요일에 들어와요.',
    );
  });

  it('renders the texts of the other kinds', () => {
    expect(render('APPLICATION_RECEIVED', '하루 한 컵')).toBe(
      '하루 한 컵님이 지원했어요.',
    );
    expect(render('OFFER_ACCEPTED', '하루 한 컵')).toBe(
      '하루 한 컵님이 오퍼를 수락했어요.',
    );
    expect(render('OFFER_DECLINED', '하루 한 컵')).toBe(
      '하루 한 컵님이 이번 오퍼는 함께하기 어렵대요.',
    );
    expect(render('PAYMENT_FUNDED', '한그릇 라멘')).toBe(
      '한그릇 라멘이 결제했어요. 방문하고 촬영해 주세요.',
    );
    expect(render('PAYMENT_FUNDED', '모아 스튜디오')).toBe(
      '모아 스튜디오가 결제했어요. 방문하고 촬영해 주세요.',
    );
    expect(render('CONTENT_SUBMITTED', '하루 한 컵')).toBe(
      '하루 한 컵님이 콘텐츠를 올렸어요.',
    );
    expect(render('SUBMIT_REMINDER', null, { days: 3 })).toBe(
      '콘텐츠 제출 기한이 3일 남았어요.',
    );
    expect(render('UNSUBMITTED_ENDED', null)).toBe(
      '제출 기한이 지나 협업이 종료됐어요.',
    );
    expect(render('UNSUBMITTED_REFUNDED', null, { amount: 100000 })).toBe(
      '기한 안에 콘텐츠가 올라오지 않아 100,000원을 돌려드려요.',
    );
    expect(render('CREATOR_CANCELLED', '하루 한 컵', { amount: 52000 })).toBe(
      '하루 한 컵님이 협업을 그만뒀어요. 52,000원을 돌려드려요.',
    );
    // 식사권만 있는 협업은 돌려줄 돈이 없다: 환급 문장 없이 그만뒀다는 소식만 낸다.
    expect(render('CREATOR_CANCELLED', '하루 한 컵', { amount: 0 })).toBe(
      '하루 한 컵님이 협업을 그만뒀어요.',
    );
    expect(render('CREATOR_CANCELLED', null)).toBe(
      '크리에이터님이 협업을 그만뒀어요.',
    );
    expect(render('CANCEL_REQUESTED', '한그릇 라멘')).toBe(
      '한그릇 라멘이 협업 취소를 요청했어요.',
    );
    expect(render('COLLABORATION_HALTED', null)).toBe(
      '협업이 잠시 멈췄어요. 운영팀이 확인하고 연락드릴게요.',
    );
    expect(render('PAYOUT_DONE', null, { amount: 43200 })).toBe(
      '43,200원이 지급됐어요.',
    );
    expect(render('SETTLEMENT_REFUNDED', null, { amount: 7000 })).toBe(
      '조회수 집계가 끝났어요. 7,000원을 돌려드려요.',
    );
  });

  it('renders the proposal wordings', () => {
    expect(render('OFFER_COUNTERED', '하루 한 컵')).toBe(
      '하루 한 컵님이 조건을 바꿔 제안했어요.',
    );
    expect(render('OFFER_REVISED', '한그릇 라멘')).toBe(
      '한그릇 라멘이 조건을 바꿔 다시 보냈어요.',
    );
    expect(render('OFFER_REVISED', '모아 스튜디오')).toBe(
      '모아 스튜디오가 조건을 바꿔 다시 보냈어요.',
    );
    expect(render('OFFER_ACCEPTED_BY_STORE', '한그릇 라멘')).toBe(
      '한그릇 라멘이 제안을 수락했어요. 결제하면 알려드릴게요.',
    );
    expect(render('OFFER_ENDED', '하루 한 컵')).toBe(
      '하루 한 컵님과의 제안이 종료됐어요.',
    );
  });

  it('puts the proposal notices on the matching tab under the offers switch', () => {
    for (const kind of [
      'OFFER_COUNTERED',
      'OFFER_REVISED',
      'OFFER_ACCEPTED_BY_STORE',
      'OFFER_ENDED',
    ] as const) {
      expect(NOTIFICATION_CATALOG[kind]).toMatchObject({
        tab: 'MATCHING',
        switch: 'OFFERS',
        glyph: null,
        needsActor: true,
        requiredParams: {},
      });
    }
  });

  it('never puts a phone number or account in a text', () => {
    // 문구는 이름, 숫자, 형식만 쓴다.
    const text = render('OFFER_RECEIVED', '한그릇 라멘', {
      format: 'REELS',
      pieceCount: 1,
    });
    expect(text).not.toMatch(/\d{3}-\d{4}/);
  });

  it('gives every kind a tab or null, a switch and a renderer', () => {
    const kinds = Object.keys(NOTIFICATION_CATALOG) as NotificationKind[];
    expect(kinds.length).toBeGreaterThanOrEqual(15);
    for (const kind of kinds) {
      const entry = NOTIFICATION_CATALOG[kind];
      expect(['MATCHING', 'COLLABORATION', 'SETTLEMENT', null]).toContain(
        entry.tab,
      );
      expect(entry.switch).toBeDefined();
      expect(['WON', 'PEN', null]).toContain(entry.glyph);
      expect(typeof entry.render({ actorName: '이름', params: {} })).toBe(
        'string',
      );
    }
  });

  it('covers every Prisma notification kind', () => {
    const enumKinds = Object.keys(NotificationKind).sort();
    expect(Object.keys(NOTIFICATION_CATALOG).sort()).toEqual(enumKinds);
  });

  it('keeps collaboration progress notices essential', () => {
    for (const kind of [
      'PAYMENT_FUNDED',
      'CONTENT_SUBMITTED',
      'SUBMIT_REMINDER',
      'UNSUBMITTED_ENDED',
      'CANCEL_REQUESTED',
      'COLLABORATION_HALTED',
    ] as const) {
      expect(NOTIFICATION_CATALOG[kind]).toMatchObject({
        tab: 'COLLABORATION',
        switch: 'ESSENTIAL',
      });
    }
  });

  it('puts refunds on the settlement tab with the won glyph', () => {
    expect(NOTIFICATION_CATALOG.UNSUBMITTED_REFUNDED).toMatchObject({
      tab: 'SETTLEMENT',
      switch: 'ESSENTIAL',
      glyph: 'WON',
    });
    expect(NOTIFICATION_CATALOG.CREATOR_CANCELLED).toMatchObject({
      tab: 'SETTLEMENT',
      switch: 'ESSENTIAL',
      glyph: 'WON',
    });
    expect(NOTIFICATION_CATALOG.SETTLEMENT_REFUNDED).toMatchObject({
      tab: 'SETTLEMENT',
      switch: 'SETTLEMENT',
      glyph: 'WON',
    });
  });
  describe('required inputs', () => {
    const actor = { name: '한그릇 라멘' };

    it('states what each kind needs', () => {
      const needs = (kind: NotificationKind) => ({
        params: Object.keys(NOTIFICATION_CATALOG[kind].requiredParams).sort(),
        actor: NOTIFICATION_CATALOG[kind].needsActor,
      });
      expect(needs('OFFER_RECEIVED')).toEqual({
        params: ['format', 'pieceCount'],
        actor: true,
      });
      expect(needs('SUBMIT_REMINDER')).toEqual({
        params: ['days'],
        actor: false,
      });
      for (const kind of [
        'SETTLEMENT_CONFIRMED',
        'PAYOUT_DONE',
        'SETTLEMENT_REFUNDED',
        'UNSUBMITTED_REFUNDED',
      ] as const) {
        expect(needs(kind)).toEqual({ params: ['amount'], actor: false });
      }
      expect(needs('CREATOR_CANCELLED')).toEqual({
        params: ['amount'],
        actor: true,
      });
      for (const kind of [
        'APPLICATION_RECEIVED',
        'OFFER_ACCEPTED',
        'OFFER_DECLINED',
        'PAYMENT_FUNDED',
        'CONTENT_SUBMITTED',
        'CANCEL_REQUESTED',
      ] as const) {
        expect(needs(kind)).toEqual({ params: [], actor: true });
      }
      expect(needs('UNSUBMITTED_ENDED')).toEqual({ params: [], actor: false });
      expect(needs('COLLABORATION_HALTED')).toEqual({
        params: [],
        actor: false,
      });
    });

    it('reports a missing amount instead of rendering 0won', () => {
      expect(missingNotifyInputs('SETTLEMENT_CONFIRMED', {}, null)).toEqual([
        'amount',
      ]);
      expect(missingNotifyInputs('PAYOUT_DONE', { amount: 'x' }, null)).toEqual(
        ['amount'],
      );
      expect(missingNotifyInputs('PAYOUT_DONE', { amount: NaN }, null)).toEqual(
        ['amount'],
      );
    });

    it('reports a missing day count', () => {
      expect(missingNotifyInputs('SUBMIT_REMINDER', {}, null)).toEqual([
        'days',
      ]);
    });

    it('reports a missing format or piece count', () => {
      expect(missingNotifyInputs('OFFER_RECEIVED', {}, actor)).toEqual([
        'format',
        'pieceCount',
      ]);
      expect(
        missingNotifyInputs('OFFER_RECEIVED', { format: 'REELS' }, actor),
      ).toEqual(['pieceCount']);
    });

    it('reports a missing actor name for a kind whose text uses it', () => {
      expect(missingNotifyInputs('OFFER_ACCEPTED', {}, null)).toEqual([
        'actor',
      ]);
      expect(missingNotifyInputs('OFFER_ACCEPTED', {}, { name: ' ' })).toEqual([
        'actor',
      ]);
      expect(missingNotifyInputs('OFFER_ACCEPTED', {}, actor)).toEqual([]);
    });

    it('treats zero as present, not missing', () => {
      // 식사권만 있는 협업의 그만둠은 금액 0으로 오고, 환급 문장 없이 그려진다(판단 R41).
      expect(
        missingNotifyInputs('CREATOR_CANCELLED', { amount: 0 }, actor),
      ).toEqual([]);
      expect(missingNotifyInputs('CREATOR_CANCELLED', {}, actor)).toEqual([
        'amount',
      ]);
    });

    it('accepts a complete input for every kind', () => {
      expect(
        missingNotifyInputs(
          'OFFER_RECEIVED',
          { format: 'REELS', pieceCount: 1 },
          actor,
        ),
      ).toEqual([]);
      expect(missingNotifyInputs('SUBMIT_REMINDER', { days: 3 }, null)).toEqual(
        [],
      );
      expect(
        missingNotifyInputs('SETTLEMENT_CONFIRMED', { amount: 43200 }, null),
      ).toEqual([]);
    });
  });
});
