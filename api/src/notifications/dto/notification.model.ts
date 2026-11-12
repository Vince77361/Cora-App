import { ApiProperty } from '@nestjs/swagger';
import { NotificationGlyph, NotificationTab } from '@prisma/client';

export class NotificationActorModel {
  @ApiProperty({ description: '알림을 만들 때 저장한 상대의 이름 사본.' })
  name!: string;

  @ApiProperty({
    type: String,
    nullable: true,
    description:
      '상대 사진의 공개 주소. 사진이 없으면 null(앱이 이름 첫 글자를 그린다).',
  })
  photoUrl!: string | null;
}

export class NotificationTargetModel {
  @ApiProperty({
    description:
      '누르면 가는 곳의 종류(예: COLLABORATION, OFFER_INBOX, WALLET). 앱이 화면으로 바꾼다.',
  })
  kind!: string;

  @ApiProperty({ type: String, nullable: true })
  id!: string | null;
}

export class NotificationModel {
  @ApiProperty({ format: 'uuid' })
  id!: string;

  @ApiProperty({ enum: NotificationTab, enumName: 'NotificationTab' })
  tab!: NotificationTab;

  @ApiProperty({ description: '종류와 값으로 만든 문구(카탈로그의 render).' })
  text!: string;

  @ApiProperty({
    enum: NotificationGlyph,
    enumName: 'NotificationGlyph',
    nullable: true,
    description: '글자 그림. 정산은 WON(₩), 없으면 상대 사진.',
  })
  glyph!: NotificationGlyph | null;

  @ApiProperty({ type: NotificationActorModel, nullable: true })
  actor!: NotificationActorModel | null;

  @ApiProperty({ type: NotificationTargetModel })
  target!: NotificationTargetModel;

  @ApiProperty({ format: 'date-time', description: '만든 시각(ISO 8601).' })
  createdAt!: string;

  @ApiProperty()
  read!: boolean;
}

export class NotificationPageModel {
  @ApiProperty({ type: [NotificationModel] })
  items!: NotificationModel[];

  @ApiProperty({
    type: String,
    nullable: true,
    description:
      '다음 쪽을 부르는 값(그대로 cursor에 넣는다). 마지막 쪽이면 null.',
  })
  nextCursor!: string | null;
}

export class UnreadCountModel {
  @ApiProperty({ description: '지금 역할의 읽지 않은 알림 수(최근 90일).' })
  count!: number;
}
