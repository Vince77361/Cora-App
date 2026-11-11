import { ContentFormat } from '@prisma/client';

// 제출할 수 있는 콘텐츠 링크의 모양. 순수 함수라 시각이나 DB를 모른다.
// 형식에 맞는 곳의 주소만 받아야 조회수 집계가 읽을 수 있는 게시물만 정산에 올라온다.
const MAX_LENGTH = 2000;

const INSTAGRAM_HOSTS = ['instagram.com', 'www.instagram.com'];
const YOUTUBE_HOSTS = ['youtube.com', 'www.youtube.com'];

// 첫 경로 조각이 prefix이고 그 뒤에 비어 있지 않은 조각(게시물 ID)이 있어야 한다.
function hasIdAfter(path: string, prefixes: string[]): boolean {
  const [, first, id] = path.split('/');
  return prefixes.includes(first) && !!id;
}

export function isAcceptedLink(format: ContentFormat, url: string): boolean {
  if (typeof url !== 'string' || url.length === 0 || url.length > MAX_LENGTH) {
    return false;
  }
  let parsed: URL;
  try {
    parsed = new URL(url);
  } catch {
    return false;
  }
  // 아이디·비밀번호나 포트가 붙은 주소는 받지 않는다(`instagram.com@다른곳` 같은 속임수를 함께 막는다).
  if (
    parsed.protocol !== 'https:' ||
    parsed.username !== '' ||
    parsed.password !== '' ||
    parsed.port !== ''
  ) {
    return false;
  }
  const host = parsed.hostname;
  const path = parsed.pathname;
  switch (format) {
    case 'SHORTS':
      if (YOUTUBE_HOSTS.includes(host)) return hasIdAfter(path, ['shorts']);
      return host === 'youtu.be' && path.length > 1;
    case 'REELS':
    case 'CARD_NEWS':
      return INSTAGRAM_HOSTS.includes(host) && hasIdAfter(path, ['reel', 'p']);
    case 'BLOG':
      if (host === 'blog.naver.com') return path.length > 1;
      // tistory.com 자체가 아니라 블로그 이름이 붙은 하위 도메인만이다.
      return (
        host.endsWith('.tistory.com') &&
        host.length > '.tistory.com'.length &&
        path.length > 1
      );
    default:
      return false;
  }
}
