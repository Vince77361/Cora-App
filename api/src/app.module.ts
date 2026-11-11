import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { AuthModule } from './auth/auth.module';
import { CommonModule } from './common/common.module';
import { CreatorsModule } from './creators/creators.module';
import { loadEnv } from './config/env';
import { HealthModule } from './health/health.module';
import { IntegrationsModule } from './integrations/integrations.module';
import { PrismaModule } from './prisma/prisma.module';
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
    UsersModule,
    UploadsModule,
    CreatorsModule,
  ],
})
export class AppModule {}
