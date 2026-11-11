import { Injectable } from '@nestjs/common';
import { ContentDraftKind, StoreContentDraft } from '@prisma/client';
import { DraftContent } from '../integrations/content-draft/content-draft.port';
import { PrismaService } from '../prisma/prisma.service';

// 하루에 한 종류를 다시 만들 수 있는 최대 횟수. 실제 AI를 붙였을 때의 비용 한도다.
export const DAILY_REGENERATION_LIMIT = 10;

export interface NewDraft extends DraftContent {
  storeId: string;
  kind: ContentDraftKind;
  version: number;
}

@Injectable()
export class ContentDraftsRepository {
  constructor(private readonly prisma: PrismaService) {}

  listByStore(storeId: string): Promise<StoreContentDraft[]> {
    return this.prisma.storeContentDraft.findMany({
      where: { storeId, deletedAt: null },
    });
  }

  // 같은 가게의 첫 읽기가 동시에 와도 (store_id, kind) 유니크에 걸리지 않게 이미 있는 것은 건너뛴다.
  async createMissing(drafts: NewDraft[]): Promise<void> {
    await this.prisma.storeContentDraft.createMany({
      data: drafts.map((draft) => ({
        ...draft,
        scenes: draft.scenes,
      })),
      skipDuplicates: true,
    });
  }

  // 다시 만들기 횟수를 한 문장으로 올린다. 오늘 이미 한도에 닿았으면 아무 행도 바뀌지 않아 null이다.
  // 확인과 갱신을 나누면 동시 요청이 한도를 넘기므로 조건을 WHERE에 둔다.
  // today는 한국 날짜(YYYY-MM-DD)다. 다른 날이면 횟수를 1로 되돌리고 시작한다.
  async claimRegeneration(
    storeId: string,
    kind: ContentDraftKind,
    today: string,
    now: Date,
  ): Promise<{ version: number; regenerationsOnDay: number } | null> {
    const rows = await this.prisma.$queryRaw<
      { version: number; regenerations_on_day: number }[]
    >`
      UPDATE "store_content_drafts"
      SET "regenerations_on_day" = CASE
            WHEN "regenerated_on" = ${today}::date THEN "regenerations_on_day" + 1
            ELSE 1
          END,
          "regenerated_on" = ${today}::date,
          "version" = "version" + 1,
          "updated_at" = ${now}::timestamptz
      WHERE "store_id" = ${storeId}::uuid
        AND "kind" = ${kind}::"content_draft_kind"
        AND "deleted_at" IS NULL
        AND ("regenerated_on" IS DISTINCT FROM ${today}::date
             OR "regenerations_on_day" < ${DAILY_REGENERATION_LIMIT})
      RETURNING "version", "regenerations_on_day"`;
    const row = rows[0];
    return row
      ? { version: row.version, regenerationsOnDay: row.regenerations_on_day }
      : null;
  }

  saveContent(
    storeId: string,
    kind: ContentDraftKind,
    content: DraftContent,
  ): Promise<StoreContentDraft> {
    return this.prisma.storeContentDraft.update({
      where: { storeId_kind: { storeId, kind } },
      data: {
        bodyLabel: content.bodyLabel,
        body: content.body,
        scenes: content.scenes,
      },
    });
  }
}
