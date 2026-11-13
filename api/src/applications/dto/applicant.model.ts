import { ApiProperty } from '@nestjs/swagger';
import { CreatorSummaryModel } from '../../creators/dto/creator-profile.model';

// 가게 사장님이 보는 지원자 한 줄. 아직 오퍼를 보내지 않은(APPLIED) 지원만 나온다.
export class ApplicantModel {
  @ApiProperty({ format: 'uuid' })
  applicationId!: string;

  @ApiProperty({ type: CreatorSummaryModel })
  creator!: CreatorSummaryModel;

  @ApiProperty({ format: 'date-time', description: '지원한 시각(ISO 8601).' })
  appliedAt!: string;

  @ApiProperty({
    type: String,
    nullable: true,
    description: '지원할 때 붙인 한 줄. 없으면 null.',
  })
  pitch!: string | null;
}
