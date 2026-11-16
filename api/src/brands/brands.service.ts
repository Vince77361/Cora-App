import { Injectable } from '@nestjs/common';
import { BrandProfile } from '@prisma/client';
import { AppError } from '../common/errors/app-error';
import { StoragePort } from '../integrations/storage/storage.port';
import { UploadsService } from '../uploads/uploads.service';
import { UsersService } from '../users/users.service';
import { BrandsRepository } from './brands.repository';
import { BrandProfileModel } from './dto/brand-profile.model';
import { UpsertBrandProfileDto } from './dto/upsert-brand-profile.dto';

// 비어 있거나 공백뿐이면 null. DTO가 이미 다듬지만, 서비스를 직접 부르는 곳에서도 같은 규칙이 지켜지게 한다.
function blankToNull(value: string | undefined): string | null {
  const text = value?.trim();
  return text ? text : null;
}

@Injectable()
export class BrandsService {
  constructor(
    private readonly brands: BrandsRepository,
    private readonly users: UsersService,
    private readonly uploads: UploadsService,
    private readonly storage: StoragePort,
  ) {}

  async getMine(userId: string): Promise<BrandProfileModel> {
    await this.assertBrand(userId);
    const row = await this.brands.findActiveByUserId(userId);
    if (!row) throw new AppError('NOT_FOUND', '브랜드 프로필이 아직 없어요.');
    return this.toModel(row);
  }

  async upsertMine(
    userId: string,
    input: UpsertBrandProfileDto,
  ): Promise<BrandProfileModel> {
    await this.assertBrand(userId);
    const photoPath = blankToNull(input.photoPath);
    if (photoPath)
      this.uploads.assertOwnedPath(userId, photoPath, 'BRAND_PHOTO');
    const row = await this.brands.upsert(userId, {
      name: input.name.trim(),
      tagline: blankToNull(input.tagline),
      industry: input.industry,
      photoPath,
    });
    return this.toModel(row);
  }

  // 캠페인 만들기처럼 프로필이 있어야 하는 동작이 앞에서 부른다.
  async requireProfile(userId: string): Promise<BrandProfileModel> {
    const row = await this.brands.findActiveByUserId(userId);
    if (!row) {
      throw new AppError('CONFLICT', '브랜드 프로필을 먼저 만들어 주세요.');
    }
    return this.toModel(row);
  }

  // 크리에이터에게 보이는 캠페인 카드가 브랜드 이름·사진·업종을 붙일 때 쓴다. 프로필이 없는 브랜드는 맵에 없다.
  async findProfiles(
    userIds: string[],
  ): Promise<Map<string, BrandProfileModel>> {
    const rows = await this.brands.findActiveByUserIds(userIds);
    return new Map(rows.map((row) => [row.userId, this.toModel(row)]));
  }

  // 알림이 상대의 이름과 사진 경로를 사본으로 저장할 때 쓴다. 프로필이 없으면 null.
  async getActor(userId: string): Promise<{
    userId: string;
    name: string;
    photoPath: string | null;
  } | null> {
    const row = await this.brands.findActiveByUserId(userId);
    return row ? { userId, name: row.name, photoPath: row.photoPath } : null;
  }

  private async assertBrand(userId: string): Promise<void> {
    if ((await this.users.getRole(userId)) !== 'BRAND') {
      throw new AppError('FORBIDDEN', '브랜드 계정만 쓸 수 있어요.');
    }
  }

  private toModel(row: BrandProfile): BrandProfileModel {
    return {
      userId: row.userId,
      name: row.name,
      tagline: row.tagline,
      industry: row.industry,
      photoUrl: row.photoPath ? this.storage.publicUrl(row.photoPath) : null,
    };
  }
}
