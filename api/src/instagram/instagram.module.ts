import { Module } from '@nestjs/common';
import { CollaborationsModule } from '../collaborations/collaborations.module';
import { CreatorsModule } from '../creators/creators.module';
import { IntegrationsModule } from '../integrations/integrations.module';
import { UsersModule } from '../users/users.module';
import { InstagramController } from './instagram.controller';
import { InstagramRepository } from './instagram.repository';
import { InstagramService } from './instagram.service';

// CreatorsModule은 이 모듈을 import하지 않는다(순환 방지). 크리에이터 요약의 instagramConnected와 followers는
// CreatorsRepository가 연결 테이블을 관계로 읽는다.
@Module({
  imports: [
    IntegrationsModule,
    UsersModule,
    CreatorsModule,
    CollaborationsModule,
  ],
  controllers: [InstagramController],
  providers: [InstagramService, InstagramRepository],
  // 오퍼 모듈이 수락 조건(연결 여부)을 읽는다.
  exports: [InstagramService],
})
export class InstagramModule {}
