import { redisConnectionFromUrl } from './redis-connection';

describe('redisConnectionFromUrl', () => {
  it('parses host, port and database', () => {
    expect(redisConnectionFromUrl('redis://127.0.0.1:6379/2')).toMatchObject({
      host: '127.0.0.1',
      port: 6379,
      db: 2,
    });
  });

  it('defaults the port and passes credentials and tls for rediss', () => {
    const c = redisConnectionFromUrl('rediss://user:pw@redis.internal');
    expect(c).toMatchObject({
      host: 'redis.internal',
      port: 6379,
      username: 'user',
      password: 'pw',
    });
    expect(c.tls).toBeDefined();
  });

  it('rejects a url that is not redis', () => {
    expect(() => redisConnectionFromUrl('http://x')).toThrow(/REDIS_URL/);
  });
});
