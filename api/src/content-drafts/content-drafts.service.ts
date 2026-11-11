import { Injectable } from '@nestjs/common';
import { ContentDraftKind, Store, StoreContentDraft } from '@prisma/client';
import { Clock } from '../common/clock';
import { AppError } from '../common/errors/app-error';
import {
  ContentDraftPort,
  DraftScene,
} from '../integrations/content-draft/content-draft.port';
import { StoresService } from '../stores/stores.service';
import { UsersService } from '../users/users.service';
import {
  ContentDraftsRepository,
  DAILY_REGENERATION_LIMIT,
} from './content-drafts.repository';
import { ContentDraftModel } from './dto/content-draft.model';

// 화면 탭 순서: 카드뉴스, 릴스 대본, 블로그 글.
export const DRAFT_KINDS: ContentDraftKind[] = [
  'CARD_NEWS',
  'REELS_SCRIPT',
  'BLOG',
];

const KST_OFFSET_MS = 9 * 60 * 60 * 1000;

// 하루 횟수는 한국 달력 날짜로 센다. 한국은 일광절약시간이 없어 +9시간이면 된다.
function koreanDate(now: Date): string {
  return new Date(now.getTime() + KST_OFFSET_MS).toISOString().slice(0, 10);
}

@Injectable()
export class ContentDraftsService {
  constructor(
    private readonly drafts: ContentDraftsRepository,
    private readonly users: UsersService,
    private readonly stores: StoresService,
    private readonly port: ContentDraftPort,
    private readonly clock: Clock,
  ) {}

  // 하나도 없으면 세 종류를 만들어 저장한 뒤 돌려준다.
  async list(userId: string): Promise<ContentDraftModel[]> {
    const store = await this.requireStore(userId);
    const rows = await this.ensureDrafts(store);
    const today = koreanDate(this.clock.now());
    return rows.map((row) => this.toModel(row, today));
  }

  // 그 종류만 다시 만든다. 오늘 횟수가 한도면 429.
  async regenerate(
    userId: string,
    kind: ContentDraftKind,
  ): Promise<ContentDraftModel> {
    const store = await this.requireStore(userId);
    const name = this.requireName(store);
    await this.ensureDrafts(store);

    const now = this.clock.now();
    const today = koreanDate(now);
    // 생성(비용이 드는 일)보다 먼저 횟수를 확보한다. 동시에 와도 한도를 넘지 못한다.
    const claim = await this.drafts.claimRegeneration(
      store.id,
      kind,
      today,
      now,
    );
    if (!claim) {
      throw new AppError('RATE_LIMITED', '오늘은 더 만들 수 없어요.');
    }
    const content = await this.port.generate(
      this.inputOf(store, name),
      kind,
      claim.version,
    );
    const row = await this.drafts.saveContent(store.id, kind, content);
    return this.toModel(row, today);
  }

  private async requireStore(userId: string): Promise<Store> {
    if ((await this.users.getRole(userId)) !== 'STORE') {
      throw new AppError('FORBIDDEN', '가게 계정만 쓸 수 있어요.');
    }
    return this.stores.requireMyStore(userId);
  }

  private requireName(store: Store): string {
    if (!store.name) {
      throw new AppError('CONFLICT', '가게 이름을 넣어 주세요.');
    }
    return store.name;
  }

  private inputOf(store: Store, storeName: string) {
    return {
      storeName,
      signatureMenu: store.signatureMenu,
      bestShootingTime: store.bestShootingTime,
      intro: store.intro,
    };
  }

  // 없는 종류만 만든다. 처음 만들 때의 version은 0이다(다시 만들 때마다 1씩 올라간다).
  // 동시 요청이 같은 행을 만들려 해도 createMissing이 건너뛰므로 다시 읽어 돌려준다.
  private async ensureDrafts(store: Store): Promise<StoreContentDraft[]> {
    const existing = await this.drafts.listByStore(store.id);
    const missing = DRAFT_KINDS.filter(
      (kind) => !existing.some((row) => row.kind === kind),
    );
    if (missing.length === 0) return this.inOrder(existing);

    const name = this.requireName(store);
    const created = await Promise.all(
      missing.map(async (kind) => ({
        storeId: store.id,
        kind,
        version: 0,
        ...(await this.port.generate(this.inputOf(store, name), kind, 0)),
      })),
    );
    await this.drafts.createMissing(created);
    return this.inOrder(await this.drafts.listByStore(store.id));
  }

  private inOrder(rows: StoreContentDraft[]): StoreContentDraft[] {
    return [...rows].sort(
      (a, b) => DRAFT_KINDS.indexOf(a.kind) - DRAFT_KINDS.indexOf(b.kind),
    );
  }

  private toModel(row: StoreContentDraft, today: string): ContentDraftModel {
    // 마지막으로 다시 만든 날이 오늘이 아니면 오늘은 0번 만든 것이다.
    const usedToday =
      row.regeneratedOn?.toISOString().slice(0, 10) === today
        ? row.regenerationsOnDay
        : 0;
    return {
      kind: row.kind,
      bodyLabel: row.bodyLabel,
      body: row.body,
      scenes: row.scenes as unknown as DraftScene[],
      regenerationsLeftToday: Math.max(0, DAILY_REGENERATION_LIMIT - usedToday),
    };
  }
}
