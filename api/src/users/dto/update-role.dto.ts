import { ApiProperty } from '@nestjs/swagger';
import { UserRole } from '@prisma/client';
import { IsEnum } from 'class-validator';

// 역할은 고정 선택지이므로 allowlist로만 받는다.
export class UpdateRoleDto {
  @ApiProperty({ enum: ['STORE', 'BRAND', 'CREATOR'] })
  @IsEnum(['STORE', 'BRAND', 'CREATOR'])
  role!: UserRole;
}
