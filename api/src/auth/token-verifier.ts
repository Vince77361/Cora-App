// DI 토큰으로 쓰려고 인터페이스가 아닌 추상 클래스로 둔다. 테스트는 이것을 가짜로 바꿔 끼운다.
// 실패하면 AppError('UNAUTHENTICATED')를 던져야 한다.
export abstract class TokenVerifier {
  abstract verify(token: string): Promise<{ userId: string }>;
}
