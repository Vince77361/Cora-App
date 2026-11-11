import { Controller, Get } from '@nestjs/common';
import { ApiOkResponse, ApiOperation } from '@nestjs/swagger';
import { Public } from '../auth/public.decorator';
import { HealthModel } from './health.model';

@Public()
@Controller('health')
export class HealthController {
  // operationId는 생성되는 Dart 메서드 이름이 되므로 명시해 고정한다.
  @Get()
  @ApiOperation({ operationId: 'getHealth' })
  @ApiOkResponse({ type: HealthModel })
  get(): HealthModel {
    return { status: 'ok' };
  }
}
