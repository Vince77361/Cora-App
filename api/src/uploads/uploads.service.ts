import { randomUUID } from 'node:crypto';
import { Injectable } from '@nestjs/common';
import { UserRole } from '@prisma/client';
import { AppError } from '../common/errors/app-error';
import {
  PRIVATE_BUCKET,
  StoragePort,
} from '../integrations/storage/storage.port';
import { UsersService } from '../users/users.service';
import { UploadRateLimiter } from './upload-rate-limiter';
import { CreatePhotoUploadDto } from './dto/create-photo-upload.dto';
import { PhotoUploadModel } from './dto/photo-upload.model';
import {
  EXTENSION_BY_CONTENT_TYPE,
  MAX_PHOTO_BYTES,
  PhotoPurpose,
} from './photo-rules';

// 목적마다 올릴 수 있는 역할과 저장 폴더가 정해져 있다.
// bucket을 적지 않으면 공개 버킷이다. 조회수 캡처는 비공개 버킷에 두고 읽는 주소를 서버가 서명해서만 준다.
const RULES: Record<
  PhotoPurpose,
  { role: UserRole; dir: string; bucket?: string }
> = {
  STORE_COVER: { role: 'STORE', dir: 'stores' },
  CREATOR_PHOTO: { role: 'CREATOR', dir: 'creators' },
  VIEW_EVIDENCE: { role: 'CREATOR', dir: 'evidence', bucket: PRIVATE_BUCKET },
};

const EXTENSIONS = Object.values(EXTENSION_BY_CONTENT_TYPE).join('|');
// 파일 이름은 서버가 만든 uuid(소문자)와 허용 확장자뿐이다.
const FILE_NAME = new RegExp(
  `^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\\.(${EXTENSIONS})$`,
);

@Injectable()
export class UploadsService {
  constructor(
    private readonly users: UsersService,
    private readonly storage: StoragePort,
    private readonly limiter: UploadRateLimiter,
  ) {}

  async createPhotoUpload(
    userId: string,
    input: CreatePhotoUploadDto,
  ): Promise<PhotoUploadModel> {
    const rule = RULES[input.purpose];
    if ((await this.users.getRole(userId)) !== rule.role) {
      throw new AppError('FORBIDDEN', '이 사진은 올릴 수 없는 계정이에요.');
    }
    // 입력 형식은 DTO가 막지만, 이 서비스를 다른 곳에서 불러도 규칙이 지켜지도록 여기서도 확인한다.
    const extension = (
      EXTENSION_BY_CONTENT_TYPE as Record<string, string | undefined>
    )[input.contentType];
    if (!extension) {
      throw new AppError(
        'VALIDATION_FAILED',
        'JPEG, PNG, HEIC 사진만 올릴 수 있어요.',
      );
    }
    if (
      !Number.isInteger(input.sizeBytes) ||
      input.sizeBytes < 1 ||
      input.sizeBytes > MAX_PHOTO_BYTES
    ) {
      throw new AppError(
        'VALIDATION_FAILED',
        '사진은 5MB 이하만 올릴 수 있어요.',
      );
    }
    // 사용자 입력은 경로에 들어가지 않는다. 사용자 ID는 토큰에서, 파일 이름은 서버가 만든다.
    const path = `${rule.dir}/${userId}/${randomUUID()}.${extension}`;
    // 역할·형식·크기 검증을 통과한 요청만 센다. 발급이 실패하면 되돌린다.
    if (!this.limiter.tryAcquire(userId)) {
      throw new AppError('RATE_LIMITED', '잠시 후 다시 시도해 주세요.');
    }
    try {
      return {
        uploadUrl: await this.storage.createUploadUrl(path, rule.bucket),
        path,
      };
    } catch (error) {
      this.limiter.release(userId);
      throw error;
    }
  }

  // 클라이언트가 보낸 사진 경로를 저장하기 전에 부른다. 남의 사진이나 임의 경로를 못 끼워 넣게 한다.
  assertOwnedPath(userId: string, path: string, purpose: PhotoPurpose): void {
    const prefix = `${RULES[purpose].dir}/${userId}/`;
    if (
      !path.startsWith(prefix) ||
      !FILE_NAME.test(path.slice(prefix.length))
    ) {
      throw new AppError('FORBIDDEN', '내 사진이 아니에요.');
    }
  }
}
