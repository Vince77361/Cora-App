import { NotificationKind } from '@prisma/client';
import { NOTIFICATION_CATALOG } from './notification-catalog';

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
});
