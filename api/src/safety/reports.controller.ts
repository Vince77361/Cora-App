import { Body, Controller, Post } from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiConflictResponse,
  ApiCreatedResponse,
  ApiNotFoundResponse,
  ApiOperation,
} from '@nestjs/swagger';
import { CurrentUser } from '../auth/current-user.decorator';
import type { AuthUser } from '../auth/current-user.decorator';
import { CreateReportDto } from './dto/create-report.dto';
import { ReportCreatedModel } from './dto/report-created.model';
import { SafetyService } from './safety.service';

@ApiBearerAuth()
@Controller('reports')
export class ReportsController {
  constructor(private readonly safety: SafetyService) {}

  @Post()
  @ApiOperation({
    operationId: 'createReport',
    summary:
      '내가 참가한 방이나 그 상대를 신고한다. 운영자에게 메일이 간다. 돈이 보관 중인 협업이면 그 협업이 멈춘다.',
  })
  @ApiCreatedResponse({ type: ReportCreatedModel })
  @ApiNotFoundResponse({ description: '내 방이나 그 상대가 아니다.' })
  @ApiConflictResponse({ description: '이미 신고했다.' })
  create(
    @CurrentUser() user: AuthUser,
    @Body() body: CreateReportDto,
  ): Promise<ReportCreatedModel> {
    return this.safety.report(user.userId, body);
  }
}
