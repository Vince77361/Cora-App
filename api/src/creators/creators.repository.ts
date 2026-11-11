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

// 프로필과 인스타그램 연결(연결이 없거나 지워졌으면 null). 연결 여부와 팔로워 수는 여기서 한 번에 읽는다.
// CreatorsModule이 InstagramModule을 import하면 순환이라, 연결 테이블은 관계로 읽는다.
export type CreatorProfileRow = CreatorProfile & {
  instagram: { followers: number | null } | null;
};

// 크리에이터 조회는 모두 여기를 거친다. 4번 계획이 목록 조건(피하는 업종 등)을 이곳에 끼운다.
@Injectable()
export class CreatorsRepository {
  constructor(private readonly prisma: PrismaService) {}

  // 지워진(deleted_at) 행은 없는 것으로 본다.
  async findActiveByUserId(userId: string): Promise<CreatorProfileRow | null> {
    const row = await this.prisma.creatorProfile.findFirst({
      where: { userId, deletedAt: null },
      include: {
        user: {
          select: {
            instagramConnection: {
              select: { followers: true, deletedAt: true },
            },
          },
        },
      },
    });
    if (!row) return null;
    const { user, ...profile } = row;
    const connection = user.instagramConnection;
    return {
      ...profile,
      instagram:
        connection && !connection.deletedAt
          ? { followers: connection.followers }
          : null,
    };
  }

  // 연결한 계정의 아이디로 프로필의 인스타그램 아이디를 덮어쓴다. 프로필이 아직 없으면 할 일이 없다.
  async updateInstagramHandle(userId: string, handle: string): Promise<void> {
    await this.prisma.creatorProfile.updateMany({
      where: { userId, deletedAt: null },
      data: { instagramHandle: handle },
    });
  }

  // 동시에 두 번 불려도 행이 하나만 생기도록 user_id 유니크로 upsert한다.
  // 지워진 행이 있으면 되살려서 같은 user_id 유니크와 부딪히지 않게 한다.
  // 돌려주는 값에는 연결 정보도 담아, 연결한 크리에이터가 프로필을 고쳐도 연결 표시가 그대로이게 한다.
  async upsert(
    userId: string,
    data: CreatorProfileData,
  ): Promise<CreatorProfileRow> {
    const saved = await this.prisma.creatorProfile.upsert({
      where: { userId },
      create: { userId, ...data },
      update: { ...data, deletedAt: null },
    });
    return (
      (await this.findActiveByUserId(userId)) ?? { ...saved, instagram: null }
    );
  }
}
