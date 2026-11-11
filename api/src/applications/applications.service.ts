import { Injectable, Logger } from '@nestjs/common';
import { Store } from '@prisma/client';
import { AppError } from '../common/errors/app-error';
import { CreatorsService } from '../creators/creators.service';
import { PushPort } from '../integrations/push/push.port';
import { StoresService } from '../stores/stores.service';
import { UsersService } from '../users/users.service';
import { ApplicationsRepository } from './applications.repository';
import { ApplicantModel } from './dto/applicant.model';
import { ApplicationModel } from './dto/application.model';

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

// 지역 정렬 묶음: 가게와 구·군이 같으면 0, 시·도만 같으면 1, 그 밖은 2.
function regionTier(
  store: Store,
  creator: { regionSido: string; regionSigungu: string | null },
): number {
  if (!store.regionSido || creator.regionSido !== store.regionSido) return 2;
  return store.regionSigungu !== null &&
    creator.regionSigungu === store.regionSigungu
    ? 0
    : 1;
}

@Injectable()
export class ApplicationsService {
  private readonly logger = new Logger(ApplicationsService.name);

  constructor(
    private readonly applications: ApplicationsRepository,
    private readonly users: UsersService,
    private readonly stores: StoresService,
    private readonly creators: CreatorsService,
    private readonly push: PushPort,
  ) {}

  // 검사 순서: 역할 → 공개된 가게 → 내 가게 아님 → 프로필 → 중복. 화면이 가장 알맞은 안내를 고르게 한다.
  async apply(userId: string, storeId: string): Promise<ApplicationModel> {
    await this.assertRole(userId, 'CREATOR', '크리에이터 계정만 쓸 수 있어요.');
    const store = await this.stores.requirePublished(storeId);
    if (store.ownerId === userId) {
      throw new AppError('CONFLICT', '내 가게에는 지원할 수 없어요.');
    }
    const profile = await this.creators.requireProfile(userId);
    if (await this.applications.findLive(store.id, userId)) {
      throw this.alreadyApplied();
    }
    // 읽은 뒤 동시에 만들어진 경우는 null로 돌아온다.
    const created = await this.applications.create(store.id, userId);
    if (!created) throw this.alreadyApplied();

    // 알림이 실패해도 이미 저장된 지원은 유효하다. 사장님은 지원자 목록에서 볼 수 있다.
    try {
      await this.push.send({
        userId: store.ownerId,
        title: 'Cora',
        body: `${profile.displayName}님이 지원했어요.`,
      });
    } catch (error) {
      this.logger.warn(
        `지원 알림을 보내지 못했어요: ${error instanceof Error ? error.name : 'unknown'}`,
      );
    }
    return {
      id: created.id,
      storeId: created.storeId,
      status: created.status,
    };
  }

  // 지원 중(APPLIED)일 때만 취소한다. 오퍼를 받은 지원은 받은 오퍼에서 거절하게 안내한다.
  async cancel(userId: string, storeId: string): Promise<void> {
    await this.assertRole(userId, 'CREATOR', '크리에이터 계정만 쓸 수 있어요.');
    // uuid 모양이 아닌 값은 DB에 보내지 않고 없는 지원으로 본다(500이 되지 않게).
    const live = UUID.test(storeId)
      ? await this.applications.findLive(storeId, userId)
      : null;
    if (!live) throw this.notFound();
    if (await this.applications.cancelApplied(storeId, userId)) return;
    // 읽은 뒤 상태가 바뀐 경우: 오퍼가 나갔으면 409, 그 사이 취소됐거나 닫혔으면 404.
    const current = await this.applications.findLive(storeId, userId);
    if (current?.status === 'OFFERED') {
      throw new AppError(
        'CONFLICT',
        '오퍼를 받은 뒤에는 받은 오퍼에서 거절해 주세요.',
      );
    }
    throw this.notFound();
  }

  // 내 가게의 지원 중인 크리에이터. 가게와 가까운 지역이 먼저, 같은 묶음에서는 최근 지원 순.
  async listApplicants(userId: string): Promise<ApplicantModel[]> {
    await this.assertRole(userId, 'STORE', '가게 계정만 쓸 수 있어요.');
    const store = await this.stores.requireMyStore(userId);
    const rows = await this.applications.listApplied(store.id);
    const summaries = await Promise.all(
      rows.map((row) => this.creators.getSummary(row.creatorId)),
    );
    const items: { tier: number; item: ApplicantModel }[] = [];
    rows.forEach((row, index) => {
      const creator = summaries[index];
      // 프로필이 지워진 지원자는 보여 줄 것이 없어 뺀다.
      if (!creator) return;
      items.push({
        tier: regionTier(store, creator),
        item: {
          applicationId: row.id,
          creator,
          appliedAt: row.createdAt.toISOString(),
        },
      });
    });
    // Array.prototype.sort는 안정 정렬이라 같은 묶음에서는 최근 지원 순이 그대로 남는다.
    return items.sort((a, b) => a.tier - b.tier).map(({ item }) => item);
  }

  // 오퍼 모듈이 쓴다. 오퍼를 보낼 때 그 크리에이터의 지원 중 지원을 오퍼 받음으로 바꾼다.
  markOffered(storeId: string, creatorId: string): Promise<string | null> {
    return this.applications.markOffered(storeId, creatorId);
  }

  // 오퍼가 거절·만료·취소로 끝나면 연결된 지원을 닫는다. 여러 번 불려도 안전하다.
  closeFor(applicationId: string): Promise<void> {
    return this.applications.closeOffered(applicationId);
  }

  // 오퍼를 만들지 못했을 때(동시 보내기에서 졌거나 저장 실패) markOffered를 되돌려 지원이 고아로 남지 않게 한다.
  // OFFERED일 때만 바꾸므로 여러 번 불려도 안전하다.
  reopen(applicationId: string): Promise<void> {
    return this.applications.reopenOffered(applicationId);
  }

  // 가게 홈의 "새 지원자" 수.
  countNew(storeId: string): Promise<number> {
    return this.applications.countApplied(storeId);
  }

  private async assertRole(
    userId: string,
    role: 'CREATOR' | 'STORE',
    message: string,
  ): Promise<void> {
    if ((await this.users.getRole(userId)) !== role) {
      throw new AppError('FORBIDDEN', message);
    }
  }

  private alreadyApplied(): AppError {
    return new AppError('CONFLICT', '이미 지원한 가게예요.');
  }

  private notFound(): AppError {
    return new AppError('NOT_FOUND', '지원한 내역을 찾을 수 없어요.');
  }
}
