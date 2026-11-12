// 운영 명령이 "할 수 없다"고 알리는 오류. 메시지는 운영자가 그대로 읽는다(개인정보를 넣지 않는다).
export class OpsError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'OpsError';
  }
}
