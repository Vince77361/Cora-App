import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  Param,
  Post,
} from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiCreatedResponse,
  ApiNoContentResponse,
  ApiOkResponse,
  ApiOperation,
} from '@nestjs/swagger';
import { CurrentUser } from '../auth/current-user.decorator';
import type { AuthUser } from '../auth/current-user.decorator';
import { ApplicationsService } from './applications.service';
import { ApplicantModel } from './dto/applicant.model';
import { RecommendedApplicantsModel } from './dto/recommended-applicants.model';
import { ApplyDto } from './dto/apply.dto';
import { ApplicationModel } from './dto/application.model';

@ApiBearerAuth()
@Controller('stores')
export class ApplicationsController {
  constructor(private readonly applications: ApplicationsService) {}

  @Get('me/applications')
  @ApiOperation({ operationId: 'listMyStoreApplicants' })
  @ApiOkResponse({ type: [ApplicantModel] })
  listApplicants(@CurrentUser() user: AuthUser): Promise<ApplicantModel[]> {
    return this.applications.listApplicants(user.userId);
  }

  // `:id` 라우트보다 위에 둔다(me가 id로 읽히지 않게).
  @Get('me/applications/recommended')
  @ApiOperation({ operationId: 'listRecommendedApplicants' })
  @ApiOkResponse({ type: RecommendedApplicantsModel })
  listRecommended(
    @CurrentUser() user: AuthUser,
  ): Promise<RecommendedApplicantsModel> {
    return this.applications.listRecommended(user.userId);
  }

  @Post('me/applications/:id/skip')
  @HttpCode(204)
  @ApiOperation({ operationId: 'skipRecommendedApplicant' })
  @ApiNoContentResponse()
  skip(@CurrentUser() user: AuthUser, @Param('id') id: string): Promise<void> {
    return this.applications.skipRecommended(user.userId, id);
  }

  @Post(':id/applications')
  @ApiOperation({ operationId: 'applyToStore' })
  @ApiCreatedResponse({ type: ApplicationModel })
  apply(
    @CurrentUser() user: AuthUser,
    @Param('id') id: string,
    @Body() dto: ApplyDto,
  ): Promise<ApplicationModel> {
    return this.applications.apply(user.userId, id, dto);
  }

  @Delete(':id/applications/mine')
  @HttpCode(204)
  @ApiOperation({ operationId: 'cancelMyApplication' })
  @ApiNoContentResponse()
  cancel(
    @CurrentUser() user: AuthUser,
    @Param('id') id: string,
  ): Promise<void> {
    return this.applications.cancel(user.userId, id);
  }
}
