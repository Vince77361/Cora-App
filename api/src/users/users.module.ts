import { Module } from '@nestjs/common';
import { UsersController } from './users.controller';
import { UsersRepository } from './users.repository';
import { UsersService } from './users.service';

@Module({
  controllers: [UsersController],
  providers: [UsersService, UsersRepository],
  // 다른 모듈은 UsersService만 쓴다(역할 확인).
  exports: [UsersService],
})
export class UsersModule {}
