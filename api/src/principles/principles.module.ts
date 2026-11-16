import { Module } from '@nestjs/common';
import { UsersModule } from '../users/users.module';
import { PrinciplesController } from './principles.controller';
import { PrinciplesRepository } from './principles.repository';
import { PrinciplesService } from './principles.service';

@Module({
  imports: [UsersModule],
  controllers: [PrinciplesController],
  providers: [PrinciplesService, PrinciplesRepository],
  // 공통 필터(visibility), 카드 조회, 프로필 수정이 PrinciplesService만 쓴다.
  exports: [PrinciplesService],
})
export class PrinciplesModule {}
