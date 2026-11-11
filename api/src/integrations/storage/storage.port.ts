// 사진이 담기는 Storage 버킷. 공개 읽기이고, 쓰기는 서버가 발급한 주소나 서비스 키로만 한다.
export const PHOTOS_BUCKET = 'photos';

// 파일 저장소 포트. 가짜/실제 전환 대상이 아니라서 _ADAPTER 환경변수가 없고,
// 개발에서도 원격 Supabase의 실제 Storage를 쓴다. 테스트는 FakeStoragePort로 바꿔 끼운다.
export abstract class StoragePort {
  // 클라이언트가 PUT으로 파일을 직접 올릴 수 있는, 기한이 있는 한 번용 주소.
  abstract createUploadUrl(path: string): Promise<string>;

  // 서버가 직접 올린다(시드 이미지 등). 같은 경로가 있으면 덮어쓴다.
  abstract upload(
    path: string,
    bytes: Buffer,
    contentType: string,
  ): Promise<void>;

  // 공개 버킷의 읽기 주소. 네트워크를 쓰지 않는다.
  abstract publicUrl(path: string): string;
}
