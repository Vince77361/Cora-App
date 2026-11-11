// 크리에이터에게 돈을 보내는 송금 포트. 구현체는 IntegrationsModule이 PAYOUT_ADAPTER 값으로 고른다.
export abstract class PayoutPort {
  // 같은 idempotencyKey로 다시 불러도 송금이 한 번만 나가야 한다. 실패하면 PayoutFailedError를 던진다.
  abstract send(input: {
    bankCode: string;
    accountNumber: string;
    holderName: string;
    amount: number;
    idempotencyKey: string;
  }): Promise<{ externalId: string }>;
}

export class PayoutFailedError extends Error {
  constructor(message = '송금이 실패했어요.') {
    super(message);
    this.name = 'PayoutFailedError';
  }
}
