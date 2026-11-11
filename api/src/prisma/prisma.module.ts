import { Global, Module } from '@nestjs/common';
import { PrismaService } from './prisma.service';

// 모든 repository가 import 없이 주입받도록 전역으로 둔다.
@Global()
@Module({
  providers: [PrismaService],
  exports: [PrismaService],
})
export class PrismaModule {}
