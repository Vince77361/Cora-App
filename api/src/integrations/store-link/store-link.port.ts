import type { IndustryCategory, SourceLinkKind } from '@prisma/client';

// 종류 타입의 원본은 Prisma가 만든 enum 타입이다. 따로 문자열 유니온을 두면 스키마와 어긋날 수 있다.
export type SourceLinkInput = { kind: SourceLinkKind; url: string };

export type StoreLinkResult = {
  store: {
    name: string | null;
    category: string | null;
    neighborhood: string | null;
    signatureMenu: string | null;
    hours: string | null;
    seats: string | null;
    bestShootingTime: string | null;
    intro: string | null;
    industry: IndustryCategory | null;
    regionSido: string | null;
    regionSigungu: string | null;
  };
  coverPhoto: { bytes: Buffer; contentType: string } | null;
  linkSummaries: { kind: SourceLinkKind; summary: string }[];
};

// 링크를 읽지 못했을 때 던진다. 호출한 쪽(가게 서비스)이 잡아서 사용자용 오류로 바꾼다.
export class StoreLinkAnalysisError extends Error {
  constructor(message = '링크를 분석하지 못했어요.') {
    super(message);
    this.name = 'StoreLinkAnalysisError';
  }
}

// 가게 링크 분석 포트. 구현체는 IntegrationsModule이 STORE_LINK_ADAPTER 값으로 고른다.
export abstract class StoreLinkPort {
  abstract analyze(links: SourceLinkInput[]): Promise<StoreLinkResult>;
}
