import { HALT_AFTER_UNREADABLE_DAYS, SNAPSHOT_DAYS } from './job-keys';

// "조회수를 연속 3일 읽지 못했는가"의 판정. 날마다의 스냅샷 작업, 7일째의 정산 작업, 캡처를 받는 API가 같은 규칙을 쓴다.
// 돌려주는 값이 참이면 연결 계정으로는 조회수를 믿을 수 없다는 뜻이라 크리에이터에게 캡처를 요청한다.
//
// - 가장 최근 세 줄이 모두 null이면(읽지 못한 날이 연속 3일) 참이다.
// - atSettlement이면 마지막 3일(5~7일)을 날로 세는 판정을 더한다: 줄이 없는 날(작업이 시도를 다 쓰고 죽었거나 작업자를 다시 켜느라
//   건너뛴 날)도 읽지 못한 날이라, 5일째 null·6일째 줄 없음·7일째 null이면 4일째 값으로 정산하지 않는다.
export function isViewCountUnreadable(
  snapshots: { dayIndex: number; views: number | null }[],
  options: { atSettlement: boolean },
): boolean {
  const latest = [...snapshots]
    .sort((a, b) => b.dayIndex - a.dayIndex)
    .slice(0, HALT_AFTER_UNREADABLE_DAYS);
  const rowsAllNull =
    latest.length === HALT_AFTER_UNREADABLE_DAYS &&
    latest.every((s) => s.views === null);
  if (rowsAllNull) return true;
  if (!options.atSettlement) return false;
  const byDay = new Map(snapshots.map((s) => [s.dayIndex, s.views]));
  return Array.from(
    { length: HALT_AFTER_UNREADABLE_DAYS },
    (_, i) => SNAPSHOT_DAYS - i,
  ).every((day) => (byDay.get(day) ?? null) === null);
}
