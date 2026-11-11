import { Injectable } from '@nestjs/common';
import { Clock } from '../common/clock';

export const UPLOAD_URL_LIMIT = 30;
export const UPLOAD_URL_WINDOW_MS = 60 * 60 * 1000;

// 사용자별로 최근 1시간 동안 발급한 업로드 주소 수를 센다(최대 30개).
// 서버가 지금은 한 대라서 메모리에 둔다. 재시작하면 초기화되고 서버가 여러 대가 되면 맞지 않으므로,
// 출시 전에 전역 Redis 기반 제한으로 옮긴다(docs/superpowers/specs/2026-11-11-integrations-launch-design.md).
@Injectable()
export class UploadRateLimiter {
  private readonly issued = new Map<string, number[]>();
  private lastSweepAt = 0;

  constructor(private readonly clock: Clock) {}

  // 한도 안이면 1건을 센 뒤 true. 확인과 기록을 한 번에 해야 동시에 들어온 요청이 한도를 넘지 못한다.
  tryAcquire(userId: string): boolean {
    const now = this.clock.now().getTime();
    this.sweep(now);
    const recent = this.recent(userId, now);
    if (recent.length >= UPLOAD_URL_LIMIT) return false;
    recent.push(now);
    this.issued.set(userId, recent);
    return true;
  }

  // 주소 발급이 실패했으면 센 1건을 되돌린다. 한도는 "발급에 성공한 수"만 센다.
  release(userId: string): void {
    const list = this.issued.get(userId);
    if (!list) return;
    list.pop();
    if (list.length === 0) this.issued.delete(userId);
  }

  private recent(userId: string, now: number): number[] {
    const cutoff = now - UPLOAD_URL_WINDOW_MS;
    return (this.issued.get(userId) ?? []).filter((t) => t > cutoff);
  }

  // 한 번 쓰고 오지 않는 사용자의 기록이 계속 쌓이지 않도록, 창이 한 번 지날 때마다 전체를 훑어 비운다.
  private sweep(now: number): void {
    if (now - this.lastSweepAt < UPLOAD_URL_WINDOW_MS) return;
    this.lastSweepAt = now;
    for (const userId of [...this.issued.keys()]) {
      const recent = this.recent(userId, now);
      if (recent.length === 0) this.issued.delete(userId);
      else this.issued.set(userId, recent);
    }
  }
}
