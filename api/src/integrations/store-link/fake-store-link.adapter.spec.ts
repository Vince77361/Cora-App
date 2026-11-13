import { StoreLinkAnalysisError, SourceLinkInput } from './store-link.port';
import { FakeStoreLinkAdapter } from './fake-store-link.adapter';

const links: SourceLinkInput[] = [
  { kind: 'NAVER_MAP', url: 'https://map.naver.com/p/entry/place/1' },
  { kind: 'INSTAGRAM', url: 'https://www.instagram.com/hangeureut' },
];

describe('FakeStoreLinkAdapter', () => {
  const adapter = new FakeStoreLinkAdapter();

  it('returns the sample store for any valid links', async () => {
    const result = await adapter.analyze(links);
    expect(result.store).toEqual({
      name: '한그릇 라멘',
      category: '라멘집',
      neighborhood: '성수동',
      signatureMenu: '돈코츠 라멘 11,000원',
      hours: '11:30 – 21:00',
      seats: '18석, 바 좌석',
      bestShootingTime: '오후 3시 – 5시',
      intro:
        '진한 국물을 12시간 끓이는 작은 라멘집이에요. 김이 오르는 첫 숟가락 장면을 담아주세요.',
      industry: 'FOOD_CAFE',
      regionSido: '서울특별시',
      regionSigungu: '성동구',
      reviewCount: 58,
      tags: ['진한국물', '바좌석', '조용한오후'],
      customerPhrases: ['국물이 진해요', '혼밥하기 좋아요'],
    });
  });

  it('returns a jpeg sample cover photo', async () => {
    const result = await adapter.analyze(links);
    expect(result.coverPhoto?.contentType).toBe('image/jpeg');
    // JPEG 시그니처(FF D8 FF)로 실제 JPEG 파일을 읽었는지 확인한다.
    expect(result.coverPhoto?.bytes.subarray(0, 3)).toEqual(
      Buffer.from([0xff, 0xd8, 0xff]),
    );
  });

  it('returns one summary per link kind given, in the given order', async () => {
    const result = await adapter.analyze([
      { kind: 'INSTAGRAM', url: 'https://www.instagram.com/a' },
      { kind: 'NAVER_MAP', url: 'https://map.naver.com/p/1' },
      { kind: 'CATCHTABLE', url: 'https://app.catchtable.co.kr/1' },
    ]);
    expect(result.linkSummaries).toEqual([
      { kind: 'INSTAGRAM', summary: '게시물 9개 찾음' },
      { kind: 'NAVER_MAP', summary: '메뉴 12개, 사진 34장, 후기 58개 찾음' },
      { kind: 'CATCHTABLE', summary: '영업시간 찾음' },
    ]);
  });

  it('summarizes a review post link', async () => {
    const result = await adapter.analyze([
      { kind: 'REVIEW_POST', url: 'https://blog.naver.com/a/1' },
    ]);
    expect(result.linkSummaries).toEqual([
      { kind: 'REVIEW_POST', summary: '후기 글 찾음' },
    ]);
  });

  it('returns two branches for the sample store and none for another name', async () => {
    expect(await adapter.findBranches('한그릇 라멘')).toEqual([
      {
        label: '성수점',
        address: '서울 성동구 성수이로 100',
        neighborhood: '성수동2가',
        regionSido: '서울특별시',
        regionSigungu: '성동구',
      },
      {
        label: '합정점',
        address: '서울 마포구 양화로 45',
        neighborhood: '합정동',
        regionSido: '서울특별시',
        regionSigungu: '마포구',
      },
    ]);
    expect(await adapter.findBranches('다른 가게')).toEqual([]);
  });

  it('throws StoreLinkAnalysisError when the url contains "fail"', async () => {
    await expect(
      adapter.analyze([
        links[0],
        { kind: 'INSTAGRAM', url: 'https://www.instagram.com/fail-case' },
      ]),
    ).rejects.toBeInstanceOf(StoreLinkAnalysisError);
  });
});
