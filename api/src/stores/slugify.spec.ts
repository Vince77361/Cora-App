import { numberedSlug, slugify } from './slugify';

describe('slugify', () => {
  it('romanizes a korean store name into a slug', () => {
    expect(slugify('한그릇 라멘')).toBe('hangeureut-ramen');
  });

  it('splits a syllable into initial, vowel and final sounds', () => {
    expect(slugify('닭갈비')).toBe('dakgalbi');
    expect(slugify('쌍쌍')).toBe('ssangssang');
    expect(slugify('왕돈까스')).toBe('wangdonkkaseu');
  });

  it('keeps latin letters and digits and drops other symbols', () => {
    expect(slugify('Cafe 24 & Bar!')).toBe('cafe-24-bar');
    expect(slugify('  Blue   Bottle  ')).toBe('blue-bottle');
    expect(slugify('카페 A1')).toBe('kape-a1');
  });

  it('falls back to store for a name with no usable letters', () => {
    expect(slugify('')).toBe('store');
    expect(slugify('!!! ㅋㅋ ...')).toBe('store');
  });

  it('cuts the slug at 40 characters without a trailing dash', () => {
    const slug = slugify('a'.repeat(39) + ' b' + 'c'.repeat(10));
    expect(slug.length).toBeLessThanOrEqual(40);
    expect(slug.endsWith('-')).toBe(false);
    expect(slugify('a'.repeat(80))).toBe('a'.repeat(40));
  });

  it('keeps a numbered slug within 40 characters by cutting the base', () => {
    expect(numberedSlug('ramen', 2)).toBe('ramen-2');
    const long = 'a'.repeat(40);
    const numbered = numberedSlug(long, 12);
    expect(numbered).toBe('a'.repeat(37) + '-12');
    expect(numbered).toHaveLength(40);
    // 잘린 자리가 구분선이면 끝 -를 지우고 번호를 붙인다.
    expect(numberedSlug('a'.repeat(37) + '-bcd', 2)).toBe(
      'a'.repeat(37) + '-2',
    );
  });
});
