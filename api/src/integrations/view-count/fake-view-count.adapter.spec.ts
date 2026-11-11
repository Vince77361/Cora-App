import { FakeClock } from '../../../test/support/fake-clock';
import { FakeViewCountAdapter } from './fake-view-count.adapter';
import { ViewCountPort, ViewCountUnavailableError } from './view-count.port';

const submittedAt = new Date('2026-11-01T00:00:00.000Z');

describe('FakeViewCountAdapter', () => {
  it('reads 600 views per elapsed day by default', async () => {
    const clock = new FakeClock(new Date('2026-11-08T05:00:00.000Z'));
    const adapter = new FakeViewCountAdapter(clock);
    await expect(
      adapter.read({ url: 'https://instagram.com/reel/abc', submittedAt }),
    ).resolves.toBe(4200);
  });

  it('does not go below zero before the first full day', async () => {
    const clock = new FakeClock(new Date('2026-11-01T10:00:00.000Z'));
    const adapter = new FakeViewCountAdapter(clock);
    await expect(
      adapter.read({ url: 'https://instagram.com/reel/abc', submittedAt }),
    ).resolves.toBe(0);
  });

  it('reads the views value from the url when present', async () => {
    const adapter = new FakeViewCountAdapter(new FakeClock());
    await expect(
      adapter.read({
        url: 'https://instagram.com/reel/abc?views=4320',
        submittedAt,
      }),
    ).resolves.toBe(4320);
    await expect(
      adapter.read({
        url: 'https://instagram.com/reel/abc?x=1&views=0',
        submittedAt,
      }),
    ).resolves.toBe(0);
  });

  it('throws ViewCountUnavailableError for an unavailable url', async () => {
    const adapter = new FakeViewCountAdapter(new FakeClock());
    await expect(
      adapter.read({
        url: 'https://instagram.com/reel/unavailable',
        submittedAt,
      }),
    ).rejects.toBeInstanceOf(ViewCountUnavailableError);
  });

  it('treats a url containing notmine as not owned', async () => {
    const adapter: ViewCountPort = new FakeViewCountAdapter(new FakeClock());
    await expect(
      adapter.isOwnedBy('https://instagram.com/reel/notmine', {
        instagramHandle: 'a',
      }),
    ).resolves.toBe(false);
    await expect(
      adapter.isOwnedBy('https://instagram.com/reel/abc', {
        instagramHandle: null,
      }),
    ).resolves.toBe(true);
  });
});
