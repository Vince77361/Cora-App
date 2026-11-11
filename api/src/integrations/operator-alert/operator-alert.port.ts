// 운영자에게 사람이 봐야 할 일을 알리는 포트. 구현체는 OPERATOR_ALERT_ADAPTER 값으로 고른다.
export abstract class OperatorAlertPort {
  abstract alert(input: { subject: string; body: string }): Promise<void>;
}
