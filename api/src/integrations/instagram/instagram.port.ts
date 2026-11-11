// 크리에이터의 인스타그램 계정 연결 포트. 구현체는 INSTAGRAM_ADAPTER 값으로 고른다.
export abstract class InstagramPort {
  abstract beginConnect(creatorId: string): Promise<{ connectUrl: string }>;

  abstract completeConnect(
    creatorId: string,
    code: string,
  ): Promise<{ handle: string; followers: number; token: string }>;

  abstract fetchFollowers(token: string): Promise<number>;
}
