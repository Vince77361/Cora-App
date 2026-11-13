import { Injectable } from '@nestjs/common';
import { Clock } from '../common/clock';
import { AppError } from '../common/errors/app-error';
import { startOfKstDayMonthsAgo } from '../common/kst';
import { PaymentsService } from '../payments/payments.service';
import { SettlementsRepository } from '../settlements/settlements.repository';
import { readTerms } from '../stores/reward-terms';
import { StoresService } from '../stores/stores.service';
import { TrialComparisonModel } from './dto/trial-comparison.model';
import { compareTrial } from './trial-comparison';

// 체험단 비교의 Cora 칸 범위: 오늘부터 달력으로 석 달 전까지.
const COMPARE_MONTHS = 3;

// 사장님의 가게에 대한 읽기 전용 모아 보기(체험단 비교). 다른 모듈의 값을 읽기만 한다.
@Injectable()
export class StoreInsightsService {
  constructor(
    private readonly stores: StoresService,
    private readonly settlements: SettlementsRepository,
    private readonly payments: PaymentsService,
    private readonly clock: Clock,
  ) {}

  // 체험단 계약 정보를 넣지 않은 가게에는 비교가 없다(404).
  async trialComparison(userId: string): Promise<TrialComparisonModel> {
    const { storeId, trial } = await this.stores.getTrialContext(userId);
    if (!trial) {
      throw new AppError('NOT_FOUND', '체험단 계약 정보를 먼저 넣어 주세요.');
    }
    const since = startOfKstDayMonthsAgo(this.clock.now(), COMPARE_MONTHS);
    const settled = await this.settlements.listSettledForStore(storeId, since);
    const funded = await this.payments.fundedAmounts(
      settled.map((s) => s.collaborationId),
    );
    const result = compareTrial({
      trial,
      collaborations: settled.map((s) => ({
        payout: s.payoutAmount,
        // 식사권만 있던 협업은 결제가 없어 수수료도 0이다.
        fee: funded.get(s.collaborationId)?.fee ?? 0,
        format: readTerms(s.collaboration.terms).format,
        multiplierTenths: s.multiplierTenths,
      })),
    });
    return {
      trial: { ...trial, spent: result.trialSpent },
      cora: {
        offerCount: result.coraCount,
        spent: result.coraSpent,
        contentByFormat: result.contentByFormat,
        averageMultiplierTenths: result.averageMultiplierTenths,
      },
    };
  }
}
