// 가게 이름으로 공개 주소 이름(cora.page/l/{slug})을 만든다. 순수 함수다.
// 한글은 음절을 초성·중성·종성으로 나눠 글자마다 로마자로 옮긴다(발음 변화는 반영하지 않는다).
const MAX_LENGTH = 40;
const FALLBACK = 'store';

const HANGUL_START = 0xac00;
const HANGUL_END = 0xd7a3;

const INITIALS = [
  'g',
  'kk',
  'n',
  'd',
  'tt',
  'r',
  'm',
  'b',
  'pp',
  's',
  'ss',
  '',
  'j',
  'jj',
  'ch',
  'k',
  't',
  'p',
  'h',
];
const VOWELS = [
  'a',
  'ae',
  'ya',
  'yae',
  'eo',
  'e',
  'yeo',
  'ye',
  'o',
  'wa',
  'wae',
  'oe',
  'yo',
  'u',
  'wo',
  'we',
  'wi',
  'yu',
  'eu',
  'ui',
  'i',
];
const FINALS = [
  '',
  'k',
  'k',
  'k',
  'n',
  'n',
  'n',
  't',
  'l',
  'k',
  'm',
  'l',
  'l',
  'l',
  'p',
  'l',
  'm',
  'p',
  'p',
  't',
  't',
  'ng',
  't',
  't',
  'k',
  't',
  'p',
  't',
];

function romanizeSyllable(code: number): string {
  const index = code - HANGUL_START;
  const initial = Math.floor(index / (21 * 28));
  const vowel = Math.floor((index % (21 * 28)) / 28);
  const final = index % 28;
  return INITIALS[initial] + VOWELS[vowel] + FINALS[final];
}

export function slugify(name: string): string {
  let out = '';
  for (const char of name.normalize('NFC')) {
    const code = char.codePointAt(0) ?? 0;
    if (code >= HANGUL_START && code <= HANGUL_END) {
      out += romanizeSyllable(code);
    } else if (/^[A-Za-z0-9]$/.test(char)) {
      out += char.toLowerCase();
    } else if (/^[\s-]$/.test(char)) {
      out += '-';
    }
    // 그 밖의 글자(기호, 이모지, 낱자 자모)는 버린다.
  }
  const slug = out
    .replace(/-{2,}/g, '-')
    .replace(/^-+|-+$/g, '')
    .slice(0, MAX_LENGTH)
    .replace(/-+$/g, '');
  return slug || FALLBACK;
}
