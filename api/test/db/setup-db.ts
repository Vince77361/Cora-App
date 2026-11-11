import { PrismaClient } from '@prisma/client';
import { truncateTestDb } from '../helpers/truncate-test-db';

// db-spec마다 같은 클라이언트를 쓰도록 한 곳에서 만든다.
export const prisma = new PrismaClient();

// 테스트끼리 데이터가 섞이지 않게 매 테스트 전에 비운다(가드는 truncateTestDb 안에 있다).
beforeEach(async () => {
  await truncateTestDb(prisma);
});

afterAll(async () => {
  await prisma.$disconnect();
});
