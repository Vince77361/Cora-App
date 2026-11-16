import { StoreSummaryModel } from './store-public.model';

// 다른 모듈(추천)이 가게 카드를 만들 때 쓰는 재료. 응답 모델이 아니다.
export interface StoreCardSource {
  ownerId: string;
  summary: StoreSummaryModel;
  intro: string | null;
  recruitLine: string | null;
  publishedAt: Date | null;
}
