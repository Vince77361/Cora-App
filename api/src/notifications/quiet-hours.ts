export type QuietHoursMode = 'OFF' | 'NIGHT' | 'WEEKEND';

// 한국은 서머타임이 없는 UTC+9라 고정 9시간을 더해 한국 시계를 얻는다.
const KST_OFFSET_MS = 9 * 60 * 60 * 1000;

// 방해 금지 시간인지. NIGHT는 22:00 이상 또는 08:00 미만, WEEKEND는 토요일 00:00부터 월요일 00:00 전까지다.
// 시각은 호출한 쪽이 Clock에서 읽어 넘긴다.
export function isQuietAt(now: Date, quiet: QuietHoursMode): boolean {
  if (quiet === 'OFF') return false;
  const kst = new Date(now.getTime() + KST_OFFSET_MS);
  if (quiet === 'NIGHT') {
    const hour = kst.getUTCHours();
    return hour >= 22 || hour < 8;
  }
  const day = kst.getUTCDay();
  return day === 6 || day === 0;
}
