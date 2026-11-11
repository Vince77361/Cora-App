import { Controller, Delete, Get, HttpCode, Param, Post } from '@nestjs/common';
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

  @Post(':id/applications')
  @ApiOperation({ operationId: 'applyToStore' })
  @ApiCreatedResponse({ type: ApplicationModel })
  apply(
    @CurrentUser() user: AuthUser,
    @Param('id') id: string,
  ): Promise<ApplicationModel> {
    return this.applications.apply(user.userId, id);
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
