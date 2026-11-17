import { ApiProperty } from '@nestjs/swagger';

export class ReportCreatedModel {
  @ApiProperty({ format: 'uuid' })
  id!: string;
}
