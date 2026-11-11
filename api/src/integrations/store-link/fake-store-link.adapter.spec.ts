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
      { kind: 'NAVER_MAP', summary: '사진 12장, 메뉴 8개 찾음' },
      { kind: 'CATCHTABLE', summary: '영업시간 찾음' },
    ]);
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
