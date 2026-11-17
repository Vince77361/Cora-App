import { ApiProperty } from '@nestjs/swagger';
import {
  BrandUsageRights,
  ContentFormat,
  ProductTrialDays,
  RevisionScope,
} from '@prisma/client';
import { MATCH_REASONS } from '../../recommendations/dto/recommendation-cards.model';
import type { MatchReason } from '../../recommendations/match-score';
import { TERMS_FIELDS } from '../terms-diff';
import type { TermsField } from '../terms-diff';

export const TERMS_PROPOSERS = ['BRAND', 'CREATOR', 'SYSTEM'] as const;

export class TermsPerformanceModel {
  @ApiProperty({
    type: 'integer',
    description: '조회수 단가(1,000회당 원).',
  })
  ratePer1000!: number;

  @ApiProperty({ type: 'integer', description: '조회수 수당 상한(원).' })
  cap!: number;
}

// 조건 한 판본. 만들기만 하고 고치지 않는다(확인한 칸만 채워진다).
export class TermsVersionModel {
  @ApiProperty({ type: 'integer', description: '판본 번호(1부터).' })
  version!: number;

  @ApiProperty({
    enum: TERMS_PROPOSERS,
    enumName: 'TermsProposer',
    description: 'SYSTEM은 서로 관심이 닿을 때 서버가 만든 버전 1이다.',
  })
  proposedBy!: (typeof TERMS_PROPOSERS)[number];

  @ApiProperty({ description: '콘텐츠 제목(40자까지).' })
  title!: string;

  @ApiProperty({ type: 'integer', description: '제작비(원, 현금 고정비).' })
  fee!: number;

  @ApiProperty({
    type: TermsPerformanceModel,
    nullable: true,
    description: '성과 추가(조회수 수당). 없으면 null.',
  })
  performance!: TermsPerformanceModel | null;

  @ApiProperty({
    type: 'integer',
    description: '최대 현금 부담 = 제작비 + 성과 추가 상한(없으면 0).',
  })
  maxCash!: number;

  @ApiProperty({
    type: 'integer',
    nullable: true,
    description:
      '바로 앞 판본의 최대 현금 부담. 판본 1은 null이다(화면이 "A원 → B원"으로 보여 준다).',
  })
  previousMaxCash!: number | null;

  @ApiProperty({ type: String, format: 'date', description: '제작 시작.' })
  startDate!: string;

  @ApiProperty({ enum: ContentFormat, enumName: 'ContentFormat' })
  format!: ContentFormat;

  @ApiProperty({ type: 'integer', description: '편 수(1~3).' })
  pieces!: number;

  @ApiProperty({ description: '제품 제공 여부.' })
  productProvided!: boolean;

  @ApiProperty({ enum: RevisionScope, enumName: 'RevisionScope' })
  revisionScope!: RevisionScope;

  @ApiProperty({ enum: BrandUsageRights, enumName: 'BrandUsageRights' })
  usageRights!: BrandUsageRights;

  @ApiProperty({
    type: 'integer',
    description: '게시 뒤 지급까지 걸리는 날(7 또는 14).',
  })
  payoutDays!: number;

  @ApiProperty({ description: '브랜드가 이 판본을 확인했다.' })
  brandConfirmed!: boolean;

  @ApiProperty({ description: '크리에이터가 이 판본을 확인했다.' })
  creatorConfirmed!: boolean;

  @ApiProperty({
    enum: TERMS_FIELDS,
    enumName: 'TermsField',
    isArray: true,
    description: '바로 앞 판본에서 바뀐 항목. 판본 1은 빈 배열이다.',
  })
  changedFields!: TermsField[];

  @ApiProperty({
    type: String,
    format: 'date-time',
    description: '판본을 낸 시각.',
  })
  createdAt!: string;
}

// 협업의 가장 최근 판본과 화면(06)이 함께 보여 주는 값.
export class TermsLatestModel {
  @ApiProperty({ type: TermsVersionModel })
  terms!: TermsVersionModel;

  @ApiProperty({
    type: String,
    nullable: true,
    description:
      '크리에이터의 협업 원칙에서 만든 안내 줄. 해당하는 것이 없으면 null.',
  })
  notice!: string | null;

  @ApiProperty({
    enum: MATCH_REASONS,
    enumName: 'MatchReason',
    isArray: true,
    description: '크리에이터의 협업 원칙과 캠페인이 겹치는 규칙.',
  })
  reasons!: MatchReason[];

  @ApiProperty({
    type: String,
    isArray: true,
    description:
      '크리에이터가 협업 원칙에서 고른 분야의 이름표(고른 순서). 원칙이 없으면 빈 배열.',
  })
  fields!: string[];

  @ApiProperty({
    enum: ProductTrialDays,
    enumName: 'ProductTrialDays',
    description: '캠페인의 제품 사용 기간.',
  })
  trialDays!: ProductTrialDays;

  @ApiProperty({
    type: 'integer',
    nullable: true,
    description:
      '크리에이터가 연동한 인스타그램의 팔로워 수. 연동이 없으면 null.',
  })
  followers!: number | null;

  @ApiProperty({ description: '최신 판본을 내가 아직 확인하지 않았다.' })
  myTurn!: boolean;

  @ApiProperty({ description: '최신 판본을 내가 냈다.' })
  mine!: boolean;

  @ApiProperty({
    description:
      '내가 크리에이터이고, 성과 추가가 켜져 있고, 형식이 릴스나 카드뉴스이고, 인스타그램이 연동돼 있지 않다.',
  })
  needsInstagram!: boolean;
}
