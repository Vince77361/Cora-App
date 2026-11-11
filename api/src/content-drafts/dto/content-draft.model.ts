import { ApiProperty } from '@nestjs/swagger';
import { ContentDraftKind } from '@prisma/client';

export class DraftSceneModel {
  @ApiProperty()
  label!: string;

  @ApiProperty()
  text!: string;

  // true면 사장님의 대표 사진을 쓰는 장면이다.
  @ApiProperty()
  usesPhoto!: boolean;
}

export class ContentDraftModel {
  @ApiProperty({ enum: ContentDraftKind, enumName: 'ContentDraftKind' })
  kind!: ContentDraftKind;

  // 본문 위에 붙는 이름(카드뉴스 "본문", 릴스 "촬영 순서", 블로그 "도입부").
  @ApiProperty()
  bodyLabel!: string;

  @ApiProperty()
  body!: string;

  @ApiProperty({ type: [DraftSceneModel] })
  scenes!: DraftSceneModel[];

  // 오늘(한국 시간) 이 종류를 더 다시 만들 수 있는 횟수. 하루 10번이다.
  @ApiProperty({ type: 'integer', minimum: 0, maximum: 10 })
  regenerationsLeftToday!: number;
}
