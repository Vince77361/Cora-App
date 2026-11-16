import { ApiProperty } from '@nestjs/swagger';
import { IndustryCategory } from '@prisma/client';

// 브랜드가 자기 프로필을 읽는 모양. 크리에이터가 보는 브랜드 카드는 4번 계획의 카드 모델이 따로 만든다.
export class BrandProfileModel {
  @ApiProperty({ format: 'uuid' })
  userId!: string;

  @ApiProperty({ minLength: 1, maxLength: 30 })
  name!: string;

  @ApiProperty({ type: String, nullable: true, maxLength: 40 })
  tagline!: string | null;

  @ApiProperty({ enum: IndustryCategory, enumName: 'IndustryCategory' })
  industry!: IndustryCategory;

  @ApiProperty({ type: String, nullable: true })
  photoUrl!: string | null;
}
