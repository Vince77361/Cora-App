import { Injectable } from '@nestjs/common';
import { User, UserRole } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class UsersRepository {
  constructor(private readonly prisma: PrismaService) {}

  findById(id: string): Promise<User | null> {
    return this.prisma.user.findUnique({ where: { id } });
  }

  // 동시에 두 번 호출돼도 행이 하나만 생기도록 upsert를 쓴다. 이미 있으면 바꾸지 않는다.
  upsert(id: string): Promise<User> {
    return this.prisma.user.upsert({
      where: { id },
      create: { id },
      update: {},
    });
  }

  updateRole(id: string, role: UserRole): Promise<User> {
    return this.prisma.user.update({ where: { id }, data: { role } });
  }
}
