import { Clock } from '../../src/common/clock';

// 손으로 시각을 움직이는 시계. 만료·기한 테스트가 실제 시간을 기다리지 않게 한다.
export class FakeClock extends Clock {
  private current: Date;

  constructor(start: Date = new Date('2026-11-11T03:00:00.000Z')) {
    super();
    this.current = new Date(start.getTime());
  }

  now(): Date {
    // 호출한 쪽이 돌려받은 Date를 고쳐도 시계가 바뀌지 않게 복사해 준다.
    return new Date(this.current.getTime());
  }

  set(d: Date): void {
    this.current = new Date(d.getTime());
  }

  advance(ms: number): void {
    this.current = new Date(this.current.getTime() + ms);
  }
}
