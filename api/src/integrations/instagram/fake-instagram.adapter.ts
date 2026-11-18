import {
  InstagramPersonalAccountError,
  InstagramPort,
  InstagramPost,
} from './instagram.port';

const FAKE_FOLLOWERS = 2100;
const FAKE_POST_COUNT = 12;
const FAKE_VIDEO_SECONDS = 30;
const FAKE_VIDEO_BYTES = 8 * 1024 * 1024;
// 이 접두어로 시작하는 코드는 개인 계정을 흉내 낸다(연동 화면의 안내를 개발에서 시험하려고).
const PERSONAL_CODE_PREFIX = 'personal';

// 견본 게시물 12개: 짝수는 30초·8MB 영상, 홀수는 사진. 그림은 공개 견본 사진 주소다(개인정보 없음).
const FAKE_POSTS: InstagramPost[] = Array.from(
  { length: FAKE_POST_COUNT },
  (_, index) => {
    const n = index + 1;
    const video = n % 2 === 0;
    return {
      id: `fake-post-${n}`,
      kind: video ? 'VIDEO' : 'PHOTO',
      caption: `견본 게시물 ${n}`,
      thumbnailUrl: `https://picsum.photos/seed/cora-ig-${n}/600/600`,
      durationSec: video ? FAKE_VIDEO_SECONDS : null,
      sizeBytes: video ? FAKE_VIDEO_BYTES : null,
    };
  },
);

// 가짜 인스타그램 연결: 사용자가 입력한 코드가 그대로 계정 아이디가 된다.
export class FakeInstagramAdapter extends InstagramPort {
  // 시험은 손으로 쓴 fetcher를 넣어 네트워크 없이 돌린다.
  constructor(private readonly fetcher: typeof fetch = fetch) {
    super();
  }

  beginConnect(): Promise<{ connectUrl: string }> {
    return Promise.resolve({ connectUrl: 'cora-dev://fake-instagram' });
  }

  completeConnect(
    // 가짜는 크리에이터를 구분하지 않아 첫 인자를 받지 않는다.
    ...[, code]: [creatorId: string, code: string]
  ): Promise<{ handle: string; followers: number; token: string }> {
    if (code.startsWith(PERSONAL_CODE_PREFIX)) {
      return Promise.reject(new InstagramPersonalAccountError());
    }
    return Promise.resolve({
      handle: code,
      followers: FAKE_FOLLOWERS,
      token: `fake-instagram-token-${code}`,
    });
  }

  fetchFollowers(): Promise<number> {
    return Promise.resolve(FAKE_FOLLOWERS);
  }

  // 토큰은 가짜가 쓰지 않는다(키 없는 개발 환경에서는 null이어도 돌아야 한다).
  listPosts(): Promise<InstagramPost[]> {
    return Promise.resolve(FAKE_POSTS.map((post) => ({ ...post })));
  }

  // 모든 견본의 파일은 그 게시물의 견본 사진이다(영상 게시물의 영상 본체도 사진으로 흉내 낸다).
  async fetchMedia(
    _token: string | null,
    postId: string,
  ): Promise<{ bytes: Buffer; contentType: string }> {
    const post = FAKE_POSTS.find((p) => p.id === postId);
    if (!post) throw new Error(`unknown fake instagram post: ${postId}`);
    const response = await this.fetcher(post.thumbnailUrl);
    if (!response.ok) {
      throw new Error(`fake instagram fetch failed: ${response.status}`);
    }
    const bytes = Buffer.from(await response.arrayBuffer());
    const header = response.headers.get('content-type');
    return {
      bytes,
      contentType: header?.split(';')[0]?.trim() || 'image/jpeg',
    };
  }
}
