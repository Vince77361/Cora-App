import { ApiProperty } from '@nestjs/swagger';

// 같은 이름의 가게 지점 하나. 직접 입력 화면이 고르게 한다.
export class StoreBranchModel {
  @ApiProperty({ description: '지점 이름(예: 성수점).' })
  label!: string;

  @ApiProperty()
  address!: string;

  @ApiProperty({ type: String, nullable: true })
  neighborhood!: string | null;

  @ApiProperty({ type: String, nullable: true })
  regionSido!: string | null;

  @ApiProperty({ type: String, nullable: true })
  regionSigungu!: string | null;
}
