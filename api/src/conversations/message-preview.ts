// 푸시와 대화 목록의 한 줄 미리 보기. 한 글자는 코드 포인트 하나로 세어 이모지가 반으로 잘리지 않게 한다.
export const PREVIEW_MAX = 60;

export function previewOf(text: string): string {
  const chars = Array.from(text);
  if (chars.length <= PREVIEW_MAX) return text;
  return `${chars.slice(0, PREVIEW_MAX).join('')}…`;
}
