import { Injectable } from '@nestjs/common';
import { Campaign } from '@prisma/client';
import { Clock } from '../common/clock';
import { AppError } from '../common/errors/app-error';
import { kstDateString } from '../common/kst';
import { BrandsService } from '../brands/brands.service';
import { UsersService } from '../users/users.service';
import { CampaignChanges, CampaignsRepository } from './campaigns.repository';
import { CampaignModel } from './dto/campaign.model';
import { CreateCampaignDto } from './dto/create-campaign.dto';
import { UpdateCampaignDto } from './dto/update-campaign.dto';

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

// @db.Date 열은 UTC 자정의 Date로 오간다.
function dateOnly(value: string): Date {
  return new Date(`${value}T00:00:00.000Z`);
}

function toModel(row: Campaign): CampaignModel {
  return {
    id: row.id,
    status: row.status,
    headline: row.headline,
    fee: row.fee,
    budget: row.budget,
    productProvided: row.productProvided,
    format: row.format,
    startFrom: row.startFrom.toISOString().slice(0, 10),
    trialDays: row.trialDays,
    mustInclude: row.mustInclude,
    notRequired: row.notRequired,
  };
}

@Injectable()
export class CampaignsService {
  constructor(
    private readonly campaigns: CampaignsRepository,
    private readonly brands: BrandsService,
    private readonly users: UsersService,
    private readonly clock: Clock,
  ) {}

  async getMyActive(userId: string): Promise<CampaignModel> {
    await this.assertBrand(userId);
    const row = await this.campaigns.findActiveByBrand(userId);
    if (!row) throw this.notFound();
    return toModel(row);
  }

  async create(
    userId: string,
    input: CreateCampaignDto,
  ): Promise<CampaignModel> {
    await this.assertBrand(userId);
    await this.brands.requireProfile(userId);
    this.assertBudgetCoversFee(input.fee, input.budget);
    this.assertNotInPast(input.startFrom);
    // 진행 중인 캠페인은 하나뿐이다. 동시에 만드는 경우는 저장소의 유니크 인덱스가 막는다.
    if (await this.campaigns.findActiveByBrand(userId))
      throw this.alreadyActive();
    const created = await this.campaigns.create({
      brandId: userId,
      headline: input.headline.trim(),
      fee: input.fee,
      budget: input.budget,
      productProvided: input.productProvided,
      format: input.format,
      startFrom: dateOnly(input.startFrom),
      trialDays: input.trialDays,
      mustInclude: input.mustInclude.map((line) => line.trim()),
      notRequired: input.notRequired,
    });
    if (!created) throw this.alreadyActive();
    return toModel(created);
  }

  async update(
    userId: string,
    id: string,
    input: UpdateCampaignDto,
  ): Promise<CampaignModel> {
    await this.assertBrand(userId);
    const row = await this.requireOwned(userId, id);
    if (row.status !== 'ACTIVE') {
      throw new AppError('CONFLICT', '이미 마감한 캠페인은 고칠 수 없어요.');
    }
    // 고친 뒤의 값끼리 맞아야 한다. 하나만 보내도 저장된 다른 값과 함께 본다.
    this.assertBudgetCoversFee(
      input.fee ?? row.fee,
      input.budget ?? row.budget,
    );
    // 시작 가능한 날은 바꿀 때만 오늘 이후를 따진다. 이미 지난 날을 그대로 두고 다른 것을 고치는 것은 된다.
    if (
      input.startFrom !== undefined &&
      !sameDate(row.startFrom, input.startFrom)
    ) {
      this.assertNotInPast(input.startFrom);
    }
    const changes: CampaignChanges = {};
    if (input.headline !== undefined) changes.headline = input.headline.trim();
    if (input.fee !== undefined) changes.fee = input.fee;
    if (input.budget !== undefined) changes.budget = input.budget;
    if (input.productProvided !== undefined) {
      changes.productProvided = input.productProvided;
    }
    if (input.format !== undefined) changes.format = input.format;
    if (input.startFrom !== undefined) {
      changes.startFrom = dateOnly(input.startFrom);
    }
    if (input.trialDays !== undefined) changes.trialDays = input.trialDays;
    if (input.mustInclude !== undefined) {
      changes.mustInclude = input.mustInclude.map((line) => line.trim());
    }
    if (input.notRequired !== undefined)
      changes.notRequired = input.notRequired;
    const updated = await this.campaigns.updateIfUnchanged(
      id,
      row.updatedAt,
      changes,
    );
    if (!updated) {
      throw new AppError(
        'CONFLICT',
        '다른 곳에서 먼저 바뀌었어요. 다시 불러와 주세요.',
      );
    }
    return toModel(updated);
  }

  // 이미 마감했으면 그대로 돌려준다(다시 눌러도 같은 결과).
  async close(userId: string, id: string): Promise<CampaignModel> {
    await this.assertBrand(userId);
    await this.requireOwned(userId, id);
    await this.campaigns.close(id);
    return toModel(await this.requireOwned(userId, id));
  }

  // 발견·제안처럼 "내 캠페인"이 있어야 하는 동작이 앞에서 부른다.
  async requireMyActive(userId: string): Promise<Campaign> {
    const row = await this.campaigns.findActiveByBrand(userId);
    if (!row) throw new AppError('CONFLICT', '캠페인을 먼저 만들어 주세요.');
    return row;
  }

  // 진행 중인 캠페인만 찾는다. 마감했거나 없으면 null.
  async findActiveById(id: string): Promise<Campaign | null> {
    return UUID.test(id) ? this.campaigns.findActiveById(id) : null;
  }

  // 남의 캠페인과 없는 캠페인을 구별하지 않는다.
  private async requireOwned(userId: string, id: string): Promise<Campaign> {
    const row = UUID.test(id) ? await this.campaigns.findById(id) : null;
    if (!row || row.brandId !== userId) throw this.notFound();
    return row;
  }

  private assertBudgetCoversFee(fee: number, budget: number): void {
    if (budget < fee) {
      throw new AppError(
        'VALIDATION_FAILED',
        '캠페인 예산은 제작비 이상이어야 해요.',
      );
    }
  }

  // 오늘은 한국 시간 기준이다. 'YYYY-MM-DD' 문자열은 사전순이 날짜순이다.
  private assertNotInPast(startFrom: string): void {
    if (startFrom < kstDateString(this.clock.now())) {
      throw new AppError(
        'VALIDATION_FAILED',
        '시작 가능한 날은 오늘 이후여야 해요.',
      );
    }
  }

  private async assertBrand(userId: string): Promise<void> {
    if ((await this.users.getRole(userId)) !== 'BRAND') {
      throw new AppError('FORBIDDEN', '브랜드 계정만 쓸 수 있어요.');
    }
  }

  private notFound(): AppError {
    return new AppError('NOT_FOUND', '캠페인을 찾을 수 없어요.');
  }

  private alreadyActive(): AppError {
    return new AppError(
      'CONFLICT',
      '진행 중인 캠페인이 이미 있어요. 먼저 마감해 주세요.',
    );
  }
}

function sameDate(stored: Date, value: string): boolean {
  return stored.toISOString().slice(0, 10) === value;
}
