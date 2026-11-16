import { Injectable } from '@nestjs/common';
import { BrandProfile, IndustryCategory } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';

export interface BrandProfileData {
  name: string;
  tagline: string | null;
  industry: IndustryCategory;
  photoPath: string | null;
}

// 브랜드마다 한 줄이다(user_id 유니크). 지워진(deleted_at) 줄은 없는 것으로 본다.
@Injectable()
export class BrandsRepository {
  constructor(private readonly prisma: PrismaService) {}

  findActiveByUserId(userId: string): Promise<BrandProfile | null> {
    return this.prisma.brandProfile.findFirst({
      where: { userId, deletedAt: null },
    });
  }

  // 여러 브랜드의 프로필을 한 번에. 프로필이 없는 브랜드는 빠진다.
  findActiveByUserIds(userIds: string[]): Promise<BrandProfile[]> {
    if (userIds.length === 0) return Promise.resolve([]);
    return this.prisma.brandProfile.findMany({
      where: { userId: { in: userIds }, deletedAt: null },
    });
  }

  // 같은 브랜드의 요청이 동시에 와도 유니크 때문에 줄은 하나다. 지워진 줄이 있으면 되살려 덮어쓴다.
  upsert(userId: string, data: BrandProfileData): Promise<BrandProfile> {
    const values = { ...data, deletedAt: null };
    return this.prisma.brandProfile.upsert({
      where: { userId },
      create: { userId, ...values },
      update: values,
    });
  }
}
