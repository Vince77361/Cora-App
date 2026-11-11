import { InstagramPort } from './instagram.port';
import { FakeInstagramAdapter } from './fake-instagram.adapter';

describe('FakeInstagramAdapter', () => {
  it('begins connect with the fake deep link', async () => {
    await expect(
      (new FakeInstagramAdapter() as InstagramPort).beginConnect('c1'),
    ).resolves.toEqual({
      connectUrl: 'cora-dev://fake-instagram',
    });
  });

  it('uses the typed handle as the connected instagram account', async () => {
    const adapter: InstagramPort = new FakeInstagramAdapter();
    const result = await adapter.completeConnect('c1', 'cora_creator');
    expect(result.handle).toBe('cora_creator');
    expect(result.followers).toBe(2100);
    await expect(adapter.fetchFollowers(result.token)).resolves.toBe(2100);
  });
});
