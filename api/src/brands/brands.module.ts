import { Module } from '@nestjs/common';
import { IntegrationsModule } from '../integrations/integrations.module';
import { UploadsModule } from '../uploads/uploads.module';
import { UsersModule } from '../users/users.module';
import { BrandsController } from './brands.controller';
import { BrandsRepository } from './brands.repository';
import { BrandsService } from './brands.service';

@Module({
  imports: [IntegrationsModule, UploadsModule, UsersModule],
  controllers: [BrandsController],
  providers: [BrandsService, BrandsRepository],
  // 캠페인과 4번 계획의 카드·매칭이 BrandsService만 쓴다.
  exports: [BrandsService],
})
export class BrandsModule {}
