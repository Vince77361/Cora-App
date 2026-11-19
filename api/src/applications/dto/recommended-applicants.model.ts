import { ApiProperty } from '@nestjs/swagger';
import { CreatorSummaryModel } from '../../creators/dto/creator-profile.model';

export const RECOMMENDED_SOURCES = ['APPLICANTS', 'ALL'] as const;

// 추천 한 장. 이유는 점수에 쓴 사실로 서버가 만든 글 조각이다(없을 수 있다).
export class RecommendedApplicantModel {
  @ApiProperty({
    type: String,
    format: 'uuid',
    nullable: true,
    description: '지원 번호. 전체 크리에이터에서 뽑은 사람(ALL)은 null.',
  })
  applicationId!: string | null;

  @ApiProperty({ type: CreatorSummaryModel })
  creator!: CreatorSummaryModel;

  @ApiProperty({
    type: String,
    format: 'date-time',
    nullable: true,
    description: '지원한 시각(ISO 8601). 전체 크리에이터에서 뽑은 사람은 null.',
  })
  appliedAt!: string | null;

  @ApiProperty({
    type: String,
    nullable: true,
    description: '지원할 때 붙인 한 줄. 없으면 null.',
  })
  pitch!: string | null;

  @ApiProperty({
    type: [String],
    description: '추천 이유. 점수에 쓴 사실만 담는다.',
  })
  reasons!: string[];
}

// 가게 사장님 홈의 추천 3명(G2, 회의 반영 5.2).
export class RecommendedApplicantsModel {
  @ApiProperty({
    enum: RECOMMENDED_SOURCES,
    enumName: 'RecommendedSource',
    description:
      'APPLICANTS = 이 가게에 지원 중인 사람 중에서, ALL = 지원자가 없어 Cora 크리에이터 전체에서 뽑았다.',
  })
  source!: (typeof RECOMMENDED_SOURCES)[number];

  @ApiProperty({
    type: 'integer',
    description:
      '지원 중인 새 지원자 수. ALL이면 보여 줄 지원자가 없다(보통 0, 지원 줄은 있는데 프로필이 모두 지워졌으면 0보다 클 수 있다). 홈은 이 수가 아니라 source로 가른다.',
  })
  totalNew!: number;

  @ApiProperty({
    type: [RecommendedApplicantModel],
    description: '점수 높은 순 최대 3명.',
  })
  items!: RecommendedApplicantModel[];
}
