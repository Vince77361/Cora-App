import { Module } from '@nestjs/common';
import { BrandsModule } from '../brands/brands.module';
import { CampaignsModule } from '../campaigns/campaigns.module';
import { CollaborationsModule } from '../collaborations/collaborations.module';
import { CreatorsModule } from '../creators/creators.module';
import { NotificationsModule } from '../notifications/notifications.module';
import { StoresModule } from '../stores/stores.module';
import { TermsModule } from '../terms/terms.module';
import { UsersModule } from '../users/users.module';
import { VisibilityModule } from '../visibility/visibility.module';
import { DiscoveryController } from './discovery.controller';
import { DiscoveryRepository } from './discovery.repository';
import { DiscoveryService } from './discovery.service';

@Module({
  imports: [
    UsersModule,
    BrandsModule,
    CampaignsModule,
    CreatorsModule,
    StoresModule,
    VisibilityModule,
    NotificationsModule,
    TermsModule,
    CollaborationsModule,
  ],
  controllers: [DiscoveryController],
  providers: [DiscoveryService, DiscoveryRepository],
})
export class DiscoveryModule {}
