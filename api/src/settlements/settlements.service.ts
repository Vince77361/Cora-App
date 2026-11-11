import { Injectable, Logger } from '@nestjs/common';
import { Collaboration } from '@prisma/client';
import { CollaborationsRepository } from '../collaborations/collaborations.repository';
import { Clock } from '../common/clock';
import { InstagramService } from '../instagram/instagram.service';
import { OperatorAlertPort } from '../integrations/operator-alert/operator-alert.port';
import {
  ViewCountPort,
  ViewCountUnavailableError,
} from '../integrations/view-count/view-count.port';
import { JobScheduler } from '../jobs/job-scheduler';
import { NotificationsService } from '../notifications/notifications.service';
import {
  HALT_AFTER_UNREADABLE_DAYS,
  settleJobKey,
  SNAPSHOT_DAYS,
  snapshotJobKey,
  VIEW_COUNT_HALT_REASON,
} from './job-keys';
import { SettlementsRepository } from './settlements.repository';

@Injectable()
export class SettlementsService {
  private readonly logger = new Logger(SettlementsService.name);

  constructor(
    private readonly repository: SettlementsRepository,
    private readonly collaborations: CollaborationsRepository,
    private readonly instagram: InstagramService,
    private readonly viewCount: ViewCountPort,
    private readonly jobs: JobScheduler,
    private readonly operatorAlert: OperatorAlertPort,
    private readonly notifications: NotificationsService,
    private readonly clock: Clock,
  ) {}

  // view-snapshot 작업: 그날의 조회수를 읽어 저장한다. 같은 날 작업이 다시 돌아도 한 번만 읽고 한 줄만 남는다.
  // 가장 최근 세 줄이 모두 null이면(읽지 못한 날이 연속 3일) 정산하지 않고 멈춘다.
  async takeSnapshot(collaborationId: string, dayIndex: number): Promise<void> {
    const collaboration = await this.collaborations.findById(collaborationId);
    if (!collaboration) return;
    // 멈추는 도중에 죽었다면 남은 단계(작업 취소, 알림)를 마친다. 이미 한 일은 같은 키라 그대로다.
    if (isViewCountHalt(collaboration)) {
      await this.finishHalt(collaboration);
      return;
    }
    if (collaboration.stage !== 'COUNTING') return;

    await this.ensureSnapshot(collaboration, dayIndex);
    const latest = await this.repository.latestSnapshots(
      collaborationId,
      HALT_AFTER_UNREADABLE_DAYS,
    );
    if (
      latest.length === HALT_AFTER_UNREADABLE_DAYS &&
      latest.every((s) => s.views === null)
    ) {
      await this.halt(collaboration);
    }
  }

  // 그날의 줄이 없을 때만 읽어서 저장한다. 읽지 못하면 views = null이다(0이 아니다).
  async ensureSnapshot(
    collaboration: Collaboration,
    dayIndex: number,
  ): Promise<void> {
    const existing = await this.repository.findSnapshot(
      collaboration.id,
      dayIndex,
    );
    if (existing) return;
    const views = await this.readViews(collaboration);
    await this.repository.createSnapshotIfAbsent({
      collaborationId: collaboration.id,
      dayIndex,
      views,
      takenAt: this.clock.now(),
    });
  }

  // 조회수 집계를 읽지 못해 협업을 멈춘다. 돈은 에스크로에 그대로 있다.
  // 운영자 알림을 먼저 보낸다: 알림이 실패하면 단계가 그대로라 작업이 다시 돌 때 신호가 다시 나간다.
  async halt(collaboration: Collaboration): Promise<void> {
    await this.operatorAlert.alert({
      subject: '조회수를 읽지 못해 협업이 멈췄어요. 확인해 주세요.',
      body: `협업 ID: ${collaboration.id}`,
    });
    await this.collaborations.advance(collaboration.id, 'COUNTING', 'HALTED', {
      stageBeforeHalt: 'COUNTING',
      haltedReason: VIEW_COUNT_HALT_REASON,
    });
    const fresh = await this.collaborations.findById(collaboration.id);
    if (fresh && isViewCountHalt(fresh)) await this.finishHalt(fresh);
  }

  // 멈춘 뒤의 정리: 정산과 남은 조회수 작업을 취소하고 양쪽에 알린다.
  private async finishHalt(collaboration: Collaboration): Promise<void> {
    await this.jobs.cancel(settleJobKey(collaboration.id));
    for (let day = 0; day <= SNAPSHOT_DAYS; day += 1) {
      await this.jobs.cancel(snapshotJobKey(collaboration.id, day));
    }
    const target = { kind: 'COLLABORATION', id: collaboration.id } as const;
    const dedupeKey = `halted:${collaboration.id}`;
    await this.notifications.notify({
      userId: collaboration.commissionerId,
      role: 'STORE',
      kind: 'COLLABORATION_HALTED',
      target,
      dedupeKey,
    });
    await this.notifications.notify({
      userId: collaboration.creatorId,
      role: 'CREATOR',
      kind: 'COLLABORATION_HALTED',
      target,
      dedupeKey,
    });
  }

  // 연결된 인스타그램 계정이 없으면 읽을 수 없다(수락 조건과 해제 제한이 있어 보통은 있다). 0회가 아니라 읽기 실패다.
  private async readViews(
    collaboration: Collaboration,
  ): Promise<number | null> {
    if (!collaboration.submittedUrl || !collaboration.submittedAt) return null;
    if (!(await this.instagram.getConnection(collaboration.creatorId))) {
      this.logger.warn('연결된 인스타그램 계정이 없어 조회수를 읽지 못했어요.');
      return null;
    }
    try {
      const views = await this.viewCount.read({
        url: collaboration.submittedUrl,
        submittedAt: collaboration.submittedAt,
      });
      // 음수나 소수는 잘못 읽은 값이다. 그 값으로 돈을 움직이지 않는다.
      return Number.isInteger(views) && views >= 0 ? views : null;
    } catch (error) {
      if (error instanceof ViewCountUnavailableError) return null;
      throw error;
    }
  }
}

export function isViewCountHalt(collaboration: Collaboration): boolean {
  return (
    collaboration.stage === 'HALTED' &&
    collaboration.haltedReason === VIEW_COUNT_HALT_REASON
  );
}
