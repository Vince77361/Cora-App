import { Body, Controller, Post } from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiCreatedResponse,
  ApiOperation,
} from '@nestjs/swagger';
import { CurrentUser } from '../auth/current-user.decorator';
import type { AuthUser } from '../auth/current-user.decorator';
import { CreatePhotoUploadDto } from './dto/create-photo-upload.dto';
import { PhotoUploadModel } from './dto/photo-upload.model';
import { UploadsService } from './uploads.service';

@ApiBearerAuth()
@Controller('uploads')
export class UploadsController {
  constructor(private readonly uploads: UploadsService) {}

  @Post('photos')
  @ApiOperation({ operationId: 'createPhotoUpload' })
  @ApiCreatedResponse({ type: PhotoUploadModel })
  createPhotoUpload(
    @CurrentUser() user: AuthUser,
    @Body() dto: CreatePhotoUploadDto,
  ): Promise<PhotoUploadModel> {
    return this.uploads.createPhotoUpload(user.userId, dto);
  }
}
