import { AppError } from '../common/errors/app-error';

export const MAX_FEATURED_POSTS = 4;
export const MAX_CAPTION = 40;

export type FeaturedPostSourceValue = 'INSTAGRAM' | 'GALLERY';
export type FeaturedPostKindValue = 'PHOTO' | 'VIDEO';

// 저장하려는 게시물 한 개(서버 행이 되기 전의 모양).
export interface FeaturedPostDraft {
  source: FeaturedPostSourceValue;
  kind: FeaturedPostKindValue;
  mediaPath: string;
  thumbnailPath: string | null;
  caption: string | null;
  instagramMediaId: string | null;
}

// 인스타 글의 첫 줄을 40자까지로. 앞쪽 빈 줄은 건너뛰고, 이모지처럼 두 칸을 차지하는 글자를 반으로 자르지 않는다.
export function firstLine(text: string | null): string | null {
  const line = text?.trim().split(/\r?\n/, 1)[0]?.trim();
  if (!line) return null;
  if (line.length <= MAX_CAPTION) return line;
  let cut = line.slice(0, MAX_CAPTION);
  const last = cut.charCodeAt(cut.length - 1);
  // 잘린 끝이 짝을 잃은 앞 서로게이트면 떼어 낸다.
  if (last >= 0xd800 && last <= 0xdbff) cut = cut.slice(0, -1);
  return cut.trimEnd() || null;
}

function invalid(message: string): never {
  throw new AppError('VALIDATION_FAILED', message);
}

// 전체 목록을 저장하기 전에 한 번에 본다. 순서는 목록의 차례이고 서비스가 1..n으로 매긴다.
export function validateReplacement(items: FeaturedPostDraft[]): void {
  if (items.length > MAX_FEATURED_POSTS) {
    invalid(`대표 게시물은 ${MAX_FEATURED_POSTS}개까지예요.`);
  }
  const instagramIds = new Set<string>();
  for (const item of items) {
    const caption = item.caption?.trim() ?? '';
    if (caption.length > MAX_CAPTION) {
      invalid(`한 줄은 ${MAX_CAPTION}자까지 쓸 수 있어요.`);
    }
    if (item.source === 'GALLERY') {
      // 사진첩은 사진만 받는다(영상은 인코딩·저장 비용 때문에 7번 계획에서).
      if (item.kind === 'VIDEO') invalid('사진첩에서는 사진만 올릴 수 있어요.');
      if (!caption) invalid('한 줄 설명을 적어 주세요.');
      if (item.instagramMediaId) {
        invalid('사진첩 게시물에는 인스타그램 게시물 ID가 없어요.');
      }
      continue;
    }
    if (!item.instagramMediaId) {
      invalid('인스타그램 게시물에는 게시물 ID가 필요해요.');
    }
    // 영상 파일은 아직 보관하지 않아(7번 계획에서 새 버킷과 함께) 카드와 목록은 첫 화면 그림 하나로 보여 준다.
    if (item.kind === 'VIDEO' && !item.thumbnailPath) {
      invalid('영상 게시물에는 첫 화면 그림이 필요해요.');
    }
    if (instagramIds.has(item.instagramMediaId)) {
      invalid('같은 인스타그램 게시물을 두 번 넣을 수 없어요.');
    }
    instagramIds.add(item.instagramMediaId);
  }
}
