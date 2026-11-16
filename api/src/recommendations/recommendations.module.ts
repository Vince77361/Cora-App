import { Module } from '@nestjs/common';
import { BrandsModule } from '../brands/brands.module';
import { CampaignsModule } from '../campaigns/campaigns.module';
import { CollaborationsModule } from '../collaborations/collaborations.module';
import { CreatorsModule } from '../creators/creators.module';
import { PrinciplesModule } from '../principles/principles.module';
import { StoresModule } from '../stores/stores.module';
import { UsersModule } from '../users/users.module';
import { VisibilityModule } from '../visibility/visibility.module';
import { RecommendationsController } from './recommendations.controller';
import { RecommendationsRepository } from './recommendations.repository';
import { RecommendationsService } from './recommendations.service';

@Module({
  imports: [
    UsersModule,
    BrandsModule,
    CampaignsModule,
    CreatorsModule,
    StoresModule,
    PrinciplesModule,
    VisibilityModule,
    CollaborationsModule,
  ],
  controllers: [RecommendationsController],
  providers: [RecommendationsService, RecommendationsRepository],
})
export class RecommendationsModule {}
