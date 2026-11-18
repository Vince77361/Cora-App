// 프로페셔널 계정이 아니라서 연동할 수 없을 때 어댑터가 던진다. 서비스가 사용자에게 보일 안내 문장과 409로 바꾼다.
export class InstagramPersonalAccountError extends Error {
  constructor() {
    super('personal instagram account');
    this.name = 'InstagramPersonalAccountError';
  }
}

// 인스타그램 게시물 한 개. 여러 장짜리 게시물은 첫 장만 담는다(공통 모델 16장).
export interface InstagramPost {
  id: string;
  kind: 'PHOTO' | 'VIDEO';
  // 게시물 글 전체. 대표 게시물의 한 줄은 서비스가 첫 줄을 40자로 잘라 쓴다.
  caption: string | null;
  // 격자에 보일 그림의 공개 주소.
  thumbnailUrl: string;
  // 영상일 때만 값이 있다. 모르면 null.
  durationSec: number | null;
  sizeBytes: number | null;
}

// 가져올 파일의 어느 쪽인가: 사진·영상 본체, 또는 영상의 첫 화면 그림. 지금은 영상 본체를 복사하지 않아 영상은 THUMBNAIL만 받는다.
export type InstagramMediaPart = 'MEDIA' | 'THUMBNAIL';

// 크리에이터의 인스타그램 계정 연결 포트. 구현체는 INSTAGRAM_ADAPTER 값으로 고른다.
// token은 연결할 때 받은 값이다. 키가 없는 개발 환경에서는 저장하지 않아 null일 수 있다.
export abstract class InstagramPort {
  abstract beginConnect(creatorId: string): Promise<{ connectUrl: string }>;

  // 개인 계정이면 InstagramPersonalAccountError를 던진다.
  abstract completeConnect(
    creatorId: string,
    code: string,
  ): Promise<{ handle: string; followers: number; token: string }>;

  abstract fetchFollowers(token: string): Promise<number>;

  abstract listPosts(token: string | null): Promise<InstagramPost[]>;

  // 게시물 파일을 받는다. 영상의 첫 화면 그림은 part를 THUMBNAIL로 불러 따로 받는다.
  abstract fetchMedia(
    token: string | null,
    postId: string,
    part?: InstagramMediaPart,
  ): Promise<{ bytes: Buffer; contentType: string }>;
}
