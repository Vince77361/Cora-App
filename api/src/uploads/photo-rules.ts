// 사진 업로드 규칙. 서버 검증과 버킷 설정(yarn setup:supabase)이 같은 값을 쓰도록 한 곳에 둔다.
export const MAX_PHOTO_BYTES = 5 * 1024 * 1024;

export const EXTENSION_BY_CONTENT_TYPE = {
  'image/jpeg': 'jpg',
  'image/png': 'png',
  'image/heic': 'heic',
} as const;

export const PHOTO_CONTENT_TYPES = Object.keys(
  EXTENSION_BY_CONTENT_TYPE,
) as (keyof typeof EXTENSION_BY_CONTENT_TYPE)[];

// VIEW_EVIDENCE(조회수 캡처)만 비공개 버킷에 올린다. 나머지는 공개 버킷의 사진이다.
export const PHOTO_PURPOSES = [
  'STORE_COVER',
  'CREATOR_PHOTO',
  'VIEW_EVIDENCE',
] as const;
export type PhotoPurpose = (typeof PHOTO_PURPOSES)[number];
