import { Inject, Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { ThrottlerStorage } from '@nestjs/throttler';
import { Env } from '../config/env';
import { clientIpOf } from './client-ip';

const MINUTE_MS = 60_000;

// 소켓 연결 시도의 IP별 요청 수 제한. HTTP의 IP 제한(RATE_LIMIT_IP_PER_MIN)과 같은 값·같은 저장소를 쓰되 키를 따로 둬서
// 소켓 시도가 일반 API의 한도를 깎지 않게 한다. 연결 시도마다 토큰 검증(JWKS)과 로그 한 줄이 드는데, 소켓 핸드셰이크는
// Nest 가드를 지나지 않아 이 제한이 없으면 잘못된 토큰 홍수가 그대로 열린다.
@Injectable()
export class ConnectionLimiter {
  private readonly limit: number;
  private readonly trustedHops: number;

  constructor(
    @Inject(ThrottlerStorage) private readonly storage: ThrottlerStorage,
    config: ConfigService<Env, true>,
  ) {
    this.limit = config.get('RATE_LIMIT_IP_PER_MIN', { infer: true });
    this.trustedHops = config.get('TRUST_PROXY_HOPS', { infer: true });
  }

  // 이 연결 시도를 받아도 되는지. 저장소가 실패하면 모든 사용자를 막지 않으려고 받아 준다(토큰 검증은 그대로 한다).
  async allow(request: Parameters<typeof clientIpOf>[0]): Promise<boolean> {
    try {
      const ip = clientIpOf(request, this.trustedHops);
      const record = await this.storage.increment(
        `ws-connect:${ip}`,
        MINUTE_MS,
        this.limit,
        0,
        'ip',
      );
      return !record.isBlocked && record.totalHits <= this.limit;
    } catch {
      return true;
    }
  }
}
