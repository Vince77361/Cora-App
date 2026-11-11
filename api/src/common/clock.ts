import { Injectable } from '@nestjs/common';

// 시각은 항상 이 포트로 받는다. service나 순수 함수에서 new Date()를 쓰면 만료·기한 테스트를 못 쓴다.
// 추상 클래스를 Nest 주입 토큰으로 쓴다: constructor(private readonly clock: Clock)
export abstract class Clock {
  abstract now(): Date;
}

@Injectable()
export class SystemClock extends Clock {
  now(): Date {
    return new Date();
  }
}
