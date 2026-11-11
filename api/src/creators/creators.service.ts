import { Injectable } from '@nestjs/common';
import { AppError } from '../common/errors/app-error';
import { StoragePort } from '../integrations/storage/storage.port';
import { UploadsService } from '../uploads/uploads.service';
import { UsersService } from '../users/users.service';
import { CreatorProfileRow, CreatorsRepository } from './creators.repository';
import {
  CreatorProfileModel,
  CreatorSummaryModel,
} from './dto/creator-profile.model';
import { UpsertCreatorProfileDto } from './dto/upsert-creator-profile.dto';

// 비어 있거나 공백뿐이면 null. DTO가 이미 다듬지만, 서비스를 직접 부르는 곳에서도 같은 규칙이 지켜지게 한다.
function blankToNull(value: string | undefined): string | null {
  const text = value?.trim();
  return text ? text : null;
}

@Injectable()
export class CreatorsService {
  constructor(
    private readonly creators: CreatorsRepository,
    private readonly users: UsersService,
    private readonly uploads: UploadsService,
    private readonly storage: StoragePort,
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

  private toProfile(row: CreatorProfileRow): CreatorProfileModel {
    return { ...this.toSummary(row), instagramHandle: row.instagramHandle };
  }
}
