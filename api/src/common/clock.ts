import { Injectable } from '@nestjs/common';

// 시각은 항상 이 포트로 받는다. service나 순수 함수에서 new Date()를 쓰면 만료·기한 테스트를 못 쓴다.
// 추상 클래스를 Nest 주입 토큰으로 쓴다: constructor(private readonly clock: Clock)
export abstract class Clock {
  abstract now(): Date;
}

const DAY_MS = 24 * 60 * 60 * 1000;

// offsetDays는 수동 시험에서 시각을 며칠 앞당기려고 쓴다(FAKE_CLOCK_OFFSET_DAYS).
// 개발에서만 값이 들어오도록 CommonModule이 거른다.
@Injectable()
export class SystemClock extends Clock {
  constructor(private readonly offsetDays: number = 0) {
    super();
  }

  now(): Date {
    return new Date(Date.now() + this.offsetDays * DAY_MS);
  }
}
