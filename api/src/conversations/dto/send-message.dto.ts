import { ApiProperty } from '@nestjs/swagger';
import {
  IsIn,
  IsOptional,
  IsString,
  IsUUID,
  MaxLength,
  MinLength,
} from 'class-validator';

export const SENDABLE_MESSAGE_KINDS = ['TEXT', 'CONTENT_CARD'] as const;
export const MESSAGE_TEXT_MAX = 1000;

export class SendMessageDto {
  @ApiProperty({
    format: 'uuid',
    description:
      '앱이 만든 중복 방지 값. 같은 값으로 다시 보내면 새 메시지를 만들지 않고 첫 메시지를 돌려준다.',
  })
  @IsUUID()
  clientId!: string;

  @ApiProperty({
    enum: SENDABLE_MESSAGE_KINDS,
    enumName: 'SendableMessageKind',
    description: 'CONTENT_CARD는 크리에이터만 보낼 수 있다.',
  })
  @IsIn(SENDABLE_MESSAGE_KINDS)
  kind!: (typeof SENDABLE_MESSAGE_KINDS)[number];

  @ApiProperty({
    required: false,
    minLength: 1,
    maxLength: MESSAGE_TEXT_MAX,
    description: '글 메시지의 글(1~1000자). 콘텐츠 카드에는 쓰지 않는다.',
  })
  @IsOptional()
  @IsString()
  @MinLength(1)
  @MaxLength(MESSAGE_TEXT_MAX)
  text?: string;
}
