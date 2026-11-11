import { Logger } from '@nestjs/common';
import { OperatorAlertPort } from './operator-alert.port';

export class FakeOperatorAlertAdapter extends OperatorAlertPort {
  private readonly logger = new Logger(FakeOperatorAlertAdapter.name);

  alert(input: { subject: string; body: string }): Promise<void> {
    // 본문에는 개인정보가 들어갈 수 있어 제목만 로그에 남긴다.
    this.logger.log(`운영자 알림(가짜) subject=${input.subject}`);
    return Promise.resolve();
  }
}
