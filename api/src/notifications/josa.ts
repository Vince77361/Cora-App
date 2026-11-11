export type JosaPair = '이/가' | '과/와' | '을/를' | '은/는';

// 숫자를 한글로 읽었을 때 마지막 글자에 받침이 있는지: 영·일·삼·육·칠·팔은 있고 이·사·오·구는 없다.
const DIGIT_HAS_FINAL: Record<string, boolean> = {
  '0': true,
  '1': true,
  '2': false,
  '3': true,
  '4': false,
  '5': false,
  '6': true,
  '7': true,
  '8': true,
  '9': false,
};

// 받침이 있으면 true, 없으면 false, 한글도 숫자도 아니면 null.
function hasFinalConsonant(word: string): boolean | null {
  const last = word.trimEnd().slice(-1);
  if (last === '') return null;
  const code = last.charCodeAt(0);
  if (code >= 0xac00 && code <= 0xd7a3) return (code - 0xac00) % 28 !== 0;
  return DIGIT_HAS_FINAL[last] ?? null;
}

// 단어 뒤에 받침에 맞는 조사를 붙인다. 판단할 수 없는 글자(영문 등)면 "이(가)"처럼 둘 다 쓴다.
export function josa(word: string, pair: JosaPair): string {
  const [withFinal, without] = pair.split('/');
  const final = hasFinalConsonant(word);
  if (final === null) return `${word}${withFinal}(${without})`;
  return `${word}${final ? withFinal : without}`;
}
