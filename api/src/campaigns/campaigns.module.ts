import { Module } from '@nestjs/common';
import { BrandsModule } from '../brands/brands.module';
import { UsersModule } from '../users/users.module';
import { CampaignsController } from './campaigns.controller';
import { CampaignsRepository } from './campaigns.repository';
import { CampaignsService } from './campaigns.service';

@Module({
  imports: [BrandsModule, UsersModule],
  controllers: [CampaignsController],
  providers: [CampaignsService, CampaignsRepository],
  // 발견·매칭·협업이 CampaignsService만 쓴다.
  exports: [CampaignsService],
})
export class CampaignsModule {}
