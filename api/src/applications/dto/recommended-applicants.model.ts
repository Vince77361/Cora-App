import { ApiProperty } from '@nestjs/swagger';
import { CreatorSummaryModel } from '../../creators/dto/creator-profile.model';

// 추천 한 장. 이유는 점수에 쓴 사실로 서버가 만든 글 조각이다(없을 수 있다).
export class RecommendedApplicantModel {
  @ApiProperty({ format: 'uuid' })
  applicationId!: string;

  @ApiProperty({ type: CreatorSummaryModel })
  creator!: CreatorSummaryModel;

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

// 가게 사장님 홈의 "지원자 추천 3명"(G2).
export class RecommendedApplicantsModel {
  @ApiProperty({
    type: 'integer',
    description: '지원 중인 새 지원자 수(추천에서 넘긴 사람도 센다).',
  })
  totalNew!: number;

  @ApiProperty({
    type: [RecommendedApplicantModel],
    description: '점수 높은 순 최대 3명. 추천에서 넘긴 지원은 뺀다.',
  })
  items!: RecommendedApplicantModel[];
}
