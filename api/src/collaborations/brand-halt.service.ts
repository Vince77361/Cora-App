import { Injectable, Logger } from '@nestjs/common';
import { CollaborationStage } from '@prisma/client';
import { ConversationsService } from '../conversations/conversations.service';
import { OperatorAlertPort } from '../integrations/operator-alert/operator-alert.port';
import { NotificationsService } from '../notifications/notifications.service';
import { haltedNoticeKey, NO_LINK_HALT_REASON } from '../settlements/job-keys';
import { BRAND_BEFORE_LINK_STAGES } from './collaboration-stage';
import { CollaborationsRepository } from './collaborations.repository';

export const NO_LINK_ALERT_SUBJECT = '[Cora] 협업 멈춤 · 60일 동안 링크 없음';

// brand-halt-check 작업의 몸: 브랜드 계약이 체결된 지 60일이 지났는데 링크가 없으면 협업을 멈추고 운영자와 양쪽에 알린다.
// 돈은 에스크로에 그대로 있다. 링크를 낸 협업(PUBLISHED 이후)이나 이미 끝난 협업이면 아무 일도 하지 않는다.
@Injectable()
export class BrandHaltService {
  private readonly logger = new Logger(BrandHaltService.name);

  constructor(
    private readonly collaborations: CollaborationsRepository,
    private readonly operatorAlert: OperatorAlertPort,
    private readonly notifications: NotificationsService,
    private readonly conversations: ConversationsService,
  ) {}

  async haltIfNoLink(collaborationId: string): Promise<void> {
    const found = await this.collaborations.findById(collaborationId);
    if (!found || found.kind !== 'BRAND_CONTRACT') return;
    // 멈추는 도중에 죽어 다시 돌 때는 남은 단계(알림)를 마친다. 이미 한 일은 같은 키라 그대로다.
    if (this.isNoLinkHalt(found)) {
      await this.finish(found.id);
      return;
    }
    if (!BRAND_BEFORE_LINK_STAGES.includes(found.stage)) return;
    // 조건부 전이: 같은 시각에 링크 제출이나 다른 멈춤이 먼저 단계를 옮겼다면 졌다(그 경우 멈추지 않는다).
    const halted = await this.collaborations.advance(
      found.id,
      found.stage,
      'HALTED',
      { stageBeforeHalt: found.stage, haltedReason: NO_LINK_HALT_REASON },
    );
    if (!halted) {
      // 같은 작업이 동시에 돌아 다른 쪽이 먼저 멈췄을 수 있다: 이 사유로 멈춰 있으면 남은 단계를 잇고, 아니면 끝.
      const fresh = await this.collaborations.findById(collaborationId);
      if (fresh && this.isNoLinkHalt(fresh)) await this.finish(fresh.id);
      return;
    }
    await this.finish(found.id);
  }

  private isNoLinkHalt(c: {
    stage: CollaborationStage;
    haltedReason: string | null;
  }): boolean {
    return c.stage === 'HALTED' && c.haltedReason === NO_LINK_HALT_REASON;
  }

  // 멈춘 뒤의 단계: 운영자 메일 → 양쪽 알림 → 대화방 갱신. 운영자 메일이 먼저다(사람이 봐야 하는 일이고, 재시도가 마저 마친다).
  // 멈출 때 협업에 남은 다른 작업은 없다(정산 작업은 링크를 낸 뒤에만 생기고, 점검 작업은 지금 이 작업이다).
  // 이 작업은 API 프로세스의 작업자에서 돈다(운영 명령 프로세스는 작업자를 끈다): 게이트웨이가 있고 Redis 어댑터가 다른 서버의 소켓에도 닿게 한다.
  private async finish(collaborationId: string): Promise<void> {
    const c = await this.collaborations.findById(collaborationId);
    if (!c) return;
    await this.operatorAlert.alert({
      subject: NO_LINK_ALERT_SUBJECT,
      body: `협업 ID: ${c.id}\n멈추기 전 단계: ${c.stageBeforeHalt ?? '알 수 없음'}`,
    });
    const target = { kind: 'COLLABORATION', id: c.id } as const;
    // 멈춤 한 번마다 다른 키라 풀었다가 다시 멈추면 새로 간다. 같은 멈춤을 다시 처리하면 한 건이다.
    const dedupeKey = haltedNoticeKey(c.id, c.updatedAt);
    await this.notifications.notify({
      userId: c.commissionerId,
      role: 'BRAND',
      kind: 'COLLABORATION_HALTED',
      target,
      dedupeKey,
    });
    await this.notifications.notify({
      userId: c.creatorId,
      role: 'CREATOR',
      kind: 'COLLABORATION_HALTED',
      target,
      dedupeKey,
    });
    const roomId = await this.conversations.idForCollaboration(c.id);
    if (roomId) await this.conversations.publishUpdated(roomId, 'STATUS');
  }
}
