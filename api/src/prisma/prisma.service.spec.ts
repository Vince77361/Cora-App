import { PrismaService } from './prisma.service';

describe('PrismaService', () => {
  it('disconnects prisma on module destroy', async () => {
    const service = new PrismaService();
    const disconnect = jest
      .spyOn(service, '$disconnect')
      .mockResolvedValue(undefined);
    await service.onModuleDestroy();
    // 종료 신호를 받으면 연결 풀을 닫아 DB 쪽에 끊긴 연결이 남지 않게 한다.
    expect(disconnect).toHaveBeenCalledTimes(1);
  });
});
