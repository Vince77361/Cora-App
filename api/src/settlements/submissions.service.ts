import { Injectable, Logger } from '@nestjs/common';
import { Collaboration, CollaborationKind } from '@prisma/client';
import { CollaborationStage } from '@prisma/client';
import { submissionDeadlineJobKeys } from '../collaborations/collaboration-jobs';
import { CollaborationsRepository } from '../collaborations/collaborations.repository';
import { Clock } from '../common/clock';
import { AppError } from '../common/errors/app-error';
import { CreatorsService } from '../creators/creators.service';
import { InstagramService } from '../instagram/instagram.service';
import { ViewCountPort } from '../integrations/view-count/view-count.port';
import { JobScheduler } from '../jobs/job-scheduler';
import { NotificationsService } from '../notifications/notifications.service';
import { UsersService } from '../users/users.service';
import { SubmissionResultModel } from './dto/submission-result.model';
import { settleJobKey, SNAPSHOT_DAYS, snapshotJobKey } from './job-keys';
import { isAcceptedLink } from './link-rules';

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const DAY_MS = 24 * 60 * 60 * 1000;

// 링크를 제출할 수 있는 단계. 가게 오퍼는 돈이 보관 중일 때(FUNDED), 브랜드 계약은 검토가 끝난 뒤(APPROVED)다.
export function submittableStage(kind: CollaborationKind): CollaborationStage {
  return kind === 'STORE_OFFER' ? 'FUNDED' : 'APPROVED';
}

@Injectable()
export class SubmissionsService {
  private readonly logger = new Logger(SubmissionsService.name);

  constructor(
    private readonly collaborations: CollaborationsRepository,
    private readonly users: UsersService,
    private readonly creators: CreatorsService,
    private readonly instagram: InstagramService,
    private readonly viewCount: ViewCountPort,
    private readonly jobs: JobScheduler,
    private readonly notifications: NotificationsService,
    private readonly clock: Clock,
  ) {}

  // 검사 순서: 역할 → 내 협업인가(아니면 404) → 제출할 수 있는 단계 → 링크 형식 → 내 계정의 게시물인가.
  async submit(
    userId: string,
    collaborationId: string,
    rawUrl: string,
  ): Promise<SubmissionResultModel> {
    if ((await this.users.getRole(userId)) !== 'CREATOR') {
      throw new AppError('FORBIDDEN', '크리에이터 계정만 쓸 수 있어요.');
    }
    const collaboration = UUID.test(collaborationId)
      ? await this.collaborations.findById(collaborationId)
      : null;
    if (!collaboration || collaboration.creatorId !== userId) {
      throw new AppError('NOT_FOUND', '협업을 찾을 수 없어요.');
    }
    if (collaboration.stage !== submittableStage(collaboration.kind)) {
      throw this.notSubmittable();
    }
    // 브랜드 계약의 제출(APPROVED → PUBLISHED)은 5·6번 계획이 이어서 구현한다. 지금은 이 계획의 가게 오퍼만 받는다.
    if (collaboration.kind !== 'STORE_OFFER') throw this.notSubmittable();

    const url = rawUrl.trim();
    const format = readFormat(collaboration.terms);
    if (!isAcceptedLink(format, url)) {
      throw new AppError('VALIDATION_FAILED', '링크 형식을 확인해 주세요.');
    }
    // 연결된 계정(프로필 칸이 아니다)의 게시물이어야 한다. 쇼츠 같은 곳은 연결이 없어도 된다.
    const connection = await this.instagram.getConnection(userId);
    if (
      !(await this.viewCount.isOwnedBy(url, {
        instagramHandle: connection?.handle ?? null,
      }))
    ) {
      throw new AppError('CONFLICT', '내 계정의 게시물만 제출할 수 있어요.');
    }

    const now = this.clock.now();
    const perView = collaboration.settlementMethod === 'PER_VIEW';
    const countingEndsAt = new Date(now.getTime() + SNAPSHOT_DAYS * DAY_MS);
    // 같은 제출이 동시에 와도 조건부 갱신이 한 번만 통과시킨다.
    const moved = await this.collaborations.advance(
      collaboration.id,
      'FUNDED',
      perView ? 'COUNTING' : 'SETTLED',
      {
        submittedUrl: url,
        submittedAt: now,
        ...(perView ? { countingEndsAt } : {}),
      },
    );
    if (!moved) throw this.notSubmittable();

    if (perView) {
      await this.startCounting(collaboration, now, countingEndsAt);
    }
    await this.cancelDeadlineJobs(collaboration.id);
    await this.notifySubmitted(collaboration);
    return {
      collaborationId: collaboration.id,
      stage: perView ? 'COUNTING' : 'SETTLED',
    };
  }

  // 집계 작업을 올린다: 조회수 8번(0일째는 지금, 이후 하루 간격)과 정산 한 번.
  // 올리지 못하면 단계를 FUNDED로 되돌려 크리에이터가 다시 제출할 수 있게 한다
  // (COUNTING인데 작업이 없으면 아무도 정산하지 않는다).
  private async startCounting(
    collaboration: Collaboration,
    now: Date,
    countingEndsAt: Date,
  ): Promise<void> {
    const keys: string[] = [];
    try {
      for (let day = 0; day <= SNAPSHOT_DAYS; day += 1) {
        const key = snapshotJobKey(collaboration.id, day);
        keys.push(key);
        await this.jobs.schedule(
          'view-snapshot',
          { collaborationId: collaboration.id, dayIndex: day },
          new Date(now.getTime() + day * DAY_MS),
          key,
        );
      }
      const settleKey = settleJobKey(collaboration.id);
      keys.push(settleKey);
      await this.jobs.schedule(
        'settle',
        { collaborationId: collaboration.id },
        countingEndsAt,
        settleKey,
      );
    } catch (error) {
      await this.undoSubmission(collaboration.id, keys);
      throw error;
    }
  }

  private async undoSubmission(
    collaborationId: string,
    keys: string[],
  ): Promise<void> {
    for (const key of keys) {
      try {
        await this.jobs.cancel(key);
      } catch (error) {
        this.logger.warn(
          `제출을 되돌리다 작업을 지우지 못했어요: ${error instanceof Error ? error.name : 'unknown'}`,
        );
      }
    }
    await this.collaborations.advance(collaborationId, 'COUNTING', 'FUNDED', {
      submittedUrl: null,
      submittedAt: null,
      countingEndsAt: null,
    });
  }

  // 제출했으니 미제출 환급과 기한 알림은 필요 없다. 지우지 못해도 처리기가 단계를 보고 아무 일도 하지 않는다.
  private async cancelDeadlineJobs(collaborationId: string): Promise<void> {
    for (const key of submissionDeadlineJobKeys(collaborationId)) {
      try {
        await this.jobs.cancel(key);
      } catch (error) {
        this.logger.warn(
          `제출 기한 작업을 지우지 못했어요: ${error instanceof Error ? error.name : 'unknown'}`,
        );
      }
    }
  }

  // 이미 저장된 제출은 알림 때문에 500이 되면 안 된다(원장 판단 R22).
  private async notifySubmitted(collaboration: Collaboration): Promise<void> {
    try {
      let actor: Awaited<ReturnType<CreatorsService['getActor']>> = null;
      try {
        actor = await this.creators.getActor(collaboration.creatorId);
      } catch {
        actor = null;
      }
      await this.notifications.notify({
        userId: collaboration.commissionerId,
        role: 'STORE',
        kind: 'CONTENT_SUBMITTED',
        actor: actor ?? {
          userId: collaboration.creatorId,
          name: '크리에이터',
          photoPath: null,
        },
        target: { kind: 'COLLABORATION', id: collaboration.id },
        dedupeKey: `submitted:${collaboration.id}`,
      });
    } catch (error) {
      this.logger.warn(
        `콘텐츠 제출 알림을 남기지 못했어요: ${error instanceof Error ? error.name : 'unknown'}`,
      );
    }
  }

  private notSubmittable(): AppError {
    return new AppError(
      'CONFLICT',
      '이미 제출했거나 지금은 제출할 수 없는 협업이에요.',
    );
  }
}

// 협업에 사본으로 남은 수락 당시의 조건에서 형식을 꺼낸다. 없으면 데이터가 어긋난 것이라 던진다.
function readFormat(terms: unknown): Parameters<typeof isAcceptedLink>[0] {
  const format = (terms as Record<string, unknown> | null)?.format;
  if (
    format === 'SHORTS' ||
    format === 'REELS' ||
    format === 'CARD_NEWS' ||
    format === 'BLOG'
  ) {
    return format;
  }
  throw new Error('협업의 조건에 콘텐츠 형식이 없어요.');
}
