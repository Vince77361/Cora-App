import { Controller, Get, Header } from '@nestjs/common';
import { ApiOkResponse, ApiOperation } from '@nestjs/swagger';
import { Public } from '../auth/public.decorator';
import { AppConfigService } from './app-config.service';
import { AppConfigModel } from './dto/app-config.model';

@Public()
@Controller('config')
export class AppConfigController {
  constructor(private readonly service: AppConfigService) {}

  // 로그인 전에도 읽는다(가입 없이 먼저 보는 화면). 자주 바뀌지 않아 1분 캐시한다.
  @Get()
  @Header('Cache-Control', 'max-age=60')
  @ApiOperation({ operationId: 'getAppConfig' })
  @ApiOkResponse({ type: AppConfigModel })
  get(): AppConfigModel {
    return this.service.get();
  }
}
