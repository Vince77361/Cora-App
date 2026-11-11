import { Logger } from '@nestjs/common';
import { PushData, PushPort } from './push.port';

export class FakePushAdapter extends PushPort {
  private readonly logger = new Logger(FakePushAdapter.name);

  send(input: {
    userId: string;
    title: string;
    body: string;
    data?: PushData;
  }): Promise<void> {
    // 본문에는 개인정보가 들어갈 수 있어 로그에 남기지 않는다. data는 ID와 종류뿐이라 함께 남긴다.
    const data = input.data ? ` data=${JSON.stringify(input.data)}` : '';
    this.logger.log(
      `푸시(가짜) userId=${input.userId} title=${input.title}${data}`,
    );
    return Promise.resolve();
  }
}
