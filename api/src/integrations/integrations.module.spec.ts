import { ConfigModule } from '@nestjs/config';
import { Test } from '@nestjs/testing';
import { AppError } from '../common/errors/app-error';
import { IntegrationsModule } from './integrations.module';
import { FakePushAdapter } from './push/fake-push.adapter';
import { PushPort } from './push/push.port';
import { FakeContentDraftAdapter } from './content-draft/fake-content-draft.adapter';
import { ContentDraftPort } from './content-draft/content-draft.port';
import { FakeStoreLinkAdapter } from './store-link/fake-store-link.adapter';
import { StoreLinkPort } from './store-link/store-link.port';

async function build(overrides: Record<string, string> = {}) {
  return Test.createTestingModule({
    imports: [
      ConfigModule.forRoot({
        isGlobal: true,
        ignoreEnvFile: true,
        ignoreEnvVars: true,
        load: [
          () => ({
            PUSH_ADAPTER: 'fake',
            STORE_LINK_ADAPTER: 'fake',
            CONTENT_DRAFT_ADAPTER: 'fake',
            ...overrides,
          }),
        ],
      }),
      IntegrationsModule,
    ],
  }).compile();
}

describe('IntegrationsModule', () => {
  it('provides FakePushAdapter when PUSH_ADAPTER is fake', async () => {
    const moduleRef = await build();
    expect(moduleRef.get(PushPort)).toBeInstanceOf(FakePushAdapter);
  });

  it('provides the fake link analysis and draft adapters when both are fake', async () => {
    const moduleRef = await build();
    expect(moduleRef.get(StoreLinkPort)).toBeInstanceOf(FakeStoreLinkAdapter);
    expect(moduleRef.get(ContentDraftPort)).toBeInstanceOf(
      FakeContentDraftAdapter,
    );
  });

  it('fails module compilation with INTERNAL when PUSH_ADAPTER is real', async () => {
    await expect(build({ PUSH_ADAPTER: 'real' })).rejects.toMatchObject({
      code: 'INTERNAL',
    } satisfies Partial<AppError>);
  });

  // real 구현은 9번 계획에서 만든다. 그 전에 real을 고르면 조용히 가짜로 돌지 않고 시작을 거부한다.
  it.each(['STORE_LINK_ADAPTER', 'CONTENT_DRAFT_ADAPTER'])(
    'fails module compilation with INTERNAL when %s is real',
    async (key) => {
      await expect(build({ [key]: 'real' })).rejects.toMatchObject({
        code: 'INTERNAL',
      } satisfies Partial<AppError>);
    },
  );
});
