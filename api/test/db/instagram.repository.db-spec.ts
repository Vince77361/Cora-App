import { InstagramRepository } from '../../src/instagram/instagram.repository';
import { prisma } from './setup-db';

const A = '66666666-6666-4666-8666-666666666661';
const B = '66666666-6666-4666-8666-666666666662';
const T0 = new Date('2026-12-01T00:00:00.000Z');
const data = (handle: string) => ({
  handle,
  followers: 2100,
  tokenEnc: null,
  refreshedAt: T0,
});

describe('InstagramRepository', () => {
  const repo = new InstagramRepository(prisma as never);

  beforeEach(async () => {
    await prisma.user.createMany({
      data: [
        { id: A, role: 'CREATOR' },
        { id: B, role: 'CREATOR' },
      ],
    });
  });

  // 서비스가 먼저 읽지 않고 곧바로 저장하는 경우(동시에 같은 아이디를 연결)의 유일 제약 위반을 직접 부른다.
  it('returns null when another creator already owns the handle', async () => {
    expect(await repo.upsert(A, data('haru_cafe'))).not.toBeNull();
    expect(await repo.upsert(B, data('haru_cafe'))).toBeNull();
    expect(await prisma.instagramConnection.count()).toBe(1);
    expect(await repo.findByCreatorId(B)).toBeNull();
  });

  it('lets only one of two concurrent connects of the same handle win', async () => {
    const results = await Promise.all([
      repo.upsert(A, data('haru_cafe')),
      repo.upsert(B, data('haru_cafe')),
    ]);
    expect(results.filter((r) => r !== null)).toHaveLength(1);
    expect(await prisma.instagramConnection.count()).toBe(1);
  });

  it('overwrites the same creator row and frees the handle on remove', async () => {
    await repo.upsert(A, data('haru_cafe'));
    expect((await repo.upsert(A, data('haru_two')))?.handle).toBe('haru_two');
    expect(await prisma.instagramConnection.count()).toBe(1);
    await repo.remove(A);
    expect(await repo.upsert(B, data('haru_two'))).not.toBeNull();
  });
});
