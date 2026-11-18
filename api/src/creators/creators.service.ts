import { Injectable } from '@nestjs/common';
import { CreatorSeries } from '@prisma/client';
import { PROPOSAL_POLICY } from '../common/collaboration-policy';
import { AppError } from '../common/errors/app-error';
import { StoragePort } from '../integrations/storage/storage.port';
import { UploadsService } from '../uploads/uploads.service';
import { UsersService } from '../users/users.service';
import {
  CreatorCardRow,
  CreatorProfileRow,
  CreatorsRepository,
} from './creators.repository';
import { CreatorCardSource } from './dto/creator-card-source';
import { CreateCreatorSeriesDto } from './dto/create-creator-series.dto';
import { CreatorSeriesModel } from './dto/creator-series.model';
import {
  CreatorProfileModel,
  CreatorSummaryModel,
} from './dto/creator-profile.model';
import { UpsertCreatorProfileDto } from './dto/upsert-creator-profile.dto';
import { FeaturedPostsService } from './featured-posts.service';

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

// 비어 있거나 공백뿐이면 null. DTO가 이미 다듬지만, 서비스를 직접 부르는 곳에서도 같은 규칙이 지켜지게 한다.
function blankToNull(value: string | undefined): string | null {
  const text = value?.trim();
  return text ? text : null;
}

function toSeriesModel(row: CreatorSeries): CreatorSeriesModel {
  return { id: row.id, name: row.name, format: row.format, note: row.note };
}

@Injectable()
export class CreatorsService {
  constructor(
    private readonly creators: CreatorsRepository,
    private readonly users: UsersService,
    private readonly uploads: UploadsService,
    private readonly storage: StoragePort,
    private readonly featured: FeaturedPostsService,
  ) {}

  async getMine(userId: string): Promise<CreatorProfileModel> {
    await this.assertCreator(userId);
    const row = await this.creators.findActiveByUserId(userId);
    if (!row) {
      throw new AppError('NOT_FOUND', '크리에이터 프로필이 아직 없어요.');
    }
    return this.toProfile(row);
  }

  async upsertMine(
    userId: string,
    input: UpsertCreatorProfileDto,
  ): Promise<CreatorProfileModel> {
    await this.assertCreator(userId);
    // input.cardHeadline·cardPhotoPath는 받기만 하고 읽지 않는다: 카드 첫 장은 대표 게시물 1번이다(옛 열은 그대로 남는다).
    const photoPath = blankToNull(input.photoPath);
    if (photoPath) {
      this.uploads.assertOwnedPath(userId, photoPath, 'CREATOR_PHOTO');
    }
    const handle = blankToNull(input.instagramHandle);
    // 연결된 계정이 있으면 프로필의 인스타그램 아이디는 항상 그 계정이다. 직접 적은 값(없는 값 포함)은 무시한다.
    // 정산이 읽는 조회수와 가게가 보는 아이디가 어긋나지 않게 하려는 것이다.
    const connected = await this.creators.findConnectedHandle(userId);
    const row = await this.creators.upsert(userId, {
      displayName: input.displayName.trim(),
      contentFocus: blankToNull(input.contentFocus),
      instagramHandle:
        connected ?? (handle?.startsWith('@') ? handle.slice(1) : handle),
      photoPath,
      regionSido: input.regionSido,
      regionSigungu: blankToNull(input.regionSigungu),
    });
    return this.toProfile(row);
  }

  async listMySeries(userId: string): Promise<CreatorSeriesModel[]> {
    await this.assertCreator(userId);
    return (await this.creators.listSeries(userId)).map(toSeriesModel);
  }

  async createMySeries(
    userId: string,
    input: CreateCreatorSeriesDto,
  ): Promise<CreatorSeriesModel> {
    await this.assertCreator(userId);
    const created = await this.creators.createSeries(
      userId,
      {
        name: input.name.trim(),
        format: input.format,
        note: blankToNull(input.note),
      },
      PROPOSAL_POLICY.seriesMax,
    );
    if (!created) {
      throw new AppError(
        'CONFLICT',
        `시리즈는 ${PROPOSAL_POLICY.seriesMax}개까지 만들 수 있어요.`,
      );
    }
    return toSeriesModel(created);
  }

  // 제안(판본)이 시리즈를 사본으로 넣을 때 쓴다. 내 것이 아니거나 없으면 404.
  // uuid 모양이 아닌 값은 DB에 보내지 않고 없는 시리즈로 본다(500이 되지 않게).
  async requireMySeries(
    userId: string,
    seriesId: string,
  ): Promise<CreatorSeriesModel> {
    const row = UUID.test(seriesId)
      ? await this.creators.findSeries(userId, seriesId)
      : null;
    if (!row) throw new AppError('NOT_FOUND', '시리즈를 찾을 수 없어요.');
    return toSeriesModel(row);
  }

  // 인스타그램 연결 모듈이 연결 직후 부른다. 프로필이 아직 없으면 할 일이 없고, 나중에 만들 때 upsertMine이 연결된 아이디를 따른다.
  async overwriteInstagramHandle(
    userId: string,
    handle: string,
  ): Promise<void> {
    await this.creators.updateInstagramHandle(userId, handle);
  }

  // 지원자·오퍼 목록이 붙이는 요약. 프로필이 없거나 지워졌으면 null.
  async getSummary(userId: string): Promise<CreatorSummaryModel | null> {
    const row = await this.creators.findActiveByUserId(userId);
    return row ? this.toSummary(row) : null;
  }

  // getSummary를 여러 명에게 한 번의 읽기로(제안함처럼 줄마다 상대 프로필이 필요한 목록). 프로필이 없거나 지워진 사람은 맵에 없다.
  async getSummaries(
    userIds: string[],
  ): Promise<Map<string, CreatorSummaryModel>> {
    const rows = await this.creators.findActiveByUserIds(userIds);
    return new Map(rows.map((row) => [row.userId, this.toSummary(row)]));
  }

  // 브랜드에게 보여 주는 카드의 재료(하루 추천, 둘러보기). 활동 중인 크리에이터 전부를 최근 가입 순으로 준다.
  // 협업 원칙과 피하는 업종은 여기서 모른다: 읽는 쪽이 VisibilityService로 거른다.
  async listCardSources(): Promise<CreatorCardSource[]> {
    return this.toCardSources(await this.creators.listForCards());
  }

  // 저장된 목록의 크리에이터만 다시 읽는다. 탈퇴했거나 프로필이 지워졌으면 빠진다.
  async findCardSources(ids: string[]): Promise<CreatorCardSource[]> {
    return this.toCardSources(await this.creators.listForCards(ids));
  }

  // 알림이 상대의 이름과 사진 경로를 사본으로 저장할 때 쓴다. 프로필이 없거나 지워졌으면 null.
  async getActor(userId: string): Promise<{
    userId: string;
    name: string;
    photoPath: string | null;
  } | null> {
    const row = await this.creators.findActiveByUserId(userId);
    return row
      ? { userId, name: row.displayName, photoPath: row.photoPath }
      : null;
  }

  // 하트를 보낼 때 남기는 콘텐츠 사본(카드 첫 장의 한 줄과 사진 경로). 카드 첫 장은 대표 게시물 1번이다.
  // 경로는 응답에 내리지 않는 값이라 이 서비스가 따로 꺼내 준다. 프로필이 없으면 null, 대표 게시물이 없으면 두 값 모두 null.
  async getCardCopy(userId: string): Promise<{
    headline: string | null;
    photoPath: string | null;
  } | null> {
    const row = await this.creators.findActiveByUserId(userId);
    if (!row) return null;
    const first = await this.featured.getFirstPostCopy(userId);
    return {
      headline: first?.headline ?? null,
      photoPath: first?.photoPath ?? null,
    };
  }

  // 지원처럼 프로필이 있어야 하는 동작이 앞에서 부른다.
  async requireProfile(userId: string): Promise<CreatorProfileModel> {
    const row = await this.creators.findActiveByUserId(userId);
    if (!row) {
      throw new AppError('CONFLICT', '크리에이터 프로필을 먼저 만들어 주세요.');
    }
    return this.toProfile(row);
  }

  private async assertCreator(userId: string): Promise<void> {
    if ((await this.users.getRole(userId)) !== 'CREATOR') {
      throw new AppError('FORBIDDEN', '크리에이터 계정만 쓸 수 있어요.');
    }
  }

  // 읽기 한 번으로 대표 게시물을 모두 붙인다. 한 줄과 사진은 1번 게시물에서, 게시물이 없으면 프로필 사진으로 대신한다.
  private async toCardSources(
    rows: CreatorCardRow[],
  ): Promise<CreatorCardSource[]> {
    const postsById = await this.featured.listForCreators(
      rows.map((row) => row.userId),
    );
    return rows.map((row) => {
      const posts = postsById.get(row.userId) ?? [];
      return {
        userId: row.userId,
        displayName: row.displayName,
        instagramHandle: row.instagramHandle,
        headline: posts[0]?.caption ?? null,
        photoUrl:
          posts[0]?.photoUrl ??
          (row.photoPath ? this.storage.publicUrl(row.photoPath) : null),
        posts,
        joinedAt: row.joinedAt,
      };
    });
  }

  private toSummary(row: CreatorProfileRow): CreatorSummaryModel {
    return {
      userId: row.userId,
      displayName: row.displayName,
      contentFocus: row.contentFocus,
      photoUrl: row.photoPath ? this.storage.publicUrl(row.photoPath) : null,
      regionSido: row.regionSido,
      regionSigungu: row.regionSigungu,
      instagramConnected: row.instagram !== null,
      followers: row.instagram?.followers ?? null,
    };
  }

  // cardHeadline·cardPhotoUrl은 앱이 대표 게시물 화면으로 바뀌기 전까지 깨지지 않게 1번 게시물에서 채운다.
  private async toProfile(
    row: CreatorProfileRow,
  ): Promise<CreatorProfileModel> {
    const first = (await this.featured.listForCreators([row.userId])).get(
      row.userId,
    )?.[0];
    return {
      ...this.toSummary(row),
      instagramHandle: row.instagramHandle,
      cardHeadline: first?.caption ?? null,
      cardPhotoUrl: first?.photoUrl ?? null,
    };
  }
}
