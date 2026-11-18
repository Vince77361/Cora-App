import { InstagramPersonalAccountError, InstagramPort } from './instagram.port';
import { FakeInstagramAdapter } from './fake-instagram.adapter';

// 손으로 쓴 fetcher: 부른 주소를 적어 두고 정한 응답을 돌려준다.
function fakeFetcher(
  respond: (url: string) => Response = () =>
    new Response(Buffer.from('jpeg-bytes'), {
      headers: { 'content-type': 'image/jpeg' },
    }),
) {
  const urls: string[] = [];
  const fetcher = (input: string) => {
    urls.push(input);
    return Promise.resolve(respond(input));
  };
  return { fetcher, urls };
}

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

  it('rejects a personal account code', async () => {
    const adapter: InstagramPort = new FakeInstagramAdapter();
    await expect(
      adapter.completeConnect('c1', 'personal_minji'),
    ).rejects.toBeInstanceOf(InstagramPersonalAccountError);
  });

  it('lists twelve sample posts', async () => {
    const posts = await new FakeInstagramAdapter().listPosts();
    expect(posts).toHaveLength(12);
    expect(posts[0]).toEqual({
      id: 'fake-post-1',
      kind: 'PHOTO',
      caption: '견본 게시물 1',
      thumbnailUrl: 'https://picsum.photos/seed/cora-ig-1/600/600',
      durationSec: null,
      sizeBytes: null,
    });
    expect(posts[1]).toMatchObject({
      id: 'fake-post-2',
      kind: 'VIDEO',
      durationSec: 30,
      sizeBytes: 8 * 1024 * 1024,
    });
    expect(posts.map((p) => p.id)).toEqual(
      Array.from({ length: 12 }, (_, i) => `fake-post-${i + 1}`),
    );
    expect(posts.filter((p) => p.kind === 'VIDEO').map((p) => p.id)).toEqual(
      [2, 4, 6, 8, 10, 12].map((n) => `fake-post-${n}`),
    );
  });

  it('fetches media through the injected fetcher', async () => {
    const { fetcher, urls } = fakeFetcher();
    const adapter = new FakeInstagramAdapter(fetcher);
    const photo = await adapter.fetchMedia(null, 'fake-post-1');
    expect(urls).toEqual(['https://picsum.photos/seed/cora-ig-1/600/600']);
    expect(photo.contentType).toBe('image/jpeg');
    expect(photo.bytes.toString()).toBe('jpeg-bytes');
  });

  it('fails when the fetcher answers with an error status or the post is unknown', async () => {
    const failing = new FakeInstagramAdapter(
      fakeFetcher(() => new Response('no', { status: 500 })).fetcher,
    );
    await expect(failing.fetchMedia(null, 'fake-post-1')).rejects.toThrow();
    await expect(
      new FakeInstagramAdapter(fakeFetcher().fetcher).fetchMedia(null, 'nope'),
    ).rejects.toThrow();
  });
});
