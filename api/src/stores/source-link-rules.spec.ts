import {
  SOURCE_LINK_MESSAGES,
  isValidSourceLinkUrl,
} from './source-link-rules';

describe('isValidSourceLinkUrl', () => {
  it('accepts the allowed https hosts per kind', () => {
    expect(isValidSourceLinkUrl('NAVER_MAP', 'https://naver.me/abc')).toBe(
      true,
    );
    expect(
      isValidSourceLinkUrl('NAVER_MAP', 'https://map.naver.com/p/entry/1'),
    ).toBe(true);
    expect(
      isValidSourceLinkUrl('CATCHTABLE', 'https://app.catchtable.co.kr/x'),
    ).toBe(true);
    expect(
      isValidSourceLinkUrl('INSTAGRAM', 'https://instagram.com/store'),
    ).toBe(true);
    expect(
      isValidSourceLinkUrl('INSTAGRAM', 'https://www.instagram.com/store'),
    ).toBe(true);
  });

  it('rejects a wrong host, a lookalike host and another kind host', () => {
    expect(isValidSourceLinkUrl('NAVER_MAP', 'https://www.naver.com/')).toBe(
      false,
    );
    expect(
      isValidSourceLinkUrl('NAVER_MAP', 'https://map.naver.com.evil.com/'),
    ).toBe(false);
    expect(
      isValidSourceLinkUrl('NAVER_MAP', 'https://evil.com/map.naver.com'),
    ).toBe(false);
    expect(isValidSourceLinkUrl('CATCHTABLE', 'https://instagram.com/a')).toBe(
      false,
    );
  });

  it('rejects non-https, credentials, custom ports and garbage', () => {
    expect(isValidSourceLinkUrl('NAVER_MAP', 'http://map.naver.com/1')).toBe(
      false,
    );
    expect(
      isValidSourceLinkUrl('NAVER_MAP', 'https://user:pw@map.naver.com/1'),
    ).toBe(false);
    expect(
      isValidSourceLinkUrl('NAVER_MAP', 'https://map.naver.com:8443/1'),
    ).toBe(false);
    expect(isValidSourceLinkUrl('NAVER_MAP', 'not a url')).toBe(false);
    expect(isValidSourceLinkUrl('NAVER_MAP', '')).toBe(false);
  });

  it('accepts naver blog and tistory urls for a review post and rejects others', () => {
    for (const url of [
      'https://blog.naver.com/hangeureut/223000000',
      'https://m.blog.naver.com/hangeureut/223000000',
      'https://hangeureut.tistory.com/12',
      'https://a-b1.tistory.com/entry/review',
    ]) {
      expect(isValidSourceLinkUrl('REVIEW_POST', url)).toBe(true);
    }
    for (const url of [
      'https://www.naver.com/',
      'https://tistory.com/12',
      'https://evil-tistory.com/12',
      'https://hangeureut.tistory.com.evil.com/12',
      'https://blog.naver.com.evil.com/a',
      'http://blog.naver.com/a',
      'https://instagram.com/a',
      'https://.tistory.com/a',
    ]) {
      expect(isValidSourceLinkUrl('REVIEW_POST', url)).toBe(false);
    }
    // 다른 종류에는 후기 글 주소를 받지 않는다.
    expect(
      isValidSourceLinkUrl('NAVER_MAP', 'https://blog.naver.com/hangeureut/1'),
    ).toBe(false);
  });

  it('explains a review post failure in the owner words', () => {
    expect(SOURCE_LINK_MESSAGES.REVIEW_POST).toBe(
      '체험단 후기 글 링크가 맞는지 확인해 주세요.',
    );
  });
});
