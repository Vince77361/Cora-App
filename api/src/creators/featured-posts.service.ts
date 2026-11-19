import { Injectable } from '@nestjs/common';
import { AppError } from '../common/errors/app-error';
import { Clock } from '../common/clock';
import {
  PHOTOS_BUCKET,
  StoragePort,
} from '../integrations/storage/storage.port';
import { UploadsService } from '../uploads/uploads.service';
import { UsersService } from '../users/users.service';
import { FeaturedPostModel } from './dto/featured-post.model';
import type { ReplaceFeaturedPostsDto } from './dto/replace-featured-posts.dto';
import {
  FeaturedPostDraft,
  firstLine,
  validateReplacement,
} from './featured-post-rules';
import {
  FeaturedPostPlanItem,
  FeaturedPostRow,
  FeaturedPostsRepository,
} from './featured-posts.repository';

function blankToNull(value: string | null | undefined): string | null {
  const text = value?.trim();
  return text ? text : null;
}

@Injectable()
export class FeaturedPostsService {
  constructor(
    private readonly posts: FeaturedPostsRepository,
    private readonly users: UsersService,
    private readonly uploads: UploadsService,
    private readonly storage: StoragePort,
    private readonly clock: Clock,
  ) {}

  // 인스타그램 글에서 카드에 쓸 한 줄(첫 줄, 40자까지)을 뽑는다. 인스타 모듈이 creators의 내부 규칙 파일을 직접 import하지 않도록 서비스로 내보낸다.
  captionFromInstagram(text: string | null): string | null {
    return firstLine(text);
  }

  async listMine(userId: string): Promise<FeaturedPostModel[]> {
    await this.assertCreator(userId);
    return (await this.posts.listLive(userId)).map((row) => this.toModel(row));
  }

  // 목록 전체를 한 번에 바꾼다(부분 저장 없음). 목록의 차례가 곧 순서이고 항상 1..n이다.
  // `{id}`만 온 항목은 있던 행을 그대로 두고, 빠진 기존 행은 지운다.
  async replaceMine(
    userId: string,
    items: ReplaceFeaturedPostsDto['items'],
  ): Promise<FeaturedPostModel[]> {
    await this.assertCreator(userId);
    const live = new Map(
      (await this.posts.listLive(userId)).map((row) => [row.id, row]),
    );
    const drafts: FeaturedPostDraft[] = [];
    const plan: FeaturedPostPlanItem[] = [];
    const keptIds = new Set<string>();
    for (const item of items) {
      if (item.id) {
        // 남의 게시물 ID는 없는 ID와 같게 보이도록 404로 답한다.
        const row = live.get(item.id);
        if (!row) {
          throw new AppError('NOT_FOUND', '대표 게시물을 찾을 수 없어요.');
        }
        if (keptIds.has(row.id)) {
          throw new AppError(
            'VALIDATION_FAILED',
            '같은 게시물을 두 번 넣을 수 없어요.',
          );
        }
        keptIds.add(row.id);
        drafts.push(toDraft(row));
        plan.push({ keepId: row.id });
        continue;
      }
      if (!item.source || !item.kind || !item.mediaPath) {
        throw new AppError(
          'VALIDATION_FAILED',
          '새 게시물은 출처, 종류, 파일 경로가 필요해요.',
        );
      }
      const draft: FeaturedPostDraft = {
        source: item.source,
        kind: item.kind,
        mediaPath: item.mediaPath,
        thumbnailPath: blankToNull(item.thumbnailPath),
        caption: blankToNull(item.caption),
        instagramMediaId: blankToNull(item.instagramMediaId),
      };
      this.assertOwnedFiles(userId, draft);
      drafts.push(draft);
      plan.push({ draft });
    }
    validateReplacement(drafts);
    await this.assertUploaded(plan);

    const saved = await this.posts.replace(userId, plan, this.clock.now());
    // 확인한 뒤 잠금 안에서 그 행이 없어졌다면 다른 기기가 먼저 바꾼 것이다.
    if (!saved) {
      throw new AppError('NOT_FOUND', '대표 게시물을 찾을 수 없어요.');
    }
    return saved.map((row) => this.toModel(row));
  }

  // 인스타그램에서 이미 대표 게시물로 가져온 원본 게시물 ID들(인스타 가져오기가 "가져옴"을 판단한다).
  async listInstagramMediaIds(userId: string): Promise<Set<string>> {
    const ids = (await this.posts.listLive(userId)).flatMap((row) =>
      row.instagramMediaId ? [row.instagramMediaId] : [],
    );
    return new Set(ids);
  }

  // 카드 목록이 줄마다 읽지 않도록 여러 크리에이터의 대표 게시물을 한 번에 읽는다. 없는 사람은 빈 목록이다.
  async listForCreators(
    userIds: string[],
  ): Promise<Map<string, FeaturedPostModel[]>> {
    const result = new Map<string, FeaturedPostModel[]>(
      userIds.map((id) => [id, []]),
    );
    for (const row of await this.posts.listLiveForCreators(userIds)) {
      result.get(row.creatorId)?.push(this.toModel(row));
    }
    return result;
  }

  // 1번 게시물이 카드 첫 장이다. 하트·대화 카드가 사본으로 남기는 한 줄과 사진 경로. 게시물이 없으면 null.
  async getFirstPostCopy(
    userId: string,
  ): Promise<{ headline: string | null; photoPath: string } | null> {
    const first = (await this.posts.listLive(userId))[0];
    return first
      ? {
          headline: first.caption,
          photoPath: first.thumbnailPath ?? first.mediaPath,
        }
      : null;
  }

  private async assertCreator(userId: string): Promise<void> {
    if ((await this.users.getRole(userId)) !== 'CREATOR') {
      throw new AppError('FORBIDDEN', '크리에이터 계정만 쓸 수 있어요.');
    }
  }

  // 남의 경로나 임의 경로를 끼워 넣지 못하게 한다. 업로드 규칙은 FORBIDDEN을 던지지만 이 요청에서는 잘못된 입력이라 400으로 돌려준다.
  private assertOwnedFiles(userId: string, draft: FeaturedPostDraft): void {
    const wrong = new AppError('VALIDATION_FAILED', '내 사진이 아니에요.');
    const photo = (path: string): void => {
      try {
        this.uploads.assertOwnedPath(userId, path, 'FEATURED_POST');
      } catch {
        throw wrong;
      }
    };
    // 인스타그램 영상도 첫 화면 그림(사진)만 복사해 오므로 모든 게시물의 파일은 내 폴더의 사진 경로다.
    photo(draft.mediaPath);
    if (draft.thumbnailPath) photo(draft.thumbnailPath);
  }

  // 올리지 않은 경로를 막는다(주소만 받고 PUT을 하지 않은 경우). 새 게시물의 파일만 본다.
  private async assertUploaded(plan: FeaturedPostPlanItem[]): Promise<void> {
    // 인스타그램 영상은 파일 경로와 첫 화면 경로가 같으므로 한 번만 확인한다.
    const paths = new Set(
      plan.flatMap((item) =>
        'draft' in item
          ? [item.draft.mediaPath, item.draft.thumbnailPath ?? []].flat()
          : [],
      ),
    );
    const found = await Promise.all(
      [...paths].map((path) => this.storage.exists(path, PHOTOS_BUCKET)),
    );
    if (found.some((exists) => !exists)) {
      throw new AppError('VALIDATION_FAILED', '올리지 않은 사진이에요.');
    }
  }

  private toModel(row: FeaturedPostRow): FeaturedPostModel {
    return {
      id: row.id,
      position: row.position,
      source: row.source,
      kind: row.kind,
      photoUrl: this.storage.publicUrl(row.thumbnailPath ?? row.mediaPath),
      mediaUrl: this.storage.publicUrl(row.mediaPath),
      caption: row.caption,
      instagramMediaId: row.instagramMediaId,
    };
  }
}

function toDraft(row: FeaturedPostRow): FeaturedPostDraft {
  return {
    source: row.source,
    kind: row.kind,
    mediaPath: row.mediaPath,
    thumbnailPath: row.thumbnailPath,
    caption: row.caption,
    instagramMediaId: row.instagramMediaId,
  };
}
