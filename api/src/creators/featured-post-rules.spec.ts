import { AppError } from '../common/errors/app-error';
import {
  FeaturedPostDraft,
  MAX_CAPTION,
  MAX_FEATURED_POSTS,
  firstLine,
  validateReplacement,
} from './featured-post-rules';

function draft(over: Partial<FeaturedPostDraft> = {}): FeaturedPostDraft {
  return {
    source: 'GALLERY',
    kind: 'PHOTO',
    mediaPath: 'featured-posts/u/a.jpg',
    thumbnailPath: null,
    caption: '오늘의 한 줄',
    instagramMediaId: null,
    ...over,
  };
}

function failure(items: FeaturedPostDraft[]): AppError | undefined {
  try {
    validateReplacement(items);
  } catch (e) {
    return e as AppError;
  }
  return undefined;
}

describe('featured post rules', () => {
  it('accepts an empty list', () => {
    expect(() => validateReplacement([])).not.toThrow();
  });

  it('accepts four valid posts', () => {
    const items = Array.from({ length: MAX_FEATURED_POSTS }, () => draft());
    expect(() => validateReplacement(items)).not.toThrow();
  });

  it('rejects a fifth post', () => {
    const items = Array.from({ length: MAX_FEATURED_POSTS + 1 }, () => draft());
    expect(failure(items)?.code).toBe('VALIDATION_FAILED');
  });

  it('rejects a caption longer than 40 characters', () => {
    const error = failure([draft({ caption: 'ㄱ'.repeat(MAX_CAPTION + 1) })]);
    expect(error?.code).toBe('VALIDATION_FAILED');
    expect(() =>
      validateReplacement([draft({ caption: 'ㄱ'.repeat(MAX_CAPTION) })]),
    ).not.toThrow();
  });

  it('rejects a gallery video', () => {
    expect(failure([draft({ kind: 'VIDEO' })])?.code).toBe('VALIDATION_FAILED');
  });

  it('rejects a gallery post without a caption', () => {
    expect(failure([draft({ caption: null })])?.code).toBe('VALIDATION_FAILED');
  });

  it('rejects the same instagram media id twice', () => {
    const insta = (id: string) =>
      draft({ source: 'INSTAGRAM', caption: null, instagramMediaId: id });
    expect(failure([insta('p1'), insta('p1')])?.code).toBe('VALIDATION_FAILED');
    expect(() => validateReplacement([insta('p1'), insta('p2')])).not.toThrow();
  });

  it('rejects an instagram post without its media id and a gallery post with one', () => {
    expect(
      failure([draft({ source: 'INSTAGRAM', instagramMediaId: null })])?.code,
    ).toBe('VALIDATION_FAILED');
    expect(failure([draft({ instagramMediaId: 'p1' })])?.code).toBe(
      'VALIDATION_FAILED',
    );
  });

  it('allows an instagram video without a caption when it has a thumbnail', () => {
    expect(() =>
      validateReplacement([
        draft({
          source: 'INSTAGRAM',
          kind: 'VIDEO',
          caption: null,
          thumbnailPath: 'featured-posts/u/t.jpg',
          instagramMediaId: 'p1',
        }),
      ]),
    ).not.toThrow();
  });

  it('rejects an instagram video without a thumbnail', () => {
    expect(
      failure([
        draft({
          source: 'INSTAGRAM',
          kind: 'VIDEO',
          caption: null,
          thumbnailPath: null,
          instagramMediaId: 'p1',
        }),
      ])?.code,
    ).toBe('VALIDATION_FAILED');
  });
});

describe('firstLine', () => {
  it('takes the first line of an instagram caption up to 40 characters', () => {
    expect(firstLine('첫 줄이에요\n둘째 줄')).toBe('첫 줄이에요');
    expect(firstLine('가'.repeat(60))).toBe('가'.repeat(MAX_CAPTION));
    expect(firstLine('\n\n  앞의 빈 줄은 건너뛰어요  \n뒤')).toBe(
      '앞의 빈 줄은 건너뛰어요',
    );
  });

  it('returns null for no text', () => {
    expect(firstLine(null)).toBeNull();
    expect(firstLine('   \n ')).toBeNull();
  });

  it('does not cut an emoji in half', () => {
    const text = `${'가'.repeat(MAX_CAPTION - 1)}😀뒤`;
    const line = firstLine(text) ?? '';
    expect(line.length).toBeLessThanOrEqual(MAX_CAPTION);
    expect(line).toBe('가'.repeat(MAX_CAPTION - 1));
  });
});
