import type {
  BrandUsageRights,
  Campaign,
  ContentFormat,
  RevisionScope,
} from '@prisma/client';

// 브랜드가 관심에 붙인 제안. 서로 관심이 닿으면 캠페인 값 대신 버전 1이 된다.
export interface BrandProposal {
  fee: number;
  productProvided: boolean;
  performance: { ratePer1000: number; cap: number } | null;
}

// 조건 한 판본이 담는 값(저장 열 이름 그대로). 확인한 시각은 판본을 만든 쪽이 정한다.
export interface TermsValues {
  proposedById: string | null;
  title: string;
  fee: number;
  startDate: Date;
  format: ContentFormat;
  pieces: number;
  productProvided: boolean;
  revisionScope: RevisionScope;
  usageRights: BrandUsageRights;
  payoutDays: number;
  perfRatePerThousand: number | null;
  perfCap: number | null;
  brandConfirmedAt: Date | null;
  creatorConfirmedAt: Date | null;
}

// 버전 1의 고정 값(공통 모델 7장 항목 표). 바꾸려면 새 판본을 낸다.
export const DRAFT_PIECES = 1;
export const DRAFT_REVISION_SCOPE: RevisionScope = 'GUIDE_1';
export const DRAFT_USAGE_RIGHTS: BrandUsageRights = 'REPOST_ONLY';
export const DRAFT_PAYOUT_DAYS = 7;

// 서로 관심이 닿을 때 서버가 만드는 조건 버전 1. 순수 함수다.
// 제목: 크리에이터가 "내가 만들고 싶은 콘텐츠 한 줄"을 썼으면 그것, 없으면 캠페인 한 줄.
// 돈과 혜택: 브랜드의 제안이 붙어 있으면 그 값, 없으면 캠페인 값(성과 추가 없음).
// 어느 쪽이든 만든 사람(proposedById)이 없고 양쪽 모두 아직 확인하지 않았다.
// creator.cardHeadline은 버전 1의 제목에 쓰지 않는다(카드 한 줄은 크리에이터가 관심에 붙이는 글이 아니다).
export function draftTerms(
  campaign: Pick<
    Campaign,
    'headline' | 'fee' | 'startFrom' | 'format' | 'productProvided'
  >,
  creator: { cardHeadline: string | null },
  creatorNote: string | null,
  proposal: BrandProposal | null,
): TermsValues {
  const note = creatorNote?.trim() ?? '';
  return {
    proposedById: null,
    title: note !== '' ? note : campaign.headline,
    fee: proposal?.fee ?? campaign.fee,
    startDate: campaign.startFrom,
    format: campaign.format,
    pieces: DRAFT_PIECES,
    productProvided: proposal?.productProvided ?? campaign.productProvided,
    revisionScope: DRAFT_REVISION_SCOPE,
    usageRights: DRAFT_USAGE_RIGHTS,
    payoutDays: DRAFT_PAYOUT_DAYS,
    perfRatePerThousand: proposal?.performance?.ratePer1000 ?? null,
    perfCap: proposal?.performance?.cap ?? null,
    brandConfirmedAt: null,
    creatorConfirmedAt: null,
  };
}
