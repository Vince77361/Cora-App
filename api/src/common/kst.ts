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
