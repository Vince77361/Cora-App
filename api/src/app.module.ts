import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { ApplicationsModule } from './applications/applications.module';
import { AuthModule } from './auth/auth.module';
import { CommonModule } from './common/common.module';
import { ContentDraftsModule } from './content-drafts/content-drafts.module';
import { CreatorsModule } from './creators/creators.module';
import { loadEnv } from './config/env';
import { HealthModule } from './health/health.module';
import { InstagramModule } from './instagram/instagram.module';
import { IntegrationsModule } from './integrations/integrations.module';
import { JobsModule } from './jobs/jobs.module';
import { NotificationsModule } from './notifications/notifications.module';
import { OffersModule } from './offers/offers.module';
import { PaymentsDevModule } from './payments/payments-dev.module';
import { PaymentsModule } from './payments/payments.module';
import { PayoutAccountsModule } from './payout-accounts/payout-accounts.module';
import { PrismaModule } from './prisma/prisma.module';
import { StoresModule } from './stores/stores.module';
import { UploadsModule } from './uploads/uploads.module';
import { UsersModule } from './users/users.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true, validate: loadEnv }),
    CommonModule,
    PrismaModule,
    AuthModule,
    HealthModule,
    IntegrationsModule,
    JobsModule,
    NotificationsModule,
    UsersModule,
    UploadsModule,
    CreatorsModule,
    StoresModule,
    ContentDraftsModule,
    ApplicationsModule,
    InstagramModule,
    OffersModule,
    PaymentsModule,
    PayoutAccountsModule,
    PaymentsDevModule.register(process.env),
  ],
})
export class AppModule {}
