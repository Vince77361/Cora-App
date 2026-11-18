import type { PrismaClient } from '@prisma/client';

// 카드 첫 장은 대표 게시물 1번이다. 시험이 크리에이터의 카드(한 줄과 사진)를 정하려고 1번 게시물 하나로 바꾼다.
// caption이 null이면 대표 게시물을 모두 지운다(카드가 없는 크리에이터). 지운 행은 순서를 비우므로 실제로 지운다.
export async function setCardPost(
  prisma: PrismaClient,
  creatorId: string,
  card: { caption: string; mediaPath: string } | null,
): Promise<void> {
  await prisma.featuredPost.deleteMany({ where: { creatorId } });
  if (!card) return;
  await prisma.featuredPost.create({
    data: {
      creatorId,
      position: 1,
      source: 'GALLERY',
      kind: 'PHOTO',
      mediaPath: card.mediaPath,
      caption: card.caption,
    },
  });
}
