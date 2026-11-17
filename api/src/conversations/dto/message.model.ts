import { ApiProperty } from '@nestjs/swagger';
import { MessageKind } from '@prisma/client';

export class MessageCardModel {
  @ApiProperty({ description: '카드를 보낸 시점의 콘텐츠 제목(사본).' })
  title!: string;

  @ApiProperty({
    type: String,
    nullable: true,
    description: '카드를 보낸 시점의 사진(사본). 없으면 null.',
  })
  photoUrl!: string | null;
}

export class MessageModel {
  @ApiProperty({ format: 'uuid' })
  id!: string;

  @ApiProperty({
    type: 'integer',
    description: '방 안의 번호(1부터, 빠짐없이 늘어난다).',
  })
  seq!: number;

  @ApiProperty({ enum: MessageKind, enumName: 'MessageKind' })
  kind!: MessageKind;

  @ApiProperty({ description: '내가 보낸 메시지이면 true. 안내 줄은 false.' })
  mine!: boolean;

  @ApiProperty({
    type: String,
    nullable: true,
    description: '앱이 보낸 중복 방지 값. 내가 보낸 메시지에만 있다.',
  })
  clientId!: string | null;

  @ApiProperty({
    type: String,
    nullable: true,
    description:
      '글 메시지의 글, 안내 줄은 읽는 사람에 맞춰 서버가 만든 문구. 콘텐츠 카드는 null.',
  })
  text!: string | null;

  @ApiProperty({ type: MessageCardModel, nullable: true })
  card!: MessageCardModel | null;

  @ApiProperty({ type: String, format: 'date-time' })
  createdAt!: string;
}
