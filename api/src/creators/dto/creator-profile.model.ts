import { ApiProperty } from '@nestjs/swagger';

// 다른 모듈의 목록(지원자, 오퍼)에 붙는 요약. 인스타그램 아이디는 담지 않고, 연결 여부와 팔로워 수만 담는다.
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

  @ApiProperty({ description: '인스타그램 계정을 연결했으면 true.' })
  instagramConnected!: boolean;

  @ApiProperty({
    type: 'integer',
    nullable: true,
    description: '연결한 계정의 팔로워 수. 연결이 없거나 읽지 못했으면 null.',
  })
  followers!: number | null;
}

export class CreatorProfileModel extends CreatorSummaryModel {
  @ApiProperty({ type: String, nullable: true })
  instagramHandle!: string | null;
}
