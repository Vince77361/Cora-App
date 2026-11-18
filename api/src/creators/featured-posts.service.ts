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
import { FeaturedPostDraft, validateReplacement } from './featured-post-rules';
import {
  FeaturedPostPlanItem,
  FeaturedPostRow,
  FeaturedPostsRepository,
} from './featured-posts.repository';

// 인스타그램에서 가져온 영상은 서버가 featured-posts/<내 ID>/ 아래에 복사한다. 사진 확장자는 업로드 규칙이 이미 본다.
const VIDEO_FILE_NAME =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\.(mp4|mov)$/;

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
    if (draft.source === 'INSTAGRAM' && draft.kind === 'VIDEO') {
      const prefix = `featured-posts/${userId}/`;
      if (
        !draft.mediaPath.startsWith(prefix) ||
        !VIDEO_FILE_NAME.test(draft.mediaPath.slice(prefix.length))
      ) {
        throw wrong;
      }
    } else {
      photo(draft.mediaPath);
    }
    if (draft.thumbnailPath) photo(draft.thumbnailPath);
  }

  // 올리지 않은 경로를 막는다(주소만 받고 PUT을 하지 않은 경우). 새 게시물의 파일만 본다.
  private async assertUploaded(plan: FeaturedPostPlanItem[]): Promise<void> {
    const paths = plan.flatMap((item) =>
      'draft' in item
        ? [item.draft.mediaPath, item.draft.thumbnailPath ?? []].flat()
        : [],
    );
    for (const path of paths) {
      if (!(await this.storage.exists(path, PHOTOS_BUCKET))) {
        throw new AppError('VALIDATION_FAILED', '올리지 않은 사진이에요.');
      }
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
