import { Controller, Get } from '@nestjs/common';
import { ApiBearerAuth, ApiOkResponse, ApiOperation } from '@nestjs/swagger';
import { CurrentUser } from '../auth/current-user.decorator';
import type { AuthUser } from '../auth/current-user.decorator';
import { TrialComparisonModel } from './dto/trial-comparison.model';
import { StoreInsightsService } from './store-insights.service';

@ApiBearerAuth()
@Controller('stores/me')
export class StoreInsightsController {
  constructor(private readonly insights: StoreInsightsService) {}

  @Get('trial-comparison')
  @ApiOperation({
    operationId: 'getMyStoreTrialComparison',
    summary: '체험단 재계약 전 비교(G3). 체험단 계약 정보가 없으면 404다.',
  })
  @ApiOkResponse({ type: TrialComparisonModel })
  get(@CurrentUser() user: AuthUser): Promise<TrialComparisonModel> {
    return this.insights.trialComparison(user.userId);
  }
}
