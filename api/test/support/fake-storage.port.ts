import {
  PHOTOS_BUCKET,
  StoragePort,
} from '../../src/integrations/storage/storage.port';

// 네트워크 없이 Storage를 흉내 낸다. 주소를 발급한 경로와 올린 파일을 기록해 테스트가 확인한다.
export class FakeStoragePort extends StoragePort {
  readonly uploadUrlPaths: string[] = [];
  // 업로드 주소를 발급한 버킷(경로와 같은 순서).
  readonly uploadUrlBuckets: string[] = [];
  // 읽기 주소를 서명해 준 경로와 기한(초).
  readonly signedReads: { path: string; ttlSeconds: number }[] = [];
  readonly uploaded: { path: string; bytes: Buffer; contentType: string }[] =
    [];

  createUploadUrl(
    path: string,
    bucket: string = PHOTOS_BUCKET,
  ): Promise<string> {
    this.uploadUrlPaths.push(path);
    this.uploadUrlBuckets.push(bucket);
    return Promise.resolve(
      `https://fake-storage.test/upload/${bucket}/${path}?token=t`,
    );
  }

  upload(path: string, bytes: Buffer, contentType: string): Promise<void> {
    this.uploaded.push({ path, bytes, contentType });
    return Promise.resolve();
  }

  publicUrl(path: string): string {
    return `https://fake-storage.test/public/${path}`;
  }

  signedReadUrl(path: string, ttlSeconds: number): Promise<string> {
    this.signedReads.push({ path, ttlSeconds });
    return Promise.resolve(
      `https://fake-storage.test/signed/${path}?ttl=${ttlSeconds}&token=t`,
    );
  }
}
