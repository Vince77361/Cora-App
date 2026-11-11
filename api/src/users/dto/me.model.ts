import { ApiProperty } from '@nestjs/swagger';
import { UserRole } from '@prisma/client';

export type MeRole = UserRole | null;

// Prisma 모델을 그대로 내보내지 않으려고 응답에 필요한 필드만 담는다.
export class MeModel {
  @ApiProperty({ format: 'uuid' })
  id!: string;

  @ApiProperty({ enum: ['STORE', 'BRAND', 'CREATOR'], nullable: true })
  role!: MeRole;
}
