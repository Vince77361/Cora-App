import { ApiProperty } from '@nestjs/swagger';

export class HealthModel {
  @ApiProperty({ enum: ['ok'] })
  status!: 'ok';
}
