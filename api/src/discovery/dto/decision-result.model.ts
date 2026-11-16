import { ApiProperty } from '@nestjs/swagger';
import { SwipeDecisionKind, SwipeTargetKind } from '@prisma/client';

export class DecisionResultModel {
  @ApiProperty({ enum: SwipeDecisionKind, enumName: 'SwipeDecisionKind' })
  decision!: SwipeDecisionKind;

  @ApiProperty({ description: '이 결정으로 서로 관심이 닿았는가.' })
  matched!: boolean;

  @ApiProperty({
    type: String,
    format: 'uuid',
    nullable: true,
    description: '서로 관심으로 생긴 협업의 id. 닿지 않았으면 null.',
  })
  collaborationId!: string | null;
}

// 되돌린 결정이 가리키던 대상. 앱이 그 카드를 다시 맨 위에 올린다.
export class UndoneDecisionModel {
  @ApiProperty({ enum: SwipeTargetKind, enumName: 'SwipeTargetKind' })
  targetKind!: SwipeTargetKind;

  @ApiProperty({ format: 'uuid' })
  targetId!: string;
}
