import { isAcceptedLink } from './link-rules';

describe('isAcceptedLink', () => {
  it('accepts instagram reel links for reels and rejects a youtube link', () => {
    expect(
      isAcceptedLink('REELS', 'https://www.instagram.com/reel/C8abc123/'),
    ).toBe(true);
    expect(isAcceptedLink('REELS', 'https://instagram.com/reel/C8abc123')).toBe(
      true,
    );
    expect(
      isAcceptedLink('REELS', 'https://www.youtube.com/shorts/abc123'),
    ).toBe(false);
  });

  it('accepts instagram reel and post links for card news', () => {
    expect(
      isAcceptedLink('CARD_NEWS', 'https://instagram.com/p/Cabc123/'),
    ).toBe(true);
    expect(
      isAcceptedLink('CARD_NEWS', 'https://www.instagram.com/reel/Cabc123/'),
    ).toBe(true);
  });

  it('accepts youtube shorts and youtu.be links for shorts only', () => {
    expect(
      isAcceptedLink('SHORTS', 'https://www.youtube.com/shorts/abc123'),
    ).toBe(true);
    expect(isAcceptedLink('SHORTS', 'https://youtube.com/shorts/abc123')).toBe(
      true,
    );
    expect(isAcceptedLink('SHORTS', 'https://youtu.be/abc123')).toBe(true);
    expect(isAcceptedLink('SHORTS', 'https://instagram.com/reel/abc')).toBe(
      false,
    );
    // 쇼츠가 아닌 일반 영상 주소는 받지 않는다.
    expect(
      isAcceptedLink('SHORTS', 'https://www.youtube.com/watch?v=abc123'),
    ).toBe(false);
  });

  it('accepts naver and tistory blog links for blog posts', () => {
    expect(isAcceptedLink('BLOG', 'https://blog.naver.com/cora/2234')).toBe(
      true,
    );
    expect(isAcceptedLink('BLOG', 'https://cora.tistory.com/12')).toBe(true);
    expect(isAcceptedLink('BLOG', 'https://tistory.com/12')).toBe(false);
    expect(isAcceptedLink('BLOG', 'https://instagram.com/p/abc')).toBe(false);
  });

  it('rejects http links', () => {
    expect(isAcceptedLink('REELS', 'http://instagram.com/reel/abc')).toBe(
      false,
    );
    expect(isAcceptedLink('SHORTS', 'http://youtu.be/abc')).toBe(false);
  });

  it('rejects links that only look like an accepted host', () => {
    expect(
      isAcceptedLink('REELS', 'https://instagram.com.evil.com/reel/abc'),
    ).toBe(false);
    expect(
      isAcceptedLink('REELS', 'https://instagram.com@evil.com/reel/abc'),
    ).toBe(false);
    expect(isAcceptedLink('REELS', 'https://evilinstagram.com/reel/abc')).toBe(
      false,
    );
  });

  it('rejects links with no content id, with a port, or that are not urls', () => {
    expect(isAcceptedLink('REELS', 'https://instagram.com/reel/')).toBe(false);
    expect(isAcceptedLink('REELS', 'https://instagram.com/')).toBe(false);
    expect(isAcceptedLink('SHORTS', 'https://youtu.be/')).toBe(false);
    expect(isAcceptedLink('REELS', 'https://instagram.com:8443/reel/abc')).toBe(
      false,
    );
    expect(isAcceptedLink('REELS', 'not a url')).toBe(false);
    expect(isAcceptedLink('REELS', '')).toBe(false);
  });
});
