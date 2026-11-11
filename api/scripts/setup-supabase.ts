import { config } from 'dotenv';
import { assertDevTarget, readDevProjectRef } from '../seed/lib/dev-target';
import { SeedError } from '../seed/lib/supabase-admin';
import { SupabaseStorageAdapter } from '../src/integrations/storage/supabase-storage.adapter';
import { PHOTOS_BUCKET } from '../src/integrations/storage/storage.port';
import {
  MAX_PHOTO_BYTES,
  PHOTO_CONTENT_TYPES,
} from '../src/uploads/photo-rules';

// api/.env를 읽는다. 값은 코드에서 출력하지 않는다.
config({ quiet: true });

// 개발용 원격 Supabase 프로젝트에 Storage 버킷을 만든다. 여러 번 돌려도 안전하다.
async function main(): Promise<void> {
  const { NODE_ENV, SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY } = process.env;
  // 키가 비었는지보다 먼저, 개발 환경·개발 프로젝트가 맞는지부터 확인한다.
  assertDevTarget({
    nodeEnv: NODE_ENV,
    supabaseUrl: SUPABASE_URL,
    devProjectRef: readDevProjectRef(),
  });
  if (!SUPABASE_SERVICE_ROLE_KEY) {
    throw new SeedError('api/.env에 SUPABASE_SERVICE_ROLE_KEY 값이 필요해요.');
  }
  const storage = new SupabaseStorageAdapter(
    SUPABASE_URL,
    SUPABASE_SERVICE_ROLE_KEY,
  );
  // 서명된 업로드 주소는 크기를 강제하지 않으므로, 저장소 쪽에서도 크기와 형식을 막는다.
  // 이미 있는 버킷은 설정만 맞추고, 안의 파일은 건드리지 않는다.
  const result = await storage.ensurePhotosBucket({
    fileSizeLimit: MAX_PHOTO_BYTES,
    allowedMimeTypes: [...PHOTO_CONTENT_TYPES],
  });
  console.log(
    result === 'created'
      ? `Storage 버킷 "${PHOTOS_BUCKET}"를 공개로 만들었어요.`
      : `Storage 버킷 "${PHOTOS_BUCKET}"는 이미 있어서 설정만 맞췄어요.`,
  );
}

main().then(
  () => process.exit(0),
  (error: unknown) => {
    // 사용자에게 보여줘도 되는 메시지만 출력한다. 그 밖의 오류는 종류만 알리고 자세한 값은 숨긴다.
    if (error instanceof SeedError) {
      console.error(error.message);
    } else {
      const name = error instanceof Error ? error.name : 'UnknownError';
      console.error(`Storage 설정이 실패했어요. (${name})`);
    }
    process.exit(1);
  },
);
