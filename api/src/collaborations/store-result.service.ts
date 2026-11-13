import { Injectable } from '@nestjs/common';
import { AppError } from '../common/errors/app-error';
import { CreatorsService } from '../creators/creators.service';
import { SettlementsRepository } from '../settlements/settlements.repository';
import { hasViewPay, readTerms } from '../stores/reward-terms';
import { CollaborationsRepository } from './collaborations.repository';
import { StoreResultModel } from './dto/store-result.model';

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

// 사장님의 7일 결과(G1). 읽기만 한다(평소 조회수는 정산이 끝날 때 한 번 읽어 저장해 둔 값이다).
@Injectable()
export class StoreResultService {
  constructor(
    private readonly collaborations: CollaborationsRepository,
    private readonly settlements: SettlementsRepository,
    private readonly creators: CreatorsService,
  ) {}

  // 맡긴 쪽(사장님)만 읽는다. 크리에이터와 남은 없는 협업과 같게 404다.
  // 끝나지 않은 협업, 식사권만 있던 협업(G1이 없다), 정산 줄이나 제출 링크가 없는 협업도 404다.
  async get(
    userId: string,
    collaborationId: string,
  ): Promise<StoreResultModel> {
    const collaboration = UUID.test(collaborationId)
      ? await this.collaborations.findById(collaborationId)
      : null;
    if (
      !collaboration ||
      collaboration.commissionerId !== userId ||
      collaboration.kind !== 'STORE_OFFER' ||
      collaboration.stage !== 'SETTLED' ||
      collaboration.settlementMethod === 'NONE' ||
      !collaboration.submittedUrl ||
      !collaboration.submittedAt
    ) {
      throw this.notFound();
    }
    const settlement = await this.settlements.findSettlement(collaboration.id);
    // 확인 완료된 정산만 결과로 보인다(끝난 협업이면 늘 그렇지만, 어긋난 행이 결과로 새지 않게 한다).
    if (!settlement || settlement.status !== 'CONFIRMED') {
      throw this.notFound();
    }

    const terms = readTerms(collaboration.terms);
    const creator = await this.creators.getSummary(collaboration.creatorId);
    return {
      creator: {
        userId: collaboration.creatorId,
        name: creator?.displayName ?? '크리에이터',
        photoUrl: creator?.photoUrl ?? null,
      },
      format: terms.format,
      postedAt: collaboration.submittedAt.toISOString(),
      postUrl: collaboration.submittedUrl,
      views: settlement.finalViews,
      usualViews: settlement.usualViews,
      multiplierTenths: settlement.multiplierTenths,
      payout: settlement.payoutAmount,
      refund: settlement.refundAmount,
      fixedCashOnly: !hasViewPay(terms),
      fixedCash: terms.fixedCash,
    };
  }

  private notFound(): AppError {
    return new AppError('NOT_FOUND', '결과를 찾을 수 없어요.');
  }
}
