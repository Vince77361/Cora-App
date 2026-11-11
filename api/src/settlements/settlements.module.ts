import { Module, OnModuleInit } from '@nestjs/common';
import { CollaborationsModule } from '../collaborations/collaborations.module';
import { CreatorsModule } from '../creators/creators.module';
import { InstagramModule } from '../instagram/instagram.module';
import { IntegrationsModule } from '../integrations/integrations.module';
import { JobHandlerRegistry } from '../jobs/job-handler-registry';
import { JobsModule } from '../jobs/jobs.module';
import { NotificationsModule } from '../notifications/notifications.module';
import { UsersModule } from '../users/users.module';
import { ViewSnapshotHandler } from './jobs/view-snapshot.handler';
import { SettlementsRepository } from './settlements.repository';
import { SettlementsService } from './settlements.service';
import { SubmissionsController } from './submissions.controller';
import { SubmissionsService } from './submissions.service';

// 링크 제출, 조회수 집계, 정산, 지급, 환급. 이 모듈의 작업 처리기는 여기서 작업 큐의 표에 올린다.
@Module({
  imports: [
    CollaborationsModule,
    JobsModule,
    NotificationsModule,
    IntegrationsModule,
    InstagramModule,
    CreatorsModule,
    UsersModule,
  ],
  controllers: [SubmissionsController],
  providers: [
    SettlementsRepository,
    SettlementsService,
    SubmissionsService,
    ViewSnapshotHandler,
  ],
  exports: [SettlementsService],
})
export class SettlementsModule implements OnModuleInit {
  constructor(
    private readonly registry: JobHandlerRegistry,
    private readonly viewSnapshot: ViewSnapshotHandler,
  ) {}

  onModuleInit(): void {
    this.registry.register('view-snapshot', (p) => this.viewSnapshot.run(p));
  }
}
