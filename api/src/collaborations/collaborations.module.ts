import { Module } from '@nestjs/common';
import { CollaborationsRepository } from './collaborations.repository';

// 협업 저장소와 단계 규칙(순수 함수)만 가진다. 다른 기능 모듈을 import하지 않으므로
// 오퍼·결제·정산 같은 모듈이 이 모듈을 import해도 순환이 생기지 않는다(원장 판단 R10).
@Module({
  providers: [CollaborationsRepository],
  exports: [CollaborationsRepository],
})
export class CollaborationsModule {}
