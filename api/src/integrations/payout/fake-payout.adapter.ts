import { Logger } from '@nestjs/common';
import { PayoutFailedError, PayoutPort } from './payout.port';

// 가짜 송금: 항상 성공하고, 예금주에 fail이 들어 있으면 실패한다(실패 흐름 시험용).
export class FakePayoutAdapter extends PayoutPort {
  private readonly logger = new Logger(FakePayoutAdapter.name);
  readonly sent: {
    bankCode: string;
    accountNumber: string;
    holderName: string;
    amount: number;
    idempotencyKey: string;
    externalId: string;
  }[] = [];

  send(input: {
    bankCode: string;
    accountNumber: string;
    holderName: string;
    amount: number;
    idempotencyKey: string;
  }): Promise<{ externalId: string }> {
    if (input.holderName.includes('fail')) {
      return Promise.reject(new PayoutFailedError());
    }
    const externalId = `fake-payout-${input.idempotencyKey}`;
    if (!this.sent.some((s) => s.idempotencyKey === input.idempotencyKey)) {
      this.sent.push({ ...input, externalId });
      // 계좌번호와 예금주는 로그에 남기지 않는다.
      this.logger.log(
        `송금(가짜) amount=${input.amount} key=${input.idempotencyKey}`,
      );
    }
    return Promise.resolve({ externalId });
  }
}
