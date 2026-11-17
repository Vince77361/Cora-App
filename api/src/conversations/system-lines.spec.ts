import { renderSystemLine } from './system-lines';

const COMMISSIONER = { userId: 'brand-1', role: 'COMMISSIONER' as const };
const CREATOR = { userId: 'creator-1', role: 'CREATOR' as const };

describe('renderSystemLine', () => {
  it('renders the proposal line differently for the proposer and the other side', () => {
    const params = { name: '하루 한 컵', version: 2, proposerId: 'creator-1' };
    expect(renderSystemLine('TERMS_PROPOSED', params, CREATOR)).toBe(
      '조건 버전 2을 제안했어요.',
    );
    expect(renderSystemLine('TERMS_PROPOSED', params, COMMISSIONER)).toBe(
      '하루 한 컵님이 조건 버전 2을 제안했어요.',
    );
  });

  it('shows each side the name of the other side on a match', () => {
    const params = { commissionerName: '느린결', creatorName: '하루 한 컵' };
    expect(renderSystemLine('MATCHED', params, COMMISSIONER)).toBe(
      '하루 한 컵님과 서로 관심이 닿았어요. 조건 버전 1이 만들어졌어요.',
    );
    expect(renderSystemLine('MATCHED', params, CREATOR)).toBe(
      '느린결님과 서로 관심이 닿았어요. 조건 버전 1이 만들어졌어요.',
    );
  });

  it('words an offer accepted by the creator and a counter-proposal accepted by the store differently', () => {
    expect(
      renderSystemLine(
        'OFFER_ACCEPTED',
        { by: 'CREATOR', name: '하루 한 컵' },
        COMMISSIONER,
      ),
    ).toBe('하루 한 컵님이 오퍼를 수락했어요.');
    expect(
      renderSystemLine(
        'OFFER_ACCEPTED',
        { by: 'COMMISSIONER', name: '한그릇 라멘' },
        CREATOR,
      ),
    ).toBe('한그릇 라멘이 제안을 수락했어요.');
    expect(
      renderSystemLine(
        'OFFER_ACCEPTED',
        { by: 'COMMISSIONER', name: '카페' },
        CREATOR,
      ),
    ).toBe('카페가 제안을 수락했어요.');
  });

  it('renders the plain lines from the copy table', () => {
    const p = { name: '느린결', version: 3 };
    expect(renderSystemLine('REQUEST_ACCEPTED', p, CREATOR)).toBe(
      '느린결님이 대화를 수락했어요.',
    );
    expect(renderSystemLine('TERMS_CONFIRMED', p, CREATOR)).toBe(
      '느린결님이 조건 버전 3을 확인했어요.',
    );
    expect(renderSystemLine('TERMS_AGREED', p, CREATOR)).toBe(
      '양쪽이 조건 버전 3을 확인했어요.',
    );
    expect(renderSystemLine('CREATOR_CONSENTED', p, COMMISSIONER)).toBe(
      '느린결님이 계약에 동의했어요.',
    );
    expect(renderSystemLine('CONSENT_VOIDED', {}, CREATOR)).toBe(
      '조건이 바뀌어 계약 동의가 취소됐어요.',
    );
    expect(renderSystemLine('CONTRACT_CONCLUDED', {}, CREATOR)).toBe(
      '계약이 체결됐어요.',
    );
  });

  it('tells the one who dropped and the other side apart without a reason', () => {
    const params = { droppedById: 'creator-1' };
    expect(renderSystemLine('DROPPED', params, CREATOR)).toBe(
      '협의를 그만뒀어요.',
    );
    expect(renderSystemLine('DROPPED', params, COMMISSIONER)).toBe(
      '이번에는 함께하기 어렵대요.',
    );
  });
});
