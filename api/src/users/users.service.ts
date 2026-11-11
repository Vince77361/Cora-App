import { Injectable } from '@nestjs/common';
import { User, UserRole } from '@prisma/client';
import { MeModel } from './dto/me.model';
import { UsersRepository } from './users.repository';

function toMe(user: User): MeModel {
  return { id: user.id, role: user.role };
}

@Injectable()
export class UsersService {
  constructor(private readonly users: UsersRepository) {}

  // 첫 로그인은 Supabase Auth에만 사용자가 있으므로 여기서 우리 쪽 행을 만든다.
  async getMe(userId: string): Promise<MeModel> {
    return toMe(await this.users.upsert(userId));
  }

  // 역할은 나중에 바꿀 수 있다(기획). 행이 없으면 먼저 만든다.
  async setRole(userId: string, role: UserRole): Promise<MeModel> {
    await this.users.upsert(userId);
    return toMe(await this.users.updateRole(userId, role));
  }
}
