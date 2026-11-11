import { Injectable } from '@nestjs/common';
import { CreatorProfile } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';

// 저장할 값. 선택 항목은 비어 있으면 null이다.
export interface CreatorProfileData {
  displayName: string;
  contentFocus: string | null;
  instagramHandle: string | null;
  photoPath: string | null;
  regionSido: string;
  regionSigungu: string | null;
}

// 크리에이터 조회는 모두 여기를 거친다. 4번 계획이 목록 조건(피하는 업종 등)을 이곳에 끼운다.
@Injectable()
export class CreatorsRepository {
  constructor(private readonly prisma: PrismaService) {}

  // 지워진(deleted_at) 행은 없는 것으로 본다.
  findActiveByUserId(userId: string): Promise<CreatorProfile | null> {
    return this.prisma.creatorProfile.findFirst({
      where: { userId, deletedAt: null },
    });
  }

  // 동시에 두 번 불려도 행이 하나만 생기도록 user_id 유니크로 upsert한다.
  // 지워진 행이 있으면 되살려서 같은 user_id 유니크와 부딪히지 않게 한다.
  upsert(userId: string, data: CreatorProfileData): Promise<CreatorProfile> {
    return this.prisma.creatorProfile.upsert({
      where: { userId },
      create: { userId, ...data },
      update: { ...data, deletedAt: null },
    });
  }
}
