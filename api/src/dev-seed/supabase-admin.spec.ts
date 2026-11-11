import { HttpSupabaseAdmin, SeedError } from './supabase-admin';

const URL_BASE = 'https://project.supabase.example';
const CREDS = { email: 'a@example.com', password: 'pw-for-test' };
const ID = '11111111-1111-4111-8111-111111111111';

interface Call {
  url: string;
  method?: string;
  headers: Record<string, string>;
  body?: string;
}

// 손으로 쓴 fetch 가짜. 준비해 둔 응답을 순서대로 돌려주고 받은 요청을 기록한다.
function fakeFetch(responses: Response[]) {
  const calls: Call[] = [];
  const fn = (input: string, init?: RequestInit) => {
    calls.push({
      url: input,
      method: init?.method,
      headers: init?.headers as Record<string, string>,
      body: init?.body as string | undefined,
    });
    const next = responses.shift();
    if (!next) throw new Error('unexpected request');
    return Promise.resolve(next);
  };
  return { fn, calls };
}

const json = (status: number, body: unknown) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json' },
  });

describe('HttpSupabaseAdmin', () => {
  it('creates a confirmed user and returns its id', async () => {
    const { fn, calls } = fakeFetch([json(200, { id: ID })]);
    const admin = new HttpSupabaseAdmin(URL_BASE, 'a.b.c', fn);

    await expect(admin.ensureUser(CREDS)).resolves.toEqual({
      id: ID,
      created: true,
    });
    expect(calls[0].url).toBe(`${URL_BASE}/auth/v1/admin/users`);
    expect(calls[0].method).toBe('POST');
    expect(JSON.parse(calls[0].body ?? '{}')).toEqual({
      ...CREDS,
      email_confirm: true,
    });
  });

  it('finds the id of an existing user when the email already exists', async () => {
    const { fn, calls } = fakeFetch([
      json(422, { error_code: 'email_exists' }),
      json(200, {
        users: [
          {
            id: '22222222-2222-4222-8222-222222222222',
            email: 'x@example.com',
          },
          { id: ID, email: CREDS.email },
        ],
      }),
    ]);
    const admin = new HttpSupabaseAdmin(URL_BASE, 'a.b.c', fn);

    await expect(admin.ensureUser(CREDS)).resolves.toEqual({
      id: ID,
      created: false,
    });
    expect(calls[1].method).toBe('GET');
  });

  it('sends only the apikey header for an sb_secret_ key', async () => {
    const { fn, calls } = fakeFetch([json(200, { id: ID })]);
    await new HttpSupabaseAdmin(URL_BASE, 'sb_secret_test', fn).ensureUser(
      CREDS,
    );

    expect(calls[0].headers.apikey).toBe('sb_secret_test');
    expect(calls[0].headers.Authorization).toBeUndefined();
  });

  it('sends apikey and Authorization for a JWT key', async () => {
    const { fn, calls } = fakeFetch([json(200, { id: ID })]);
    await new HttpSupabaseAdmin(URL_BASE, 'a.b.c', fn).ensureUser(CREDS);

    expect(calls[0].headers.apikey).toBe('a.b.c');
    expect(calls[0].headers.Authorization).toBe('Bearer a.b.c');
  });

  it('explains that the service role key may belong to another project on 401', async () => {
    const { fn } = fakeFetch([json(401, { msg: 'Invalid API key' })]);
    const admin = new HttpSupabaseAdmin(URL_BASE, 'a.b.c', fn);

    const error = await admin.ensureUser(CREDS).catch((e: unknown) => e);
    expect(error).toBeInstanceOf(SeedError);
    expect((error as SeedError).message).toContain(
      'SUPABASE_SERVICE_ROLE_KEY가 이 프로젝트의 키인지 확인하세요',
    );
  });

  it('never puts the key, email or password into an error message', async () => {
    const { fn } = fakeFetch([json(500, { msg: CREDS.email })]);
    const admin = new HttpSupabaseAdmin(URL_BASE, 'secret-key-value', fn);

    const error = (await admin
      .ensureUser(CREDS)
      .catch((e: unknown) => e)) as Error;
    expect(error.message).not.toContain('secret-key-value');
    expect(error.message).not.toContain(CREDS.email);
    expect(error.message).not.toContain(CREDS.password);
  });

  it('reports a connection problem without echoing the cause', async () => {
    const fn = (() =>
      Promise.reject(new Error(URL_BASE))) as unknown as typeof fetch;
    const admin = new HttpSupabaseAdmin(URL_BASE, 'a.b.c', fn);

    await expect(admin.ensureUser(CREDS)).rejects.toThrow(/연결하지 못했어요/);
    await expect(admin.ensureUser(CREDS)).rejects.not.toThrow(URL_BASE);
  });
});
