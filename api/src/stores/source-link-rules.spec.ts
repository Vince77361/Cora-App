import { isValidSourceLinkUrl } from './source-link-rules';

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
});
