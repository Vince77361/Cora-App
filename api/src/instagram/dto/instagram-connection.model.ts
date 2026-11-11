import { ApiProperty } from '@nestjs/swagger';

export class InstagramConnectionModel {
  @ApiProperty({ description: '연결된 인스타그램 아이디(@ 없이).' })
  handle!: string;

  @ApiProperty({ type: 'integer', nullable: true })
  followers!: number | null;
}

export class InstagramConnectUrlModel {
  @ApiProperty({ description: '앱이 열어서 인스타그램 승인을 받을 주소.' })
  connectUrl!: string;
}
