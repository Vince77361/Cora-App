import { Injectable } from '@nestjs/common';
import type { Payment, Prisma } from '@prisma/client';
import type { PaymentQuoteModel } from './dto/payment-quote.model';

export interface BrandPaymentOptions {
  // 요청을 받는 길(웹훅, 개발용 경로)은 이미 저장된 결과를 알림 때문에 오류로 돌려주지 않는다(3번 원장 R22).
  swallowNotifyErrors?: boolean;
}

// 승인 트랜잭션 안에서 계약·협업·장부를 옮긴 결과. afterCommit은 커밋 뒤의 후속 단계(작업 등록·환급 전송·알림)이고,
// 모두 같은 키라 다시 불러도 한 번만 일어난다.
export interface BrandApproval {
  outcome: 'concluded' | 'refunded';
  afterCommit(options: BrandPaymentOptions): Promise<void>;
}

// 브랜드 계약의 결제가 계약과 만나는 곳. 계약 모듈이 결제 모듈을 쓰므로(결제 만들기) 결제 모듈이 계약 모듈을 import할 수 없어,
// 계약 모듈이 시작할 때 이 처리기를 등록한다(작업 처리기 표와 같은 모양, forwardRef 없음).
export interface BrandPaymentHandler {
  // 브랜드의 견적. 계약 사본(없으면 합의한 최신 판본)에서만 계산한다.
  quote(userId: string, collaborationId: string): Promise<PaymentQuoteModel>;
  // 결제를 APPROVED로 바꾼 같은 트랜잭션 안에서 부른다. 잠금 순서: 결제(이미 갱신됨) → 협업 → 계약 → 장부.
  // 계약이 AWAITING_BRAND이고 이 결제가 그 계약의 결제이면 체결하고, 아니면 계약 없이 전액 환급 줄만 남긴다.
  applyApproval(
    payment: Payment,
    now: Date,
    tx: Prisma.TransactionClient,
  ): Promise<BrandApproval>;
  // 이미 승인된 결제에 같은 통지가 또 왔다: 커밋 뒤 단계가 끝나지 않았다면 마친다.
  retryApproved(payment: Payment, options: BrandPaymentOptions): Promise<void>;
}

@Injectable()
export class BrandPayments {
  private handler: BrandPaymentHandler | null = null;

  register(handler: BrandPaymentHandler): void {
    if (this.handler) {
      throw new Error('브랜드 계약 결제 처리기가 이미 등록돼 있어요.');
    }
    this.handler = handler;
  }

  require(): BrandPaymentHandler {
    if (!this.handler) {
      throw new Error('브랜드 계약 결제 처리기가 등록되지 않았어요.');
    }
    return this.handler;
  }
}
