import { Module } from '@nestjs/common';
import { IntegrationsModule } from '../integrations/integrations.module';
import { StoresModule } from '../stores/stores.module';
import { UsersModule } from '../users/users.module';
import { ContentDraftsController } from './content-drafts.controller';
import { ContentDraftsRepository } from './content-drafts.repository';
import { ContentDraftsService } from './content-drafts.service';

@Module({
  imports: [IntegrationsModule, StoresModule, UsersModule],
  controllers: [ContentDraftsController],
  providers: [ContentDraftsService, ContentDraftsRepository],
})
export class ContentDraftsModule {}
