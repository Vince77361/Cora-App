import { ApiProperty } from '@nestjs/swagger';
import { UserRole } from '@prisma/client';

export type MeRole = UserRole | null;

// Prisma 모델을 그대로 내보내지 않으려고 응답에 필요한 필드만 담는다.
export class MeModel {
  @ApiProperty({ format: 'uuid' })
  id!: string;

  // enumName을 같게 두어 문서와 Dart 클라이언트에 UserRole 열거형이 하나만 생기게 한다.
  @ApiProperty({ enum: UserRole, enumName: 'UserRole', nullable: true })
  role!: MeRole;
}
