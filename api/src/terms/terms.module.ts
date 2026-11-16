import { Module } from '@nestjs/common';
import { TermsRepository } from './terms.repository';
import { TermsService } from './terms.service';

// 조건 판본. 서로 관심 트랜잭션(발견)과 새 판본 제안(5번 계획)이 TermsService만 쓴다.
@Module({
  providers: [TermsService, TermsRepository],
  exports: [TermsService],
})
export class TermsModule {}
