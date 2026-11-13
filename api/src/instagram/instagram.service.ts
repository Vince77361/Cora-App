import { Injectable, Logger } from '@nestjs/common';
import { isMoneyHeld } from '../collaborations/collaboration-stage';
import { CollaborationsRepository } from '../collaborations/collaborations.repository';
import { Clock } from '../common/clock';
import { SecretBox } from '../common/crypto/secret-box';
import { AppError } from '../common/errors/app-error';
import { CreatorsService } from '../creators/creators.service';
import { InstagramPort } from '../integrations/instagram/instagram.port';
import { UsersService } from '../users/users.service';
import { InstagramConnectionModel } from './dto/instagram-connection.model';
import { InstagramRepository } from './instagram.repository';

const HANDLE = /^[A-Za-z0-9._]{1,30}$/;

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
    const connected = await this.port.completeConnect(userId, code.trim());
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
