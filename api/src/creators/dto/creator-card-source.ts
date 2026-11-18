import type { FeaturedPostModel } from './featured-post.model';

// 다른 모듈(추천)이 카드를 만들 때 쓰는 크리에이터의 재료. 응답 모델이 아니라서 문서에 나가지 않는다.
export interface CreatorCardSource {
  userId: string;
  displayName: string;
  instagramHandle: string | null;
  // 카드의 콘텐츠 한 줄(40자까지).
  headline: string | null;
  photoUrl: string | null;
  // 대표 게시물 최대 4개(차례대로). 없으면 빈 목록이고, 그때 카드 사진은 프로필 사진이다.
  posts: FeaturedPostModel[];
  joinedAt: Date;
}
