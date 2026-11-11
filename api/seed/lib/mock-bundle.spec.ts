import { existsSync, readFileSync } from 'node:fs';
import { join } from 'node:path';
import { DEV_ACCOUNTS } from './dev-accounts';

const root = join(__dirname, '../mock');
const mock = JSON.parse(readFileSync(join(root, 'mock.json'), 'utf8')) as {
  devAccounts: { phone: string; role: string }[];
  images: { file: string }[];
  [key: string]: unknown;
};

function collectImagePaths(value: unknown, out: string[] = []): string[] {
  if (Array.isArray(value)) value.forEach((v) => collectImagePaths(v, out));
  else if (value && typeof value === 'object') {
    for (const [key, v] of Object.entries(value)) {
      if ((key === 'image' || key === 'avatarImage') && typeof v === 'string') {
        out.push(v);
      } else {
        collectImagePaths(v, out);
      }
    }
  }
  return out;
}

describe('mock bundle', () => {
  it('lists the same dev accounts as the seed script', () => {
    expect(mock.devAccounts).toEqual(
      DEV_ACCOUNTS.map((a) => ({
        phone: a.phone,
        role: a.role,
        persona: expect.any(String) as unknown,
      })),
    );
  });

  it('has every listed image file on disk', () => {
    for (const image of mock.images) {
      expect(existsSync(join(root, image.file))).toBe(true);
    }
  });

  it('only references images that are listed', () => {
    const listed = new Set(mock.images.map((i) => i.file));
    for (const path of collectImagePaths({ ...mock, images: undefined })) {
      expect(listed.has(path)).toBe(true);
    }
  });
});
