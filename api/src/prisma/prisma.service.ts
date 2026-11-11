import { Injectable, OnModuleDestroy, OnModuleInit } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';

// 연결 문자열은 Prisma가 schema.prisma의 env("DATABASE_URL")로 직접 읽는다.
// 코드에서 값을 다루지 않아 로그나 예외에 새어 나갈 길이 없다.
@Injectable()
export class PrismaService
  extends PrismaClient
  implements OnModuleInit, OnModuleDestroy
{
  // 기본 오류 형식에는 쿼리 인자 값이 들어가 로그로 새어 나갈 수 있어 최소 형식을 쓴다.
  constructor() {
    super({ errorFormat: 'minimal' });
  }

  async onModuleInit(): Promise<void> {
    await this.$connect();
  }

  async onModuleDestroy(): Promise<void> {
    await this.$disconnect();
  }
}
