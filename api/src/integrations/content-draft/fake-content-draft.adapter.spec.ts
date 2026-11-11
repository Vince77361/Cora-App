import { FakeContentDraftAdapter } from './fake-content-draft.adapter';

const input = {
  storeName: '한그릇 라멘',
  signatureMenu: '돈코츠 라멘 11,000원',
  bestShootingTime: '오후 3시 – 5시',
  intro: null,
};

describe('FakeContentDraftAdapter', () => {
  const adapter = new FakeContentDraftAdapter();

  it('returns three scenes and a body for each draft kind', async () => {
    const cardNews = await adapter.generate(input, 'CARD_NEWS', 0);
    expect(cardNews).toEqual({
      bodyLabel: '본문',
      body: '성수동 골목 안, 12시간 끓인 국물 한 그릇.\n오후 3시 이후엔 줄 없이 들어올 수 있어요.\n#성수라멘 #돈코츠',
      scenes: [
        { label: '1', text: '12시간 끓인\n국물 한 그릇', usesPhoto: true },
        {
          label: '2',
          text: '대표 메뉴\n돈코츠 라멘\n11,000원',
          usesPhoto: false,
        },
        { label: '3', text: '줄 없는 시간\n오후 3시 – 5시', usesPhoto: false },
      ],
    });

    const reels = await adapter.generate(input, 'REELS_SCRIPT', 0);
    expect(reels).toEqual({
      bodyLabel: '촬영 순서',
      body: '0–3초  김이 오르는 그릇 클로즈업\n3–8초  면을 들어 올리는 손\n8–15초  가게 간판과 위치 자막',
      scenes: [
        { label: '장면 1', text: '김이 오르는\n첫 숟가락', usesPhoto: true },
        { label: '장면 2', text: '면을 들어\n올리는 손', usesPhoto: false },
        { label: '장면 3', text: '골목 간판과\n위치 자막', usesPhoto: false },
      ],
    });

    const blog = await adapter.generate(input, 'BLOG', 0);
    expect(blog).toEqual({
      bodyLabel: '도입부',
      body: '성수역에서 걸어서 5분, 골목 끝에 바 좌석 18석짜리 라멘집이 있어요. 국물은 매일 아침 12시간을 끓여요.',
      scenes: [
        { label: '제목', text: '성수 골목\n라멘집 한 곳', usesPhoto: true },
        { label: '소제목 1', text: '12시간\n끓인 국물', usesPhoto: false },
        { label: '소제목 2', text: '줄 없이\n먹는 시간', usesPhoto: false },
      ],
    });
  });

  it('returns different scene order for odd and even versions', async () => {
    for (const kind of ['CARD_NEWS', 'REELS_SCRIPT', 'BLOG'] as const) {
      const even = await adapter.generate(input, kind, 2);
      const odd = await adapter.generate(input, kind, 1);
      expect(odd.scenes[0]).toEqual(even.scenes[0]);
      expect(odd.scenes[1]).toEqual(even.scenes[2]);
      expect(odd.scenes[2]).toEqual(even.scenes[1]);
      expect(odd.body).toBe(even.body);
      expect(odd.bodyLabel).toBe(even.bodyLabel);
    }
  });

  it('does not mutate the sample drafts between calls', async () => {
    const first = await adapter.generate(input, 'BLOG', 1);
    first.scenes[0].text = 'changed';
    const second = await adapter.generate(input, 'BLOG', 0);
    expect(second.scenes[0].text).toBe('성수 골목\n라멘집 한 곳');
  });
});
