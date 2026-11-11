import { Module } from '@nestjs/common';
import { IntegrationsModule } from '../integrations/integrations.module';
import { UsersModule } from '../users/users.module';
import { UploadsController } from './uploads.controller';
import { UploadRateLimiter } from './upload-rate-limiter';
import { UploadsService } from './uploads.service';

// 사진 경로를 저장하는 모듈(가게, 크리에이터)이 UploadsService.assertOwnedPath를 쓰도록 내보낸다.
@Module({
  imports: [IntegrationsModule, UsersModule],
  controllers: [UploadsController],
  providers: [UploadsService, UploadRateLimiter],
  exports: [UploadsService],
})
export class UploadsModule {}
