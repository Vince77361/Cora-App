import { SetMetadata } from '@nestjs/common';

export const IS_PUBLIC_KEY = 'isPublic';

// 전역 가드가 기본으로 막으므로, 토큰 없이 열어야 하는 경로에만 명시한다.
export const Public = () => SetMetadata(IS_PUBLIC_KEY, true);
