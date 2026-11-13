import { SourceLinkKind } from '@prisma/client';

// 종류마다 받는 서비스의 호스트. 모두 https여야 한다.
const HOSTS: Record<SourceLinkKind, readonly string[]> = {
  NAVER_MAP: ['naver.me', 'map.naver.com'],
  CATCHTABLE: ['app.catchtable.co.kr'],
  INSTAGRAM: ['instagram.com', 'www.instagram.com'],
  REVIEW_POST: ['blog.naver.com', 'm.blog.naver.com'],
};

// 호스트가 하나로 정해지지 않는 종류의 하위 도메인(티스토리는 블로그마다 주소가 다르다). 마침표로 끝을 맞춰 evil-tistory.com을 막는다.
const SUBDOMAIN_OF: Partial<Record<SourceLinkKind, RegExp>> = {
  REVIEW_POST: /^([a-z0-9]([a-z0-9-]*[a-z0-9])?\.)+tistory\.com$/,
};

export const SOURCE_LINK_MESSAGES: Record<SourceLinkKind, string> = {
  NAVER_MAP: '네이버 지도 링크가 맞는지 확인해 주세요.',
  CATCHTABLE: '캐치테이블 링크가 맞는지 확인해 주세요.',
  INSTAGRAM: '인스타그램 링크가 맞는지 확인해 주세요.',
  REVIEW_POST: '체험단 후기 글 링크가 맞는지 확인해 주세요.',
};

// 서버가 이 주소를 나중에 내려받을 수 있으므로(링크 분석) 호스트를 정확히 맞춰 엉뚱한 곳을 못 가리키게 한다.
// 계정 정보(user:pw@)나 다른 포트가 붙은 주소도 막는다.
export function isValidSourceLinkUrl(
  kind: SourceLinkKind,
  value: string,
): boolean {
  let url: URL;
  try {
    url = new URL(value);
  } catch {
    return false;
  }
  return (
    url.protocol === 'https:' &&
    url.username === '' &&
    url.password === '' &&
    url.port === '' &&
    (HOSTS[kind].includes(url.hostname) ||
      (SUBDOMAIN_OF[kind]?.test(url.hostname) ?? false))
  );
}
