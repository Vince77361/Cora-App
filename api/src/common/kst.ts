// 한국 시간(Asia/Seoul, UTC+9, 서머타임 없음) 계산. 모두 순수 함수이고 시각은 인자로 받는다(Clock은 호출한 쪽이 쥔다).
// 한국은 서머타임이 없어 하루는 늘 24시간이므로, 오프셋을 더하고 빼는 것만으로 날짜 경계가 맞는다.
const HOUR_MS = 60 * 60 * 1000;
const MINUTE_MS = 60 * 1000;
const DAY_MS = 24 * HOUR_MS;
const KST_OFFSET_MS = 9 * HOUR_MS;

// 그 순간이 속한 한국 날짜의 0시(UTC 시각).
export function startOfKstDay(at: Date): Date {
  const shifted = at.getTime() + KST_OFFSET_MS;
  // 1970년 이전의 음수 시각에서도 나머지가 음수가 되지 않게 한다.
  const intoDay = ((shifted % DAY_MS) + DAY_MS) % DAY_MS;
  return new Date(shifted - intoDay - KST_OFFSET_MS);
}

// 그 순간이 속한 한국 날짜의 한국 시계 hour:minute(UTC 시각). 예: 기한 알림의 "그날 10:00".
export function kstTimeOnDate(onDate: Date, hour: number, minute = 0): Date {
  if (!Number.isInteger(hour) || hour < 0 || hour > 23) {
    throw new Error(`시(hour)는 0~23의 정수여야 해요: ${hour}`);
  }
  if (!Number.isInteger(minute) || minute < 0 || minute > 59) {
    throw new Error(`분(minute)은 0~59의 정수여야 해요: ${minute}`);
  }
  return new Date(
    startOfKstDay(onDate).getTime() + hour * HOUR_MS + minute * MINUTE_MS,
  );
}

// 그 순간이 속한 한국 날짜의 요일을 월요일 0, 화요일 1, … 일요일 6으로 센다(주는 월요일 0시에 시작한다).
export function kstWeekdayFromMonday(at: Date): number {
  // 한국 날짜 0시에 9시간을 더하면 UTC 달력으로 같은 날짜의 0시라 getUTCDay가 한국 요일이 된다.
  const sameDateInUtc = new Date(startOfKstDay(at).getTime() + KST_OFFSET_MS);
  return (sameDateInUtc.getUTCDay() + 6) % 7;
}

// 그 순간이 속한 한국 시간의 주가 시작하는 월요일 0시(UTC 시각).
export function startOfKstWeek(at: Date): Date {
  return new Date(
    startOfKstDay(at).getTime() - kstWeekdayFromMonday(at) * DAY_MS,
  );
}

// 그 순간이 속한 한국 날짜를 'YYYY-MM-DD'로. 화면이 날짜만 보여 줄 때(지급일 등) 쓴다.
export function kstDateString(at: Date): string {
  return new Date(at.getTime() + KST_OFFSET_MS).toISOString().slice(0, 10);
}

// 그 순간이 속한 한국 시간의 달이 시작하는 1일 0시(UTC 시각). "이번 달"의 경계다.
export function startOfKstMonth(at: Date): Date {
  const shifted = new Date(at.getTime() + KST_OFFSET_MS);
  return new Date(
    Date.UTC(shifted.getUTCFullYear(), shifted.getUTCMonth(), 1) -
      KST_OFFSET_MS,
  );
}

// 그 순간이 속한 한국 시간의 달 다음 달 1일 0시(UTC 시각). 이번 달 범위의 끝(포함하지 않음)이다.
export function startOfNextKstMonth(at: Date): Date {
  const shifted = new Date(at.getTime() + KST_OFFSET_MS);
  return new Date(
    Date.UTC(shifted.getUTCFullYear(), shifted.getUTCMonth() + 1, 1) -
      KST_OFFSET_MS,
  );
}

// 그 순간이 속한 한국 날짜에서 달력으로 months개월 앞선 같은 날의 0시(UTC 시각). 그 달에 같은 날이 없으면 그 달의 마지막 날이다
// (5월 31일의 석 달 전은 2월 28일). "오늘부터 석 달 전까지" 같은 범위의 시작이다.
export function startOfKstDayMonthsAgo(at: Date, months: number): Date {
  const shifted = new Date(at.getTime() + KST_OFFSET_MS);
  const monthIndex =
    shifted.getUTCFullYear() * 12 + shifted.getUTCMonth() - months;
  const year = Math.floor(monthIndex / 12);
  const month = monthIndex - year * 12;
  const lastDay = new Date(Date.UTC(year, month + 1, 0)).getUTCDate();
  const day = Math.min(shifted.getUTCDate(), lastDay);
  return new Date(Date.UTC(year, month, day) - KST_OFFSET_MS);
}
