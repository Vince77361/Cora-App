import { Module } from '@nestjs/common';
import { TermsRepository } from './terms.repository';
import { TermsService } from './terms.service';

// 조건 판본의 저장과 읽기. 서로 관심 트랜잭션(발견)과 대화방(머리의 최신 조건)이 TermsService만 쓴다.
// 이 모듈은 다른 기능 모듈을 import하지 않는다: 대화 모듈이 이 모듈을 import하므로, 대화방에 안내 줄을 남기는
// 조건 확인·새 판본 API는 TermsApiModule이 맡아 순환을 피한다(원장 판단 R10과 같은 모양).
@Module({
  providers: [TermsService, TermsRepository],
  exports: [TermsService],
})
export class TermsModule {}
