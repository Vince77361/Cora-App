import { assertWorkerOnInProduction } from './assert-worker';

describe('assertWorkerOnInProduction', () => {
  it('refuses a production server with the worker turned off', () => {
    expect(() =>
      assertWorkerOnInProduction({
        NODE_ENV: 'production',
        JOBS_WORKER: 'off',
      }),
    ).toThrow(/JOBS_WORKER=off/);
  });

  it('allows production with the worker on or unset, and development with it off', () => {
    expect(() =>
      assertWorkerOnInProduction({ NODE_ENV: 'production', JOBS_WORKER: 'on' }),
    ).not.toThrow();
    expect(() =>
      assertWorkerOnInProduction({ NODE_ENV: 'production' }),
    ).not.toThrow();
    expect(() =>
      assertWorkerOnInProduction({
        NODE_ENV: 'development',
        JOBS_WORKER: 'off',
      }),
    ).not.toThrow();
  });
});
