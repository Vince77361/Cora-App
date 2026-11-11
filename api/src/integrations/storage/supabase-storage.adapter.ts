import { createClient, SupabaseClient } from '@supabase/supabase-js';
import { AppError } from '../../common/errors/app-error';
import { PHOTOS_BUCKET, StoragePort } from './storage.port';

export interface BucketOptions {
  fileSizeLimit: number;
  allowedMimeTypes: string[];
}

// @supabase/supabase-js를 import하는 곳은 이 파일뿐이다.
export class SupabaseStorageAdapter extends StoragePort {
  private client?: SupabaseClient;

  constructor(
    private readonly supabaseUrl: string | undefined,
    private readonly serviceRoleKey: string | undefined,
  ) {
    super();
  }

  // 앱이 뜰 때가 아니라 처음 쓸 때 만든다. 개발에서 키가 비어도 Storage와 무관한 API는 돌아야 하고,
  // 운영에서 비면 Env 검증이 시작을 거부한다.
  private storage() {
    if (!this.client) {
      if (!this.supabaseUrl || !this.serviceRoleKey) {
        throw new AppError(
          'INTERNAL',
          'Storage 설정(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)이 비어 있어요.',
        );
      }
      // 서버가 서비스 키로 쓰는 클라이언트라 세션을 저장하거나 갱신하지 않는다.
      this.client = createClient(this.supabaseUrl, this.serviceRoleKey, {
        auth: { persistSession: false, autoRefreshToken: false },
      });
    }
    return this.client.storage;
  }

  async createUploadUrl(path: string): Promise<string> {
    const { data, error } = await this.storage()
      .from(PHOTOS_BUCKET)
      .createSignedUploadUrl(path);
    // 원본 오류에는 내부 정보가 있을 수 있어 메시지를 사용자에게 그대로 넘기지 않는다.
    if (error || !data) {
      throw new AppError('INTERNAL', '사진 올릴 주소를 만들지 못했어요.');
    }
    return data.signedUrl;
  }

  async upload(
    path: string,
    bytes: Buffer,
    contentType: string,
  ): Promise<void> {
    const { error } = await this.storage()
      .from(PHOTOS_BUCKET)
      .upload(path, bytes, { contentType, upsert: true });
    if (error) {
      throw new AppError('INTERNAL', '사진을 올리지 못했어요.');
    }
  }

  publicUrl(path: string): string {
    return this.storage().from(PHOTOS_BUCKET).getPublicUrl(path).data.publicUrl;
  }

  // yarn setup:supabase가 쓴다(포트에는 없다). 버킷이 없으면 공개로 만들고, 있으면 설정만 맞춘다.
  // 서명된 업로드 주소는 크기를 강제하지 않아서, 크기·형식 제한을 저장소 쪽에도 둔다.
  async ensurePhotosBucket(
    options: BucketOptions,
  ): Promise<'created' | 'updated'> {
    const storage = this.storage();
    const listed = await storage.listBuckets();
    if (listed.error) {
      throw new AppError('INTERNAL', 'Storage 버킷 목록을 읽지 못했어요.');
    }
    const exists = listed.data.some((b) => b.name === PHOTOS_BUCKET);
    const settings = { public: true, ...options };
    const { error } = exists
      ? await storage.updateBucket(PHOTOS_BUCKET, settings)
      : await storage.createBucket(PHOTOS_BUCKET, settings);
    if (error) {
      throw new AppError('INTERNAL', 'Storage 버킷을 설정하지 못했어요.');
    }
    return exists ? 'updated' : 'created';
  }
}
