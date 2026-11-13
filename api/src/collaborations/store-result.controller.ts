import { Controller, Get, Param } from '@nestjs/common';
import { ApiBearerAuth, ApiOkResponse, ApiOperation } from '@nestjs/swagger';
import { CurrentUser } from '../auth/current-user.decorator';
import type { AuthUser } from '../auth/current-user.decorator';
import { StoreResultModel } from './dto/store-result.model';
import { StoreResultService } from './store-result.service';

@ApiBearerAuth()
@Controller('collaborations')
export class StoreResultController {
  constructor(private readonly results: StoreResultService) {}

  @Get(':id/result')
  @ApiOperation({
    operationId: 'getStoreResult',
    summary:
      '사장님의 7일 결과(G1). 끝난 협업의 지급·환불과 평소 조회수 대비 배수를 돌려준다.',
  })
  @ApiOkResponse({ type: StoreResultModel })
  get(
    @CurrentUser() user: AuthUser,
    @Param('id') id: string,
  ): Promise<StoreResultModel> {
    return this.results.get(user.userId, id);
  }
}
