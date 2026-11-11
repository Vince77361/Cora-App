export type RedisConnection = {
  host: string;
  port: number;
  username?: string;
  password?: string;
  db?: number;
  tls?: Record<string, never>;
};

// REDIS_URL을 BullMQ 연결 옵션으로 바꾼다. ioredis를 직접 import하지 않으려고 직접 푼다.
export function redisConnectionFromUrl(url: string): RedisConnection {
  let parsed: URL;
  try {
    parsed = new URL(url);
  } catch {
    throw new Error('REDIS_URL이 올바른 주소가 아니에요.');
  }
  if (parsed.protocol !== 'redis:' && parsed.protocol !== 'rediss:') {
    throw new Error('REDIS_URL은 redis:// 또는 rediss://로 시작해야 해요.');
  }
  const db = parsed.pathname.length > 1 ? Number(parsed.pathname.slice(1)) : 0;
  return {
    host: parsed.hostname,
    port: parsed.port ? Number(parsed.port) : 6379,
    ...(parsed.username && { username: decodeURIComponent(parsed.username) }),
    ...(parsed.password && { password: decodeURIComponent(parsed.password) }),
    ...(db > 0 && { db }),
    ...(parsed.protocol === 'rediss:' && { tls: {} }),
  };
}
