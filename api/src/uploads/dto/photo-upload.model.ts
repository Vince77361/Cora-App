import { ApiProperty } from '@nestjs/swagger';

export class PhotoUploadModel {
  // 클라이언트가 이 주소로 파일을 PUT(Content-Type 포함)한다. 기한이 있다.
  @ApiProperty()
  uploadUrl!: string;

  // 올린 뒤 가게·크리에이터 저장 요청에 이 경로를 담는다. 서버가 소유자를 다시 확인한다.
  @ApiProperty()
  path!: string;
}
