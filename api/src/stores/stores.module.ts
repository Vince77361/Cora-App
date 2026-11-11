import { Module } from '@nestjs/common';
import { CreatorsModule } from '../creators/creators.module';
import { IntegrationsModule } from '../integrations/integrations.module';
import { UploadsModule } from '../uploads/uploads.module';
import { UsersModule } from '../users/users.module';
import { StoresController } from './stores.controller';
import { StoresRepository } from './stores.repository';
import { StoresService } from './stores.service';

@Module({
  imports: [IntegrationsModule, UploadsModule, UsersModule, CreatorsModule],
  controllers: [StoresController],
  providers: [StoresService, StoresRepository],
  // 콘텐츠 초안, 지원, 오퍼가 내 가게와 공개 가게를 찾을 때 쓴다.
  exports: [StoresService],
})
export class StoresModule {}
