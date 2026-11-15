import { Controller, Get } from '@nestjs/common';
import { ApiOkResponse, ApiOperation } from '@nestjs/swagger';
import { Public } from '../auth/public.decorator';
import { SkipRateLimit } from '../common/rate-limit/rate-limit';
import { HealthModel } from './health.model';

// 배포 확인과 로드밸런서의 상태 확인이 부르는 주소라 요청 수 제한에서 뺀다.
@Public()
@SkipRateLimit()
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
