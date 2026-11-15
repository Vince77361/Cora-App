import { Test } from '@nestjs/testing';
import { PrismaService } from './prisma.service';

describe('PrismaService', () => {
  it('disconnects prisma on application shutdown', async () => {
    const service = new PrismaService();
    const disconnect = jest
      .spyOn(service, '$disconnect')
      .mockResolvedValue(undefined);
    await service.onApplicationShutdown();
    // 종료 신호를 받으면 연결 풀을 닫아 DB 쪽에 끊긴 연결이 남지 않게 한다.
    expect(disconnect).toHaveBeenCalledTimes(1);
  });

  it('does not disconnect before the worker has closed or in-flight requests have finished', async () => {
    const calls: string[] = [];
    // 손으로 쓴 가짜 작업자: 실제 BullMqJobScheduler와 같은 훅(beforeApplicationShutdown)을 쓴다.
    class FakeWorkerHolder {
      async beforeApplicationShutdown(): Promise<void> {
        // 진행 중인 작업을 기다리는 시간을 흉내 낸다.
        await new Promise((resolve) => setTimeout(resolve, 20));
        calls.push('worker closed');
      }
    }
    jest.spyOn(PrismaService.prototype, '$connect').mockResolvedValue();
    jest
      .spyOn(PrismaService.prototype, '$disconnect')
      .mockImplementation(() => {
        calls.push('prisma disconnected');
        return Promise.resolve();
      });
    const moduleRef = await Test.createTestingModule({
      providers: [PrismaService, FakeWorkerHolder],
    }).compile();
    const app = moduleRef.createNestApplication();
    await app.init();
    // app.close()는 HTTP 서버를 닫으며 처리 중 요청을 기다린다(두 훅 사이에서).
    const server = app.getHttpAdapter().getHttpServer() as {
      close: (cb: () => void) => void;
    };
    const originalClose = server.close.bind(server);
    server.close = (cb) => {
      calls.push('http drained');
      originalClose(cb);
    };
    await app.close();
    expect(calls).toEqual([
      'worker closed',
      'http drained',
      'prisma disconnected',
    ]);
    jest.restoreAllMocks();
  });
});
