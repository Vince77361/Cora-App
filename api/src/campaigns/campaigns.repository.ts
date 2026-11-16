import { Injectable } from '@nestjs/common';
import {
  Campaign,
  ContentFormat,
  NotRequired,
  Prisma,
  ProductTrialDays,
} from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';

export interface NewCampaign {
  brandId: string;
  headline: string;
  fee: number;
  budget: number;
  productProvided: boolean;
  format: ContentFormat;
  startFrom: Date;
  trialDays: ProductTrialDays;
  mustInclude: string[];
  notRequired: NotRequired[];
}

export type CampaignChanges = Partial<Omit<NewCampaign, 'brandId'>>;

// 캠페인 조회는 모두 여기를 거친다. 지워진(deleted_at) 행은 없는 것으로 본다.
@Injectable()
export class CampaignsRepository {
  constructor(private readonly prisma: PrismaService) {}

  findById(id: string): Promise<Campaign | null> {
    return this.prisma.campaign.findFirst({ where: { id, deletedAt: null } });
  }

  findActiveById(id: string): Promise<Campaign | null> {
    return this.prisma.campaign.findFirst({
      where: { id, status: 'ACTIVE', deletedAt: null },
    });
  }

  findActiveByBrand(brandId: string): Promise<Campaign | null> {
    return this.prisma.campaign.findFirst({
      where: { brandId, status: 'ACTIVE', deletedAt: null },
    });
  }

  // 브랜드마다 진행 중인 캠페인은 부분 유니크 인덱스가 하나로 막는다.
  // 읽은 뒤 동시에 만들어 위반(P2002)이 나면 null.
  async create(data: NewCampaign): Promise<Campaign | null> {
    try {
      return await this.prisma.campaign.create({
        data: { ...data, status: 'ACTIVE' },
      });
    } catch (error) {
      if (isUniqueViolation(error)) return null;
      throw error;
    }
  }

  // 읽은 뒤 그 사이에 다른 요청이 고치거나 마감했다면 updatedAt이 달라 아무것도 바꾸지 않고 null이다.
  // 제작비와 예산은 서비스가 읽은 값끼리 검사했으므로, 그 값 위에서만 쓰이게 하려는 것이다.
  async updateIfUnchanged(
    id: string,
    seenUpdatedAt: Date,
    changes: CampaignChanges,
  ): Promise<Campaign | null> {
    const { count } = await this.prisma.campaign.updateMany({
      where: {
        id,
        status: 'ACTIVE',
        deletedAt: null,
        updatedAt: seenUpdatedAt,
      },
      data: changes,
    });
    return count === 0 ? null : this.findById(id);
  }

  // 진행 중일 때만 마감한다. 이미 마감됐으면 아무것도 하지 않는다.
  async close(id: string): Promise<void> {
    await this.prisma.campaign.updateMany({
      where: { id, status: 'ACTIVE', deletedAt: null },
      data: { status: 'CLOSED' },
    });
  }
}

function isUniqueViolation(error: unknown): boolean {
  return (
    error instanceof Prisma.PrismaClientKnownRequestError &&
    error.code === 'P2002'
  );
}
