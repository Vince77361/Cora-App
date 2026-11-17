import { Injectable, Logger } from '@nestjs/common';
import {
  Collaboration,
  Prisma,
  Report,
  ReportReason,
  UserRole,
} from '@prisma/client';
import {
  isMoneyHeld,
  preContractStages,
} from '../collaborations/collaboration-stage';
import { CollaborationsRepository } from '../collaborations/collaborations.repository';
import { Clock } from '../common/clock';
import { AppError } from '../common/errors/app-error';
import { ConversationDetailModel } from '../conversations/dto/conversation.model';
import { ConversationsService } from '../conversations/conversations.service';
import { OperatorAlertPort } from '../integrations/operator-alert/operator-alert.port';
import { JobScheduler } from '../jobs/job-scheduler';
import { NotificationsService } from '../notifications/notifications.service';
import { OffersService } from '../offers/offers.service';
import { haltJobKeys } from '../settlements/job-keys';
import { SettlementsRepository } from '../settlements/settlements.repository';
import { CreateReportDto, REPORT_DETAIL_MAX } from './dto/create-report.dto';
import { ReportCreatedModel } from './dto/report-created.model';
import { SafetyRepository } from './safety.repository';

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

// 신고로 멈춘 협업의 사유(collaborations.haltedReason). 운영 명령 resume이 이 값으로 되돌린다.
export const REPORTED_HALT_REASON = 'REPORTED';

const MONEY_HELD_MESSAGE = '진행 중인 협업이 있어요. 문의하기로 알려 주세요.';
const ALREADY_REPORTED_MESSAGE = '이미 신고했어요.';

const REASON_LABEL: Record<ReportReason, string> = {
  SPAM: '광고·스팸',
  ABUSE: '부적절한 말',
  FRAUD: '사기 의심',
  OTHER: '기타',
};

const notFound = (): AppError =>
  new AppError('NOT_FOUND', '대상을 찾을 수 없어요.');

// 신고를 저장하는 트랜잭션이 돌려주는 결과. 멈춘 협업과 멈추지 않은 이유를 커밋 뒤의 알림·메일이 쓴다.
interface ReportOutcome {
  report: Report;
  halted: Collaboration[];
  // 조회 자료 확인 전의 정산이 있어 멈추지 못한 협업. 돈은 확인 전에는 나가지 않는다.
  unhalted: Collaboration[];
}

// 차단과 신고. 둘 다 상대에게 사실을 알리지 않는다(알림·안내 줄 없음). 신고로 돈이 보관 중인 협업이 멈출 때만 양쪽에
// "협업이 잠시 멈췄어요"가 가고, 누가 신고했는지는 어디에도 담지 않는다.
@Injectable()
export class SafetyService {
  private readonly logger = new Logger(SafetyService.name);

  constructor(
    private readonly repository: SafetyRepository,
    private readonly conversations: ConversationsService,
    private readonly collaborations: CollaborationsRepository,
    private readonly offers: OffersService,
    private readonly settlements: SettlementsRepository,
    private readonly notifications: NotificationsService,
    private readonly jobs: JobScheduler,
    private readonly operatorAlert: OperatorAlertPort,
    private readonly clock: Clock,
  ) {}

  // 상대를 차단한다. 두 사람 사이의 협업 가운데 돈이 보관 중인 것이 하나라도 있으면 409다.
  // 통과하면 한 트랜잭션에서: 차단 행, 열린 오퍼와 결제 전 가게 협업 취소, 계약 전 브랜드 협업 종료(살아 있는 계약은 무효),
  // 두 사람 사이의 모든 방 닫기. 안내 줄도 알림도 남기지 않는다: 상대는 닫힌 방(`대화가 종료됐어요.`)만 본다.
  // 잠금 순서는 정산 → 오퍼 → 협업이다(lockAndListBetween). 결제·장부 행은 건드리지 않는다.
  async block(
    userId: string,
    conversationId: string,
  ): Promise<ConversationDetailModel> {
    const room = await this.requireRoom(userId, conversationId);
    const counterpartId = room.counterpartId;
    const now = this.clock.now();
    const closedRoomIds = await this.repository.transaction(async (tx) => {
      const collaborations = await this.collaborations.lockAndListBetween(
        userId,
        counterpartId,
        tx,
      );
      if (collaborations.some((c) => isMoneyHeld(c.kind, c.stage))) {
        throw new AppError('CONFLICT', MONEY_HELD_MESSAGE);
      }
      await this.repository.saveBlock(userId, counterpartId, now, tx);
      // 열린 오퍼와 결제 전 가게 협업.
      await this.offers.cancelForBlock(userId, counterpartId, tx);
      // 계약 전 브랜드 협업은 그만둔 것으로 끝내고, 브랜드가 아직 결제하지 않은 계약은 무효로 만든다.
      for (const c of collaborations) {
        if (
          c.kind !== 'BRAND_CONTRACT' ||
          !preContractStages.includes(c.stage)
        ) {
          continue;
        }
        const dropped = await this.collaborations.advance(
          c.id,
          c.stage,
          'DROPPED',
          { dropReason: 'BLOCKED', droppedById: userId },
          tx,
        );
        if (!dropped) {
          throw new AppError(
            'CONFLICT',
            '협업의 상태가 바뀌었어요. 잠시 뒤 다시 시도해 주세요.',
          );
        }
        await this.collaborations.voidPendingContract(c.id, 'BLOCKED', now, tx);
      }
      return this.conversations.closeBetween(userId, counterpartId, tx);
    });
    // 닫힌 방을 양쪽 화면이 다시 읽게 한다(상대는 `대화가 종료됐어요.`만 본다). 전달 실패는 차단에 영향이 없다.
    for (const id of closedRoomIds) {
      await this.conversations.publishUpdated(id, 'STATUS');
    }
    return this.conversations.get(userId, conversationId);
  }

  // 신고를 저장하고 운영자에게 메일을 보낸다. 대상은 내가 참가한 방이나 그 상대여야 한다(아니면 404).
  // 돈이 보관 중인 협업(대화방 신고는 그 방의 협업, 사용자 신고는 둘 사이의 모든 협업)이면 그 협업을 HALTED(REPORTED)로 멈춘다:
  // 보관 중인 금액은 운영자가 확인할 때까지 지급되지 않는다(2026-11-11 소유자 결정).
  async report(
    userId: string,
    input: CreateReportDto,
  ): Promise<ReportCreatedModel> {
    const detail = this.cleanDetail(input.detail);
    const target = await this.resolveTarget(userId, input);
    if (
      await this.repository.findReport(userId, input.targetKind, input.targetId)
    ) {
      throw new AppError('CONFLICT', ALREADY_REPORTED_MESSAGE);
    }
    const now = this.clock.now();
    const outcome = await this.repository.transaction(
      async (tx): Promise<ReportOutcome> => {
        const collaborations = await this.collaborations.lockAndListBetween(
          userId,
          target.counterpartId,
          tx,
        );
        const report = await this.repository.createReport(
          {
            reporterId: userId,
            targetKind: input.targetKind,
            targetId: input.targetId,
            reason: input.reason,
            detail,
            now,
          },
          tx,
        );
        if (!report) throw new AppError('CONFLICT', ALREADY_REPORTED_MESSAGE);
        const halted: Collaboration[] = [];
        const unhalted: Collaboration[] = [];
        for (const c of collaborations) {
          if (target.collaborationId && c.id !== target.collaborationId)
            continue;
          // 이미 멈춘 협업은 다시 멈출 것이 없다(돈은 그대로 보관 중이다).
          if (c.stage === 'HALTED' || !isMoneyHeld(c.kind, c.stage)) continue;
          // 조회 자료 확인 전의 정산이 있으면 멈추지 않는다: 멈추면 확인·재개·강제 끝내기가 모두 막힌다(운영 명령 halt와 같다).
          // 돈은 확인 전에는 나가지 않으므로 운영자 메일로 알린다.
          const settlement = await this.settlements.findSettlement(c.id, tx);
          if (settlement && settlement.status !== 'CONFIRMED') {
            unhalted.push(c);
            continue;
          }
          const moved = await this.collaborations.advance(
            c.id,
            c.stage,
            'HALTED',
            { stageBeforeHalt: c.stage, haltedReason: REPORTED_HALT_REASON },
            tx,
          );
          if (moved) halted.push(c);
          else unhalted.push(c);
        }
        return { report, halted, unhalted };
      },
    );
    await this.afterReport(userId, input, outcome);
    return { id: outcome.report.id };
  }

  // 운영 명령 resolve-report: 처리 완료로 표시한다. 감사 기록과 같은 트랜잭션이라 tx를 받는다.
  resolveReport(id: string, operator: string, tx: Prisma.TransactionClient) {
    return this.repository.resolveReport(id, operator, this.clock.now(), tx);
  }

  // 신고가 커밋된 뒤의 일: 멈춘 협업의 작업 취소, 양쪽 알림과 화면 갱신, 운영자 메일.
  // 모두 이미 저장된 신고와 멈춤을 되돌리지 않으므로 실패해도 던지지 않고(신고자가 다시 눌러도 409가 된다) 메일에 적어 알린다.
  private async afterReport(
    reporterId: string,
    input: CreateReportDto,
    outcome: ReportOutcome,
  ): Promise<void> {
    const failures: string[] = [];
    for (const c of outcome.halted) {
      if (!(await this.cancelJobs(c.id)))
        failures.push(`작업 취소 실패: ${c.id}`);
      await this.notifyHalted(c);
      const roomId = await this.conversations.idForCollaboration(c.id);
      if (roomId) await this.conversations.publishUpdated(roomId, 'STATUS');
    }
    const halted = outcome.halted.length > 0;
    const body = [
      `신고 ID: ${outcome.report.id}`,
      `대상: ${input.targetKind} ${input.targetId}`,
      `신고자 ID: ${reporterId}`,
      `설명: ${outcome.report.detail ?? '(없음)'}`,
      ...outcome.halted.map((c) => `멈춘 협업: ${c.id} (${c.stage} → HALTED)`),
      ...outcome.unhalted.map(
        (c) =>
          `멈추지 못한 협업: ${c.id} (${c.stage}, 조회 자료 확인 전 정산이 있어요. 돈은 확인 전에는 나가지 않아요)`,
      ),
      ...failures,
    ].join('\n');
    try {
      await this.operatorAlert.alert({
        subject: `[Cora] 신고 접수 · ${REASON_LABEL[input.reason]}${halted ? ' · 협업 멈춤' : ''}`,
        body,
      });
    } catch (error) {
      this.logger.error(
        `운영자 알림을 보내지 못했어요: ${error instanceof Error ? error.name : 'unknown'}`,
      );
    }
  }

  // 멈춘 협업에 남은 작업을 지운다. 지우지 못해도 처리기가 단계를 다시 보고 건너뛰므로 협업은 멈춘 채다.
  private async cancelJobs(collaborationId: string): Promise<boolean> {
    try {
      for (const key of haltJobKeys(collaborationId)) {
        await this.jobs.cancel(key);
      }
      return true;
    } catch (error) {
      this.logger.error(
        `멈춘 협업의 작업을 지우지 못했어요: ${error instanceof Error ? error.name : 'unknown'}`,
      );
      return false;
    }
  }

  // 양쪽에 같은 알림을 보낸다. 누가 신고했는지는 담지 않는다(행위자 없음).
  private async notifyHalted(c: Collaboration): Promise<void> {
    const target = { kind: 'COLLABORATION', id: c.id } as const;
    const dedupeKey = `halted:${c.id}`;
    const sides: { userId: string; role: UserRole }[] = [
      {
        userId: c.commissionerId,
        role: c.kind === 'BRAND_CONTRACT' ? 'BRAND' : 'STORE',
      },
      { userId: c.creatorId, role: 'CREATOR' },
    ];
    for (const side of sides) {
      try {
        await this.notifications.notify({
          ...side,
          kind: 'COLLABORATION_HALTED',
          target,
          dedupeKey,
        });
      } catch (error) {
        this.logger.warn(
          `협업 멈춤 알림을 남기지 못했어요: ${error instanceof Error ? error.name : 'unknown'}`,
        );
      }
    }
  }

  // 신고 대상이 내 방(또는 그 상대)인지 확인하고 상대와 대상 협업을 정한다. 아니면 404다.
  private async resolveTarget(
    userId: string,
    input: CreateReportDto,
  ): Promise<{ counterpartId: string; collaborationId: string | null }> {
    if (!UUID.test(input.targetId)) throw notFound();
    if (input.targetKind === 'CONVERSATION') {
      const room = await this.requireRoom(userId, input.targetId);
      return {
        counterpartId: room.counterpartId,
        collaborationId: room.collaborationId,
      };
    }
    if (!(await this.conversations.isRoomPartner(userId, input.targetId))) {
      throw notFound();
    }
    return { counterpartId: input.targetId, collaborationId: null };
  }

  private async requireRoom(userId: string, id: string) {
    if (!UUID.test(id)) throw notFound();
    return this.conversations.participantView(userId, id);
  }

  private cleanDetail(detail: string | undefined): string | null {
    const trimmed = detail?.trim() ?? '';
    if (trimmed === '') return null;
    if (Array.from(trimmed).length > REPORT_DETAIL_MAX) {
      throw new AppError('VALIDATION_FAILED', '500자까지 적을 수 있어요.');
    }
    return trimmed;
  }
}
