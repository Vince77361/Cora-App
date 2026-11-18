import { ApiProperty } from '@nestjs/swagger';
import { IsIn, IsOptional } from 'class-validator';

export const STORE_INTEREST_TABS = ['saved', 'sent'] as const;

export class ListStoreInterestsQuery {
  @ApiProperty({
    enum: STORE_INTEREST_TABS,
    enumName: 'StoreInterestTab',
    required: false,
    description:
      'saved(기본) = 내가 저장한 크리에이터, sent = 내가 하트를 보낸 크리에이터.',
  })
  @IsOptional()
  @IsIn(STORE_INTEREST_TABS)
  tab?: (typeof STORE_INTEREST_TABS)[number];
}

// 사장님 저장함(03)의 줄 하나. 크리에이터를 가리킨다.
export class StoreInterestCardModel {
  @ApiProperty({ format: 'uuid' })
  creatorId!: string;

  @ApiProperty({ description: '크리에이터의 활동 이름.' })
  name!: string;

  @ApiProperty({
    description: '"{X}의 …" 꼴이면 X, 아니면 이름 전체. 버튼 글자에 쓴다.',
  })
  shortName!: string;

  @ApiProperty({ type: String, nullable: true, description: '분야.' })
  contentFocus!: string | null;

  @ApiProperty({
    type: 'integer',
    nullable: true,
    description: '인스타그램 팔로워 수. 연동하지 않았으면 null.',
  })
  followers!: number | null;

  @ApiProperty({ type: String, nullable: true })
  photoUrl!: string | null;

  @ApiProperty({
    description:
      '서로 관심: 내가 하트를 보냈고 그 크리에이터가 이 가게에 살아 있는 지원(APPLIED·OFFERED)을 가졌다. 저장 탭에서는 늘 false다.',
  })
  mutual!: boolean;
}
