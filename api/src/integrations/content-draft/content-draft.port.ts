import type { ContentDraftKind } from '@prisma/client';

export type DraftScene = { label: string; text: string; usesPhoto: boolean };

export type DraftContent = {
  bodyLabel: string;
  body: string;
  scenes: DraftScene[];
};

// AI 초안 생성 포트. 구현체는 IntegrationsModule이 CONTENT_DRAFT_ADAPTER 값으로 고른다.
// version은 "다시 만들기" 횟수다. 같은 입력이라도 version이 다르면 다른 초안을 돌려줘야 한다.
export abstract class ContentDraftPort {
  abstract generate(
    input: {
      storeName: string;
      signatureMenu: string | null;
      bestShootingTime: string | null;
      intro: string | null;
    },
    kind: ContentDraftKind,
    version: number,
  ): Promise<DraftContent>;
}
