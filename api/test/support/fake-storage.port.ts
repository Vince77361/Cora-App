import { StoragePort } from '../../src/integrations/storage/storage.port';

// 네트워크 없이 Storage를 흉내 낸다. 주소를 발급한 경로와 올린 파일을 기록해 테스트가 확인한다.
export class FakeStoragePort extends StoragePort {
  readonly uploadUrlPaths: string[] = [];
  readonly uploaded: { path: string; bytes: Buffer; contentType: string }[] =
    [];

  createUploadUrl(path: string): Promise<string> {
    this.uploadUrlPaths.push(path);
    return Promise.resolve(`https://fake-storage.test/upload/${path}?token=t`);
  }

  upload(path: string, bytes: Buffer, contentType: string): Promise<void> {
    this.uploaded.push({ path, bytes, contentType });
    return Promise.resolve();
  }

  publicUrl(path: string): string {
    return `https://fake-storage.test/public/${path}`;
  }
}
