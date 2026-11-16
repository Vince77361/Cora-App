import { Injectable } from '@nestjs/common';
import { CreatorPrinciples, FeeBand } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { UpsertPrinciplesDto } from './dto/upsert-principles.dto';

// 크리에이터마다 한 줄이다(creator_id 유니크). 지워진(deleted_at) 줄은 없는 것으로 본다.
@Injectable()
export class PrinciplesRepository {
  constructor(private readonly prisma: PrismaService) {}

  findByCreatorId(creatorId: string): Promise<CreatorPrinciples | null> {
    return this.prisma.creatorPrinciples.findFirst({
      where: { creatorId, deletedAt: null },
    });
  }

  findByCreatorIds(creatorIds: string[]): Promise<CreatorPrinciples[]> {
    if (creatorIds.length === 0) return Promise.resolve([]);
    return this.prisma.creatorPrinciples.findMany({
      where: { creatorId: { in: creatorIds }, deletedAt: null },
    });
  }

  // 같은 크리에이터의 요청이 동시에 와도 유니크 때문에 줄은 하나다. 지워진 줄이 있으면 되살려 덮어쓴다.
  upsert(
    creatorId: string,
    data: UpsertPrinciplesDto,
  ): Promise<CreatorPrinciples> {
    const values = {
      fields: data.fields,
      blockedIndustries: data.blockedIndustries,
      faceOk: data.faceOk,
      scriptOk: data.scriptOk,
      honestReview: data.honestReview,
      feeBand: data.feeBand,
      trialDays: data.trialDays,
      deletedAt: null,
    };
    return this.prisma.creatorPrinciples.upsert({
      where: { creatorId },
      create: { creatorId, ...values },
      update: values,
    });
  }

  // 원칙이 있을 때만 바꾼다. 없으면 null.
  async updateFeeBand(
    creatorId: string,
    feeBand: FeeBand,
  ): Promise<CreatorPrinciples | null> {
    const { count } = await this.prisma.creatorPrinciples.updateMany({
      where: { creatorId, deletedAt: null },
      data: { feeBand },
    });
    return count === 0 ? null : this.findByCreatorId(creatorId);
  }
}
