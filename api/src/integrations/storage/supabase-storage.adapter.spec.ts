import { AppError } from '../../common/errors/app-error';
import { SupabaseStorageAdapter } from './supabase-storage.adapter';

type ExistsResult = { data: boolean | null; error: unknown };

// 네트워크 없이 storage-js의 exists 응답만 흉내 낸다(가짜 storage 클라이언트를 끼운다).
function adapterAnswering(
  answer: () => Promise<ExistsResult>,
): SupabaseStorageAdapter {
  const adapter = new SupabaseStorageAdapter('https://x.test', 'key');
  const fake = {
    storage: { from: () => ({ exists: answer }) },
  };
  (adapter as unknown as { client: unknown }).client = fake;
  return adapter;
}

async function codeOf(promise: Promise<unknown>): Promise<string | undefined> {
  try {
    await promise;
  } catch (e) {
    return (e as AppError).code;
  }
  return undefined;
}

describe('SupabaseStorageAdapter.exists', () => {
  it('answers true when the file is there', async () => {
    const adapter = adapterAnswering(() =>
      Promise.resolve({ data: true, error: null }),
    );
    await expect(adapter.exists('evidence/u/a.jpg', 'evidence')).resolves.toBe(
      true,
    );
  });

  it('answers false, not an error, when storage says the file is missing', async () => {
    const adapter = adapterAnswering(() =>
      Promise.resolve({ data: false, error: { status: 404 } }),
    );
    await expect(adapter.exists('evidence/u/a.jpg', 'evidence')).resolves.toBe(
      false,
    );
  });

  it('turns any other error into INTERNAL', async () => {
    const failing = adapterAnswering(() =>
      Promise.resolve({ data: null, error: { status: 500 } }),
    );
    expect(await codeOf(failing.exists('evidence/u/a.jpg', 'evidence'))).toBe(
      'INTERNAL',
    );
    const thrown = adapterAnswering(() => Promise.reject(new Error('network')));
    expect(await codeOf(thrown.exists('evidence/u/a.jpg', 'evidence'))).toBe(
      'INTERNAL',
    );
  });

  it('does not leak the original error message', async () => {
    const adapter = adapterAnswering(() =>
      Promise.reject(new Error('secret-host.internal refused')),
    );
    await expect(adapter.exists('p', 'evidence')).rejects.toThrow(
      '파일이 있는지 확인하지 못했어요.',
    );
  });
});
