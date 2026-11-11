// 인스타그램 릴스의 소유 확인과 조회수 읽기 포트. 구현체는 VIEW_COUNT_ADAPTER 값으로 고른다.
export abstract class ViewCountPort {
  abstract isOwnedBy(
    url: string,
    creator: { instagramHandle: string | null },
  ): Promise<boolean>;

  // submittedAt은 가짜 구현이 "제출 후 지난 날 수"를 계산하는 데 쓴다. 실제 구현은 무시한다.
  // 읽지 못하면 ViewCountUnavailableError를 던진다.
  abstract read(input: { url: string; submittedAt: Date }): Promise<number>;
}

export class ViewCountUnavailableError extends Error {
  constructor(message = '조회수를 읽지 못했어요.') {
    super(message);
    this.name = 'ViewCountUnavailableError';
  }
}
