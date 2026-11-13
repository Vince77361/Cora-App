// 사진이 담기는 Storage 버킷. 공개 읽기이고, 쓰기는 서버가 발급한 주소나 서비스 키로만 한다.
export const PHOTOS_BUCKET = 'photos';

// 비공개 버킷. 조회수 캡처처럼 당사자만 봐야 하는 파일을 둔다. 읽기 주소는 서버가 기한을 두고 서명해서만 준다.
export const PRIVATE_BUCKET = 'evidence';

// 파일 저장소 포트. 가짜/실제 전환 대상이 아니라서 _ADAPTER 환경변수가 없고,
// 개발에서도 원격 Supabase의 실제 Storage를 쓴다. 테스트는 FakeStoragePort로 바꿔 끼운다.
export abstract class StoragePort {
  // 클라이언트가 PUT으로 파일을 직접 올릴 수 있는, 기한이 있는 한 번용 주소. 버킷을 주지 않으면 공개 버킷(photos)이다.
  abstract createUploadUrl(path: string, bucket?: string): Promise<string>;

  // 서버가 직접 올린다(시드 이미지 등). 같은 경로가 있으면 덮어쓴다.
  abstract upload(
    path: string,
    bytes: Buffer,
    contentType: string,
  ): Promise<void>;

  // 공개 버킷의 읽기 주소. 네트워크를 쓰지 않는다.
  abstract publicUrl(path: string): string;

  // 비공개 버킷(PRIVATE_BUCKET)의 읽기 주소. ttlSeconds가 지나면 쓸 수 없다. 누구에게 줄지는 부르는 쪽이 정한다.
  abstract signedReadUrl(path: string, ttlSeconds: number): Promise<string>;
}
