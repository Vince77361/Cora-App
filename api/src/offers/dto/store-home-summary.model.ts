import { ApiProperty } from '@nestjs/swagger';

// 사장님 홈 위쪽의 숫자 세 개.
export class StoreHomeSummaryModel {
  @ApiProperty({
    type: 'integer',
    description: '아직 오퍼를 보내지 않은 지원.',
  })
  newApplications!: number;

  @ApiProperty({ type: 'integer', description: '답을 기다리는 보낸 오퍼.' })
  sentOffers!: number;

  @ApiProperty({ type: 'integer', description: '수락된 오퍼.' })
  inProgress!: number;
}
