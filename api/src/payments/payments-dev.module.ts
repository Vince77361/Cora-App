import { DynamicModule, Module } from '@nestjs/common';
import { IntegrationsModule } from '../integrations/integrations.module';
import { PaymentsDevController } from './payments.dev.controller';
import { PaymentsModule } from './payments.module';

export interface DevPaymentEnv {
  NODE_ENV?: string;
  PAYMENT_ADAPTER?: string;
}

// 개발 전용 가짜 결제 경로를 열지 정한다. 운영이 아니고 PAYMENT_ADAPTER가 fake일 때만이다.
// NODE_ENV는 개발·테스트로 허용된 값일 때만 연다(모르는 값이면 닫는다). PAYMENT_ADAPTER가 비어 있으면
// 환경변수 검증(loadEnv)이 개발에서 fake로 채우는 것과 같게 fake로 본다.
export function devPaymentRoutesEnabled(env: DevPaymentEnv): boolean {
  if (env.NODE_ENV !== 'development' && env.NODE_ENV !== 'test') return false;
  const adapter = env.PAYMENT_ADAPTER;
  return adapter === undefined || adapter === '' || adapter === 'fake';
}

// 조건에 맞지 않으면 컨트롤러를 아예 등록하지 않는다(가드로 막는 것이 아니라 라우트가 없다 → 404).
// 모듈 정의 시점에 정해지므로 AppModule이 process.env를 넘긴다(ConfigModule.forRoot가 .env를 먼저 올린다).
@Module({})
export class PaymentsDevModule {
  static register(env: DevPaymentEnv): DynamicModule {
    return {
      module: PaymentsDevModule,
      imports: [PaymentsModule, IntegrationsModule],
      controllers: devPaymentRoutesEnabled(env) ? [PaymentsDevController] : [],
    };
  }
}
