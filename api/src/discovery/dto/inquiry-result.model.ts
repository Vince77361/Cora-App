import { ApiProperty } from '@nestjs/swagger';

export class InquiryResultModel {
  @ApiProperty({
    format: 'uuid',
    description: '만들어진 협업(단계 INQUIRY)의 id.',
  })
  collaborationId!: string;

  @ApiProperty({
    format: 'uuid',
    description: '메시지 요청 상태로 만들어진 대화방의 id.',
  })
  conversationId!: string;
}
