import { Module } from '@nestjs/common';
import { PrinciplesModule } from '../principles/principles.module';
import { VisibilityService } from './visibility.service';

@Module({
  imports: [PrinciplesModule],
  providers: [VisibilityService],
  // 가게·지원·오퍼·(5번 계획의) 탐색이 VisibilityService만 쓴다.
  exports: [VisibilityService],
})
export class VisibilityModule {}
