import { Body, Controller, Get, HttpCode, Param, Post } from '@nestjs/common';
import { ApiBearerAuth, ApiOkResponse, ApiOperation } from '@nestjs/swagger';
import { CurrentUser } from '../auth/current-user.decorator';
import type { AuthUser } from '../auth/current-user.decorator';
import { ViewReportService } from '../settlements/view-report.service';
import { DisputeViewReportDto } from './dto/dispute-view-report.dto';
import { SubmitViewEvidenceDto } from './dto/submit-view-evidence.dto';
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

  @Post(':id/view-report/dispute')
  @HttpCode(200)
  @ApiOperation({
    operationId: 'disputeViewReport',
    summary:
      '조회 자료에 이의를 제기한다(당사자 누구나, 확인 전인 계산에 한 사람이 한 번). 돈은 그대로 보관되고 운영팀이 처리한다. 낼 수 없는 상태면 409.',
  })
  @ApiOkResponse({ type: ViewReportModel })
  dispute(
    @CurrentUser() user: AuthUser,
    @Param('id') id: string,
    @Body() dto: DisputeViewReportDto,
  ): Promise<ViewReportModel> {
    return this.viewReports.dispute(user.userId, id, dto.reason);
  }

  @Post(':id/view-evidence')
  @HttpCode(200)
  @ApiOperation({
    operationId: 'submitViewEvidence',
    summary:
      '조회수를 읽지 못했을 때 크리에이터가 인사이트 캡처와 조회수를 낸다. 크리에이터만, 캡처가 요청된 때 한 번. 받을 수 없는 상태면 409, 내 파일이 아니면 403.',
  })
  @ApiOkResponse({ type: ViewReportModel })
  submitEvidence(
    @CurrentUser() user: AuthUser,
    @Param('id') id: string,
    @Body() dto: SubmitViewEvidenceDto,
  ): Promise<ViewReportModel> {
    return this.viewReports.submitEvidence(user.userId, id, dto);
  }
}
