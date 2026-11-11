import { assertDevTarget, projectRefOf, readDevProjectRef } from './dev-target';
import { SeedError } from './supabase-admin';

const REF = 'abcdefghijklmnopqrst';
const URL_OK = `https://${REF}.supabase.co`;
const ok = { nodeEnv: 'development', supabaseUrl: URL_OK, devProjectRef: REF };

describe('assertDevTarget', () => {
  it('allows development with the dev project', () => {
    expect(() => assertDevTarget(ok)).not.toThrow();
  });

  it.each([undefined, '', 'test', 'staging', 'production'])(
    'refuses NODE_ENV=%p',
    (nodeEnv) => {
      expect(() => assertDevTarget({ ...ok, nodeEnv })).toThrow(SeedError);
    },
  );

  it('refuses another project and shows only the last four characters', () => {
    const other = 'zzzzzzzzzzzzzzzzwxyz';
    let message = '';
    try {
      assertDevTarget({ ...ok, supabaseUrl: `https://${other}.supabase.co` });
    } catch (e) {
      message = (e as Error).message;
    }
    expect(message).toContain('…wxyz');
    expect(message).not.toContain(other);
    expect(message).not.toContain(REF);
  });

  it('refuses a missing or malformed SUPABASE_URL', () => {
    expect(() => assertDevTarget({ ...ok, supabaseUrl: undefined })).toThrow(
      SeedError,
    );
    expect(() => assertDevTarget({ ...ok, supabaseUrl: 'not a url' })).toThrow(
      SeedError,
    );
  });
});

describe('projectRefOf', () => {
  it('takes the first host label', () => {
    expect(projectRefOf(URL_OK)).toBe(REF);
  });
});

describe('readDevProjectRef', () => {
  it('reads a non-empty ref from seed/dev-project.json', () => {
    expect(readDevProjectRef()).toMatch(/^[a-z0-9]{20}$/);
  });
});
