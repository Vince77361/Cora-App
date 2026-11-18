import { Campaign } from '@prisma/client';
import { BrandProfileModel } from '../brands/dto/brand-profile.model';
import { CreatorCardSource } from '../creators/dto/creator-card-source';
import { PrinciplesModel } from '../principles/dto/principles.model';
import { campaignTags, principleTags } from './card-text';
import {
  CampaignCardModel,
  CreatorCardModel,
} from './dto/recommendation-cards.model';
import { CampaignFacts, matchScore } from './match-score';

export function campaignFacts(
  campaign: Campaign,
  brand: BrandProfileModel,
): CampaignFacts {
  return {
    industry: brand.industry,
    fee: campaign.fee,
    notRequired: campaign.notRequired,
    trialDays: campaign.trialDays,
  };
}

// 아래 변환은 응답에 나갈 값을 하나씩 고른다. Prisma 행을 그대로 펼치지 않는다
// (캠페인 예산과 넘김 기록이 응답에 새지 않게 하려는 것이다).
export function toCreatorCard(
  source: CreatorCardSource,
  p: PrinciplesModel,
  facts: CampaignFacts,
): CreatorCardModel {
  return {
    creatorId: source.userId,
    displayName: source.displayName,
    instagramHandle: source.instagramHandle,
    headline: source.headline,
    photoUrl: source.photoUrl,
    posts: source.posts,
    feeBand: p.feeBand,
    tags: principleTags(p),
    reasons: matchScore(p, facts).reasons,
    // 상대의 관심은 미리 알려 주지 않는다. 순서에만 쓰고 늘 false로 내보낸다.
    theyLikedMe: false,
  };
}

export function toCampaignCard(
  campaign: Campaign,
  brand: BrandProfileModel,
  principles: PrinciplesModel | null,
): CampaignCardModel {
  return {
    kind: 'CAMPAIGN',
    campaignId: campaign.id,
    brandName: brand.name,
    brandTagline: brand.tagline,
    photoUrl: brand.photoUrl,
    headline: campaign.headline,
    fee: campaign.fee,
    productProvided: campaign.productProvided,
    tags: campaignTags(campaign.notRequired),
    reasons: principles
      ? matchScore(principles, campaignFacts(campaign, brand)).reasons
      : [],
  };
}
