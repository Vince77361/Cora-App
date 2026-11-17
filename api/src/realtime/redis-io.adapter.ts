import { INestApplicationContext, Logger } from '@nestjs/common';
import { IoAdapter } from '@nestjs/platform-socket.io';
import { createAdapter } from '@socket.io/redis-adapter';
import Redis from 'ioredis';
import type { Server, ServerOptions } from 'socket.io';

const CONNECT_TIMEOUT_MS = 5_000;

// 서버를 여러 대로 늘려도 이벤트가 다른 서버에 붙은 소켓에 닿도록 Redis를 거치게 하는 어댑터(3번 계획에서 들인 Redis).
// keyPrefix는 같은 Redis를 쓰는 다른 서버(개발 서버와 테스트)와 채널이 섞이지 않게 하려는 것이다.
export class RedisIoAdapter extends IoAdapter {
  private readonly redisLogger = new Logger(RedisIoAdapter.name);
  private adapterConstructor?: ReturnType<typeof createAdapter>;
  private readonly clients: Redis[] = [];

  constructor(
    app: INestApplicationContext,
    private readonly redisUrl: string,
    private readonly keyPrefix?: string,
  ) {
    super(app);
  }

  // 서버가 요청을 받기 전에 부른다. 연결하지 못하면 던져서 시작을 멈춘다(조용히 한 대짜리로 도는 것보다 낫다).
  async connectToRedis(): Promise<void> {
    const publisher = new Redis(this.redisUrl);
    const subscriber = publisher.duplicate();
    this.clients.push(publisher, subscriber);
    for (const client of this.clients) {
      // 처리하지 않은 error 이벤트는 프로세스를 죽인다. 오류 이름만 남긴다(주소에 비밀번호가 있을 수 있다).
      client.on('error', (error: Error) => {
        this.redisLogger.warn(`Redis 연결 오류: ${error.name}`);
      });
    }
    try {
      await Promise.all(
        [publisher, subscriber].map((client) => this.untilReady(client)),
      );
    } catch (error) {
      await this.dispose();
      throw error;
    }
    this.adapterConstructor = createAdapter(
      publisher,
      subscriber,
      this.keyPrefix ? { key: this.keyPrefix } : {},
    );
  }

  createIOServer(port: number, options?: ServerOptions): Server {
    const server = super.createIOServer(port, options) as Server;
    if (this.adapterConstructor) server.adapter(this.adapterConstructor);
    return server;
  }

  // 서버가 닫힐 때(Nest가 소켓 서버를 닫은 뒤) Redis 연결도 닫는다.
  async dispose(): Promise<void> {
    await super.dispose();
    await Promise.all(
      this.clients.splice(0).map(async (client) => {
        try {
          await client.quit();
        } catch {
          client.disconnect();
        }
      }),
    );
  }

  private untilReady(client: Redis): Promise<void> {
    if (client.status === 'ready') return Promise.resolve();
    return new Promise((resolve, reject) => {
      const timer = setTimeout(() => {
        reject(
          new Error(
            'Redis에 연결하지 못했어요. REDIS_URL과 Redis 실행 상태를 확인해 주세요.',
          ),
        );
      }, CONNECT_TIMEOUT_MS);
      client.once('ready', () => {
        clearTimeout(timer);
        resolve();
      });
    });
  }
}
