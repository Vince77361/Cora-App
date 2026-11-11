import { InstagramPort } from './instagram.port';

const FAKE_FOLLOWERS = 2100;

// 가짜 인스타그램 연결: 사용자가 입력한 코드가 그대로 계정 아이디가 된다.
export class FakeInstagramAdapter extends InstagramPort {
  beginConnect(): Promise<{ connectUrl: string }> {
    return Promise.resolve({ connectUrl: 'cora-dev://fake-instagram' });
  }

  completeConnect(
    // 가짜는 크리에이터를 구분하지 않아 첫 인자를 받지 않는다.
    ...[, code]: [creatorId: string, code: string]
  ): Promise<{ handle: string; followers: number; token: string }> {
    return Promise.resolve({
      handle: code,
      followers: FAKE_FOLLOWERS,
      token: `fake-instagram-token-${code}`,
    });
  }

  fetchFollowers(): Promise<number> {
    return Promise.resolve(FAKE_FOLLOWERS);
  }
}
