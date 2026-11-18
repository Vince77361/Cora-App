import { Module } from '@nestjs/common';
import { IntegrationsModule } from '../integrations/integrations.module';
import { UploadsModule } from '../uploads/uploads.module';
import { UsersModule } from '../users/users.module';
import { CreatorsController } from './creators.controller';
import { CreatorsRepository } from './creators.repository';
import { CreatorsService } from './creators.service';
import { FeaturedPostsRepository } from './featured-posts.repository';
import { FeaturedPostsService } from './featured-posts.service';

@Module({
  imports: [IntegrationsModule, UploadsModule, UsersModule],
  controllers: [CreatorsController],
  providers: [
    CreatorsService,
    CreatorsRepository,
    FeaturedPostsService,
    FeaturedPostsRepository,
  ],
  // 지원자·오퍼 목록을 만드는 모듈은 CreatorsService만 쓴다.
  exports: [CreatorsService],
})
export class CreatorsModule {}
