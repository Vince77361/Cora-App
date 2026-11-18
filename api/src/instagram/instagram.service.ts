import { randomUUID } from 'node:crypto';
import { Injectable, Logger } from '@nestjs/common';
import { isMoneyHeld } from '../collaborations/collaboration-stage';
import { CollaborationsRepository } from '../collaborations/collaborations.repository';
import { Clock } from '../common/clock';
import { SecretBox } from '../common/crypto/secret-box';
import { AppError } from '../common/errors/app-error';
import { firstLine } from '../creators/featured-post-rules';
import { CreatorsService } from '../creators/creators.service';
import { FeaturedPostsService } from '../creators/featured-posts.service';
import {
  InstagramMediaPart,
  InstagramPersonalAccountError,
  InstagramPort,
  InstagramPost,
} from '../integrations/instagram/instagram.port';
import { StoragePort } from '../integrations/storage/storage.port';
import { UsersService } from '../users/users.service';
import { FeaturedPostDraftModel } from './dto/featured-post-draft.model';
import { InstagramConnectionModel } from './dto/instagram-connection.model';
import { InstagramPostModel } from './dto/instagram-post.model';
import { InstagramRepository } from './instagram.repository';

const HANDLE = /^[A-Za-z0-9._]{1,30}$/;

const PERSONAL_ACCOUNT_MESSAGE =
  '개인 계정은 연동할 수 없어요. 인스타그램 앱에서 프로페셔널 계정으로 바꾼 뒤 다시 연동해 주세요.';
// 공통 모델 16장: 60초나 100MB를 넘는 영상은 가져올 수 없다.
const MAX_VIDEO_SECONDS = 60;
const MAX_VIDEO_BYTES = 100 * 1024 * 1024;
const VIDEO_TOO_LONG_MESSAGE = '60초가 넘는 영상은 가져올 수 없어요.';

// 가져온 사진 파일의 확장자. 대표 게시물 저장 규칙(업로드 사진 규칙: jpg·png·heic)과 맞아야 한다.
const IMAGE_EXTENSIONS: Record<string, string> = {
  'image/jpeg': 'jpg',
  'image/png': 'png',
  'image/heic': 'heic',
};

// 크리에이터의 인스타그램 연결. 조회수당 지급을 받는 오퍼는 연결이 있어야 수락할 수 있다(공통 모델 2장).
@Injectable()
export class InstagramService {
  private readonly logger = new Logger(InstagramService.name);

  constructor(
    private readonly connections: InstagramRepository,
    private readonly port: InstagramPort,
    private readonly users: UsersService,
    private readonly creators: CreatorsService,
    private readonly collaborations: CollaborationsRepository,
    private readonly secretBox: SecretBox,
    private readonly clock: Clock,
    private readonly storage: StoragePort,
    private readonly featuredPosts: FeaturedPostsService,
  ) {}

  async begin(userId: string): Promise<{ connectUrl: string }> {
    await this.assertCreator(userId);
    return this.port.beginConnect(userId);
  }

  async complete(
    userId: string,
    code: string,
  ): Promise<InstagramConnectionModel> {
    await this.assertCreator(userId);
    const connected = await this.port
      .completeConnect(userId, code.trim())
      .catch((error: unknown) => {
        if (error instanceof InstagramPersonalAccountError) {
          throw new AppError('CONFLICT', PERSONAL_ACCOUNT_MESSAGE);
        }
        throw error;
      });
    // 인스타그램 아이디는 대소문자를 가리지 않으므로 소문자로 맞춰 같은 계정이 두 번 연결되지 않게 한다.
    const handle = connected.handle.trim().replace(/^@/, '').toLowerCase();
    if (!HANDLE.test(handle)) {
      throw new AppError(
        'VALIDATION_FAILED',
        '인스타그램 아이디는 영문, 숫자, 점, 밑줄만 쓸 수 있어요.',
      );
    }
    // 이미 연결된 크리에이터가 다른 계정으로 바꾸는 것은 해제와 같은 조건을 따른다.
    // 같은 계정으로 다시 연결하는 것(토큰 갱신)은 언제든 된다.
    const mine = await this.connections.findByCreatorId(userId);
    if (mine && mine.handle !== handle) {
      await this.assertNoPerViewInProgress(
        userId,
        '조회수당 지급이 진행 중이라 지금은 다른 계정으로 바꿀 수 없어요.',
      );
    }
    // 먼저 읽어 친절한 오류를 주고, 동시에 연결하는 경우는 저장할 때 유일 제약이 막는다.
    const owner = await this.connections.findByHandle(handle);
    if (owner && owner.creatorId !== userId) throw this.handleTaken();

    const saved = await this.connections.upsert(userId, {
      handle,
      followers: connected.followers,
      tokenEnc: this.sealToken(connected.token),
      refreshedAt: this.clock.now(),
    });
    if (!saved) throw this.handleTaken();

    // 프로필의 인스타그램 아이디는 연결된 계정으로 덮어쓴다(직접 적은 값과 어긋나지 않게).
    await this.creators.overwriteInstagramHandle(userId, handle);
    return { handle: saved.handle, followers: saved.followers };
  }

  // 다른 모듈(오퍼의 수락 조건)이 연결이 있는지 읽을 때 쓴다.
  async getConnection(creatorId: string): Promise<{
    handle: string;
    followers: number | null;
  } | null> {
    const row = await this.connections.findByCreatorId(creatorId);
    return row ? { handle: row.handle, followers: row.followers } : null;
  }

  async getMine(userId: string): Promise<InstagramConnectionModel> {
    await this.assertCreator(userId);
    const row = await this.getConnection(userId);
    if (!row) {
      throw new AppError('NOT_FOUND', '연결된 인스타그램 계정이 없어요.');
    }
    return row;
  }

  // 연동한 계정의 게시물. 고르기 격자가 쓴다.
  async listPosts(userId: string): Promise<InstagramPostModel[]> {
    await this.assertCreator(userId);
    const token = await this.requireToken(userId);
    return (await this.port.listPosts(token)).map((post) => ({ ...post }));
  }

  // 고른 게시물의 파일을 서버 저장소로 복사하고, 대표 게시물로 저장할 수 있는 초안을 돌려준다(저장은 앱이 PUT으로 한다).
  // 목록·중복·길이 검사를 모두 마친 뒤에 복사를 시작해 거절될 요청이 파일을 남기지 않게 한다.
  // 복사 중간에 실패하면 이미 올린 파일은 두고 전체를 실패로 돌려준다(고아 파일은 허용).
  async importPosts(
    userId: string,
    postIds: string[],
  ): Promise<FeaturedPostDraftModel[]> {
    await this.assertCreator(userId);
    const token = await this.requireToken(userId);
    const byId = new Map(
      (await this.port.listPosts(token)).map((post) => [post.id, post]),
    );
    const already = await this.featuredPosts.listInstagramMediaIds(userId);
    const picked = postIds.map((id) => {
      const post = byId.get(id);
      if (!post) {
        throw new AppError('NOT_FOUND', '인스타그램 게시물을 찾을 수 없어요.');
      }
      if (already.has(id)) {
        throw new AppError(
          'CONFLICT',
          '이미 대표 게시물로 가져온 게시물이에요.',
        );
      }
      assertImportable(post);
      return post;
    });
    const drafts: FeaturedPostDraftModel[] = [];
    for (const post of picked) {
      drafts.push(await this.copyPost(userId, token, post));
    }
    return drafts;
  }

  // 조회수당 협업이 진행 중이면 정산이 이 계정의 조회수를 읽어야 하므로 풀 수 없다. 연결이 없으면 이미 풀린 것이다.
  async disconnect(userId: string): Promise<void> {
    await this.assertCreator(userId);
    await this.assertNoPerViewInProgress(
      userId,
      '조회수당 지급이 진행 중이라 지금은 연동을 해제할 수 없어요.',
    );
    await this.connections.remove(userId);
  }

  // 결제를 기다리는 협업도 막는다. 결제가 끝나면 곧 돈이 보관되고, 그때 조회수를 읽을 계정이 있어야 한다.
  private async assertNoPerViewInProgress(
    userId: string,
    message: string,
  ): Promise<void> {
    // 조회수 수당이 있는 협업이면 고정 현금과 함께여도 조회수를 읽을 계정이 필요하다.
    const perView = await this.collaborations.listForCreator(userId, [
      'PER_VIEW',
      'FIXED_AND_PER_VIEW',
    ]);
    if (
      perView.some(
        (c) => c.stage === 'AWAITING_PAYMENT' || isMoneyHeld(c.kind, c.stage),
      )
    ) {
      throw new AppError('CONFLICT', message);
    }
  }

  // 사진 버킷은 5MB·이미지만 받으므로 영상 파일은 복사하지 않는다(영상 보관과 재생은 7번 계획에서 새 버킷과 함께).
  // 영상 게시물은 첫 화면 그림만 복사하고 mediaPath와 thumbnailPath가 그 그림 하나를 가리킨다.
  private async copyPost(
    userId: string,
    token: string | null,
    post: InstagramPost,
  ): Promise<FeaturedPostDraftModel> {
    const isVideo = post.kind === 'VIDEO';
    const file = await this.fetchPart(
      token,
      post,
      isVideo ? 'THUMBNAIL' : 'MEDIA',
    );
    const extension = IMAGE_EXTENSIONS[file.contentType];
    if (!extension) throw unsupportedFile();
    const path = `featured-posts/${userId}/${randomUUID()}.${extension}`;
    await this.storage.upload(path, file.bytes, file.contentType);
    return {
      source: 'INSTAGRAM',
      kind: post.kind,
      mediaPath: path,
      thumbnailPath: isVideo ? path : null,
      caption: firstLine(post.caption),
      instagramMediaId: post.id,
      photoUrl: this.storage.publicUrl(path),
    };
  }

  // 인스타그램에서 파일을 받다 실패한 원인(네트워크 등)은 사용자에게 내부 사정을 보이지 않고 한 문장으로 돌려준다.
  private async fetchPart(
    token: string | null,
    post: InstagramPost,
    part: InstagramMediaPart,
  ): Promise<{ bytes: Buffer; contentType: string }> {
    try {
      return await this.port.fetchMedia(token, post.id, part);
    } catch (error) {
      if (error instanceof AppError) throw error;
      this.logger.warn(
        `인스타그램 파일을 받지 못했어요. (${post.id}, ${part})`,
      );
      throw new AppError(
        'INTERNAL',
        '인스타그램에서 파일을 가져오지 못했어요. 잠시 후 다시 시도해 주세요.',
      );
    }
  }

  // 연결이 없으면 404. 토큰은 봉해 둔 것을 연다(키가 없는 개발 환경에서는 저장하지 않아 null이고 가짜는 그래도 돈다).
  private async requireToken(userId: string): Promise<string | null> {
    const row = await this.connections.findByCreatorId(userId);
    if (!row) {
      throw new AppError('NOT_FOUND', '연결된 인스타그램 계정이 없어요.');
    }
    return row.tokenEnc && this.secretBox.isConfigured()
      ? this.secretBox.open(row.tokenEnc)
      : null;
  }

  // 키가 없는 개발 환경에서도 연결 → 수락 흐름을 쓸 수 있게 토큰을 저장하지 않는다. 운영은 키 없이 시작하지 않는다.
  private sealToken(token: string): string | null {
    if (this.secretBox.isConfigured()) return this.secretBox.seal(token);
    this.logger.warn(
      'PAYOUT_ACCOUNT_KEY가 없어 인스타그램 토큰을 저장하지 않았어요. 개발 환경에서만 허용돼요.',
    );
    return null;
  }

  private handleTaken(): AppError {
    return new AppError(
      'CONFLICT',
      '이미 다른 크리에이터가 연결한 인스타그램 계정이에요.',
    );
  }

  private async assertCreator(userId: string): Promise<void> {
    if ((await this.users.getRole(userId)) !== 'CREATOR') {
      throw new AppError('FORBIDDEN', '크리에이터 계정만 쓸 수 있어요.');
    }
  }
}

function unsupportedFile(): AppError {
  return new AppError(
    'CONFLICT',
    '지원하지 않는 파일 형식이라 가져올 수 없어요.',
  );
}

// 영상 파일은 받지 않으므로 목록이 알려 준 길이·크기로만 막는다. 모르는 값(null)은 막지 않는다.
function assertImportable(post: InstagramPost): void {
  if (post.kind !== 'VIDEO') return;
  if (
    (post.durationSec ?? 0) > MAX_VIDEO_SECONDS ||
    (post.sizeBytes ?? 0) > MAX_VIDEO_BYTES
  ) {
    throw new AppError('CONFLICT', VIDEO_TOO_LONG_MESSAGE);
  }
}
