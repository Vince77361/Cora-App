import { ApiProperty } from '@nestjs/swagger';
import { BrandUsageRights, ContentFormat, FeeBand } from '@prisma/client';
import { IsUUID } from 'class-validator';
import { COMPARE_FIELDS, CompareField } from '../compare-rules';
import { INTEREST_STATES } from './interest-card.model';

export class CompareQuery {
  @ApiProperty({ format: 'uuid', description: '비교할 크리에이터 한 명.' })
  @IsUUID()
  a!: string;

  @ApiProperty({ format: 'uuid', description: '비교할 다른 크리에이터.' })
  @IsUUID()
  b!: string;
}

// 04 표의 한 열. 팔로워 수는 담지 않는다.
export class CompareSideModel {
  @ApiProperty({ format: 'uuid' })
  creatorId!: string;

  @ApiProperty()
  name!: string;

  @ApiProperty({ description: '"{X}의 …" 꼴이면 X, 아니면 이름 전체.' })
  shortName!: string;

  @ApiProperty({ type: String, nullable: true })
  photoUrl!: string | null;

  @ApiProperty({ enum: INTEREST_STATES, enumName: 'InterestState' })
  state!: (typeof INTEREST_STATES)[number];

  @ApiProperty({ type: String, format: 'uuid', nullable: true })
  collaborationId!: string | null;

  @ApiProperty({ enum: ContentFormat, enumName: 'ContentFormat' })
  format!: ContentFormat;

  @ApiProperty({ type: 'integer' })
  pieces!: number;

  @ApiProperty()
  productProvided!: boolean;

  @ApiProperty({
    type: 'integer',
    nullable: true,
    description:
      '서로 관심이면 최신 판본의 제작비, 아니면 내 제안의 금액, 없으면 null.',
  })
  fee!: number | null;

  @ApiProperty({
    enum: FeeBand,
    enumName: 'FeeBand',
    description:
      'fee가 null일 때 앱이 "30만 원대"로 보여 주는 희망 제작비 구간.',
  })
  feeBand!: FeeBand;

  @ApiProperty({ type: 'integer', nullable: true })
  perfCap!: number | null;

  @ApiProperty({ enum: BrandUsageRights, enumName: 'BrandUsageRights' })
  usageRights!: BrandUsageRights;

  @ApiProperty({ type: String, format: 'date', nullable: true })
  startDate!: string | null;

  @ApiProperty({ description: '크리에이터의 원칙 3번: 얼굴 출연이 괜찮은가.' })
  faceOk!: boolean;
}

export class CompareModel {
  @ApiProperty({ type: [CompareSideModel], minItems: 2, maxItems: 2 })
  sides!: [CompareSideModel, CompareSideModel];

  @ApiProperty({
    enum: COMPARE_FIELDS,
    enumName: 'CompareField',
    isArray: true,
    description: '두 후보의 보이는 값이 다른 줄(앞에 점을 붙인다).',
  })
  differs!: CompareField[];
}
