import {
  kstTimeOnDate,
  kstWeekdayFromMonday,
  startOfKstDay,
  startOfKstWeek,
} from '../common/kst';

// 송금은 매주 수요일 10:00(한국 시간)에 모아서 한다(2026-11-11 소유자 결정). 순수 함수이고 시각은 인자로 받는다.
const DAY_MS = 24 * 60 * 60 * 1000;
const WEDNESDAY_FROM_MONDAY = 2;
const PAYDAY_HOUR_KST = 10;

// 정산이 확정된 시각이 속한 주(월요일 0시 시작)의 다음 주 수요일 10:00.
// 일요일 23:59 확정은 바로 다음 수요일이고, 월요일 0시 확정은 그다음 주 수요일이다.
export function nextPayday(settledAt: Date): Date {
  const nextWednesday = new Date(
    startOfKstWeek(settledAt).getTime() + (7 + WEDNESDAY_FROM_MONDAY) * DAY_MS,
  );
  return kstTimeOnDate(nextWednesday, PAYDAY_HOUR_KST);
}

// now 이후(같은 시각 포함) 가장 가까운 수요일 10:00. 수요일 10시 전이면 그날이다.
// 계좌 등록처럼 이미 지난 지급일을 다음 지급일로 옮길 때 쓴다.
export function upcomingPayday(now: Date): Date {
  const daysAhead = (WEDNESDAY_FROM_MONDAY - kstWeekdayFromMonday(now) + 7) % 7;
  const thisWednesday = kstTimeOnDate(
    new Date(startOfKstDay(now).getTime() + daysAhead * DAY_MS),
    PAYDAY_HOUR_KST,
  );
  if (thisWednesday.getTime() >= now.getTime()) return thisWednesday;
  return kstTimeOnDate(
    new Date(thisWednesday.getTime() + 7 * DAY_MS),
    PAYDAY_HOUR_KST,
  );
}
