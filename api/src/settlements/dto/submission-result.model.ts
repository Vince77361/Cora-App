import { ApiProperty } from '@nestjs/swagger';
import { CollaborationStage } from '@prisma/client';

// 링크 제출의 결과. 협업 모델이 생기면(9번 작업) 그것으로 바뀐다.
export class SubmissionResultModel {
  @ApiProperty({ format: 'uuid' })
  collaborationId!: string;

  @ApiProperty({
    enum: CollaborationStage,
    enumName: 'CollaborationStage',
    description:
      '제출 뒤의 단계. 조회수 보상이 있으면 COUNTING, 식사권만 있으면 SETTLED.',
  })
  stage!: CollaborationStage;
}
