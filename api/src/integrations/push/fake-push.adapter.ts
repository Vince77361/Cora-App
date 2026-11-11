import { Logger } from '@nestjs/common';
import { PushPort } from './push.port';

export class FakePushAdapter extends PushPort {
  private readonly logger = new Logger(FakePushAdapter.name);

  send(input: { userId: string; title: string; body: string }): Promise<void> {
    // 본문에는 개인정보가 들어갈 수 있어 로그에 남기지 않는다.
    this.logger.log(`푸시(가짜) userId=${input.userId} title=${input.title}`);
    return Promise.resolve();
  }
}
