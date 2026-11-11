import { ConfigModule } from '@nestjs/config';
import { Test } from '@nestjs/testing';
import { FakeClock } from '../../test/support/fake-clock';
import { Clock, SystemClock } from './clock';
import { CommonModule } from './common.module';

describe('Clock', () => {
  it('provides SystemClock globally through CommonModule', async () => {
    const moduleRef = await Test.createTestingModule({
      imports: [CommonModule],
    }).compile();
    expect(moduleRef.get(Clock)).toBeInstanceOf(SystemClock);
  });

  it('SystemClock returns the current time', () => {
    const before = Date.now();
    const now = new SystemClock().now().getTime();
    expect(now).toBeGreaterThanOrEqual(before);
    expect(now).toBeLessThanOrEqual(Date.now());
  });

  it('FakeClock can be overridden in place of Clock', async () => {
    const fake = new FakeClock(new Date('2026-01-01T00:00:00Z'));
    const moduleRef = await Test.createTestingModule({
      imports: [CommonModule],
    })
      .overrideProvider(Clock)
      .useValue(fake)
      .compile();
    expect(moduleRef.get(Clock).now().toISOString()).toBe(
      '2026-01-01T00:00:00.000Z',
    );
  });

  it('FakeClock set and advance move the time', () => {
    const clock = new FakeClock(new Date('2026-01-01T00:00:00Z'));
    clock.advance(60_000);
    expect(clock.now().toISOString()).toBe('2026-01-01T00:01:00.000Z');
    clock.set(new Date('2026-02-01T00:00:00Z'));
    expect(clock.now().toISOString()).toBe('2026-02-01T00:00:00.000Z');
  });

  it('FakeClock does not let a caller mutate its time through the returned date', () => {
    const clock = new FakeClock(new Date('2026-01-01T00:00:00Z'));
    clock.now().setFullYear(1999);
    expect(clock.now().getUTCFullYear()).toBe(2026);
  });

  describe('FAKE_CLOCK_OFFSET_DAYS', () => {
    const DAY = 24 * 60 * 60 * 1000;

    async function clockFor(config: Record<string, unknown>): Promise<Clock> {
      const moduleRef = await Test.createTestingModule({
        imports: [
          ConfigModule.forRoot({
            isGlobal: true,
            ignoreEnvFile: true,
            ignoreEnvVars: true,
            load: [() => config],
          }),
          CommonModule,
        ],
      }).compile();
      return moduleRef.get(Clock);
    }

    it('adds the offset days to the system time in development', async () => {
      const clock = await clockFor({
        NODE_ENV: 'development',
        FAKE_CLOCK_OFFSET_DAYS: 3,
      });
      const diff = clock.now().getTime() - Date.now();
      expect(diff).toBeGreaterThan(3 * DAY - 5000);
      expect(diff).toBeLessThan(3 * DAY + 5000);
    });

    it.each(['test', 'production'])(
      'ignores the offset when NODE_ENV is %s',
      async (nodeEnv) => {
        const clock = await clockFor({
          NODE_ENV: nodeEnv,
          FAKE_CLOCK_OFFSET_DAYS: 3,
        });
        expect(Math.abs(clock.now().getTime() - Date.now())).toBeLessThan(5000);
      },
    );

    it('does not move the clock when the offset is 0 or unset', async () => {
      const clock = await clockFor({ NODE_ENV: 'development' });
      expect(Math.abs(clock.now().getTime() - Date.now())).toBeLessThan(5000);
    });
  });
});
