import { ConfigModule } from '@nestjs/config';
import { Test } from '@nestjs/testing';
import { AppError } from '../common/errors/app-error';
import { IntegrationsModule } from './integrations.module';
import { FakePushAdapter } from './push/fake-push.adapter';
import { PushPort } from './push/push.port';

async function build(adapter: string) {
  return Test.createTestingModule({
    imports: [
      ConfigModule.forRoot({
        isGlobal: true,
        ignoreEnvFile: true,
        ignoreEnvVars: true,
        load: [() => ({ PUSH_ADAPTER: adapter })],
      }),
      IntegrationsModule,
    ],
  }).compile();
}

describe('IntegrationsModule', () => {
  it('provides FakePushAdapter when PUSH_ADAPTER is fake', async () => {
    const moduleRef = await build('fake');
    expect(moduleRef.get(PushPort)).toBeInstanceOf(FakePushAdapter);
  });

  it('fails module compilation with INTERNAL when PUSH_ADAPTER is real', async () => {
    await expect(build('real')).rejects.toMatchObject({
      code: 'INTERNAL',
    } satisfies Partial<AppError>);
  });
});
