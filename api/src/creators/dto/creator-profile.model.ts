import { ApiProperty } from '@nestjs/swagger';

// 다른 모듈의 목록(지원자, 오퍼)에 붙는 요약. 인스타그램 아이디는 담지 않는다.
export class CreatorSummaryModel {
  @ApiProperty({ format: 'uuid' })
  userId!: string;

  @ApiProperty()
  displayName!: string;

  @ApiProperty({ type: String, nullable: true })
  contentFocus!: string | null;

  @ApiProperty({ type: String, nullable: true })
  photoUrl!: string | null;

  @ApiProperty()
  regionSido!: string;

  @ApiProperty({ type: String, nullable: true })
  regionSigungu!: string | null;
}

export class CreatorProfileModel extends CreatorSummaryModel {
  @ApiProperty({ type: String, nullable: true })
  instagramHandle!: string | null;
}
