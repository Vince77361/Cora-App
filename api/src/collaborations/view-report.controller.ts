import { Controller, Get, HttpCode, Param, Post } from '@nestjs/common';
import { ApiBearerAuth, ApiOkResponse, ApiOperation } from '@nestjs/swagger';
import { CurrentUser } from '../auth/current-user.decorator';
import type { AuthUser } from '../auth/current-user.decorator';
import { ViewReportService } from '../settlements/view-report.service';
import { ViewReportModel } from './dto/view-report.model';

@ApiBearerAuth()
@Controller('collaborations')
export class ViewReportController {
  constructor(private readonly viewReports: ViewReportService) {}

  @Get(':id/view-report')
  @ApiOperation({
    operationId: 'getViewReport',
    summary:
      '조회 자료 확인(F4). 당사자만 읽는다. 조회수 수당이 없거나 링크 제출 전이면 404.',
  })
  @ApiOkResponse({ type: ViewReportModel })
  get(
    @CurrentUser() user: AuthUser,
    @Param('id') id: string,
  ): Promise<ViewReportModel> {
    return this.viewReports.get(user.userId, id);
  }

  @Post(':id/view-report/confirm')
  @HttpCode(200)
  @ApiOperation({
    operationId: 'confirmViewReport',
    summary:
      '맡긴 쪽이 "자료 확인했어요"를 누른다. 확인되면 정산이 이어진다. 확인할 수 없는 상태면 409, 크리에이터는 403.',
  })
  @ApiOkResponse({ type: ViewReportModel })
  confirm(
    @CurrentUser() user: AuthUser,
    @Param('id') id: string,
  ): Promise<ViewReportModel> {
    return this.viewReports.confirmByCommissioner(user.userId, id);
  }
}
