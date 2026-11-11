import { Global, Module } from '@nestjs/common';
import { Clock, SystemClock } from './clock';

// 모든 모듈이 import 없이 Clock을 주입받도록 전역으로 둔다.
@Global()
@Module({
  providers: [{ provide: Clock, useClass: SystemClock }],
  exports: [Clock],
})
export class CommonModule {}
