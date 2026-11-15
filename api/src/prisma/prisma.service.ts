import {
  Injectable,
  OnApplicationShutdown,
  OnModuleInit,
} from '@nestjs/common';
import { PrismaClient } from '@prisma/client';

// 연결 문자열은 Prisma가 schema.prisma의 env("DATABASE_URL")로 직접 읽는다.
// 코드에서 값을 다루지 않아 로그나 예외에 새어 나갈 길이 없다.
@Injectable()
export class PrismaService
  extends PrismaClient
  implements OnModuleInit, OnApplicationShutdown
{
  // 기본 오류 형식에는 쿼리 인자 값이 들어가 로그로 새어 나갈 수 있어 최소 형식을 쓴다.
  constructor() {
    super({ errorFormat: 'minimal' });
  }

  async onModuleInit(): Promise<void> {
    await this.$connect();
  }

  // onModuleDestroy가 아니라 가장 마지막 훅에서 닫는다. 종료 순서는 작업자 닫기(진행 중 작업 대기) → HTTP 서버 정리(처리 중 요청 대기) → 여기다.
  // 먼저 닫으면 아직 처리 중인 요청과 작업의 쿼리가 끊기거나 Prisma가 다시 연결해 풀이 열린 채 프로세스가 끝난다.
  async onApplicationShutdown(): Promise<void> {
    await this.$disconnect();
  }
}
