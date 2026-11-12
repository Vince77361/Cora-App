import { Injectable, Logger } from '@nestjs/common';
import { NotificationSwitch, UserRole } from '@prisma/client';
import { Clock } from '../common/clock';
import { PushPort } from '../integrations/push/push.port';
import {
  NOTIFICATION_CATALOG,
  missingNotifyInputs,
  NotificationParams,
  NotificationTarget,
} from './notification-catalog';
import {
  NotificationSettingsRow,
  NotificationsRepository,
} from './notifications.repository';
import { isQuietAt } from './quiet-hours';

export interface NotifyInput {
  userId: string;
  role: UserRole;
  kind: keyof typeof NOTIFICATION_CATALOG;
  params?: NotificationParams;
  // 문구와 그림에 쓰는 상대. 이름과 사진 경로는 사본으로 저장한다.
  actor?: { userId: string; name: string; photoPath: string | null };
  target: NotificationTarget;
  // 작업 큐처럼 다시 실행될 수 있는 곳이 넘긴다. 같은 키의 두 번째 알림은 줄도 푸시도 만들지 않는다.
  // 주의: 줄(DB의 유일 제약)로 막으므로 알림함에 남는 종류(tab이 있는 종류)만 막힌다. 줄이 없는 종류
  // (5번 계획의 대화 메시지)는 키를 줘도 두 번째 푸시가 나가니, 그 종류는 호출하는 쪽이 중복을 막아야 한다.
  dedupeKey?: string;
  // 대화방별 "알림 끄기"(5번 계획). 켜져 있으면 푸시하지 않는다.
  roomMuted?: boolean;
}

// 문구에 필요한 값이 빠진 호출. 줄을 만들기 전에 던진다. 요청 경로는 잡아서 로그만 남기고(이름이 로그에 보이도록
// 클래스 이름을 따로 둔다), 작업 처리기는 그대로 올려 다시 시도되게 한다. 메시지에는 빠진 값의 이름만 담는다.
export class InvalidNotificationInput extends Error {
  constructor(kind: string, missing: string[]) {
    super(
      `알림에 필요한 값이 빠졌어요: kind=${kind} missing=${missing.join(', ')}`,
    );
    this.name = 'InvalidNotificationInput';
  }
}

// 설정 행이 없는 사람의 기본값(E5의 처음 값).
export const DEFAULT_SETTINGS: NotificationSettingsRow = {
  mutualInterest: true,
  offers: true,
  messages: true,
  settlement: true,
  recommendations: false,
  quietHours: 'NIGHT',
};

// 끌 수 없는 ESSENTIAL을 뺀 스위치가 설정의 어느 칸인지.
const SWITCH_FIELD: Record<
  Exclude<NotificationSwitch, 'ESSENTIAL'>,
  keyof Omit<NotificationSettingsRow, 'quietHours'>
> = {
  MUTUAL_INTEREST: 'mutualInterest',
  OFFERS: 'offers',
  MESSAGES: 'messages',
  SETTLEMENT: 'settlement',
  RECOMMENDATIONS: 'recommendations',
};

// 모든 알림이 지나는 하나의 길. 기능 모듈은 PushPort를 직접 부르지 않고 이것만 부른다.
// 트랜잭션이 끝난 뒤에 부른다: 알림이 실패해도 이미 저장된 변경은 유효해야 하기 때문이다.
@Injectable()
export class NotificationsService {
  private readonly logger = new Logger(NotificationsService.name);

  constructor(
    private readonly notifications: NotificationsRepository,
    private readonly push: PushPort,
    private readonly clock: Clock,
  ) {}

  // 줄을 만드는 데 실패하면 던진다(작업 큐가 다시 시도하고, 중복 방지 키가 두 번째 줄을 막는다).
  // 줄을 만든 뒤의 푸시 단계(설정 읽기, 푸시 전송)가 실패하면 던지지 않고 개인정보 없이 로그만 남긴다.
  async notify(input: NotifyInput): Promise<void> {
    const entry = NOTIFICATION_CATALOG[input.kind];
    const params = input.params ?? {};
    // 줄을 쓰기 전에 거른다: 틀린 문구("0원")가 한 번 저장되면 다시 시도해도 같은 키가 막아 고칠 수 없다.
    const missing = missingNotifyInputs(
      input.kind,
      params,
      input.actor ?? null,
    );
    if (missing.length > 0)
      throw new InvalidNotificationInput(input.kind, missing);

    let notificationId: string | null = null;
    if (entry.tab) {
      const created = await this.notifications.create({
        userId: input.userId,
        role: input.role,
        kind: input.kind,
        tab: entry.tab,
        params,
        actorUserId: input.actor?.userId ?? null,
        actorName: input.actor?.name ?? null,
        actorPhotoPath: input.actor?.photoPath ?? null,
        targetKind: input.target.kind,
        targetId: input.target.id,
        dedupeKey: input.dedupeKey ?? null,
        // DB 기본값(now())이 아니라 Clock의 시각이다: E3의 시각 표시, 90일 창, 개발용 시계 이동이 같은 시계를 본다(R24).
        createdAt: this.clock.now(),
      });
      // 이미 같은 키의 알림이 있다: 줄도 푸시도 만들지 않는다.
      if (!created) return;
      notificationId = created.id;
    }

    try {
      if (input.roomMuted) return;
      const settings =
        (await this.notifications.findSettings(input.userId)) ??
        DEFAULT_SETTINGS;
      if (!this.switchIsOn(entry.switch, settings)) return;
      // 방해 금지 시간에는 끌 수 없는 알림도 알림함에만 남긴다.
      if (isQuietAt(this.clock.now(), settings.quietHours)) return;
      await this.push.send({
        userId: input.userId,
        title: '',
        body: entry.render({
          actorName: input.actor?.name ?? null,
          params,
        }),
        data: {
          notificationId,
          targetKind: input.target.kind,
          targetId: input.target.id,
          role: input.role,
        },
      });
    } catch (error) {
      // 이름과 내용에는 개인정보가 들어갈 수 있어 종류와 오류 이름만 남긴다.
      this.logger.warn(
        `푸시를 보내지 못했어요: kind=${input.kind} ${error instanceof Error ? error.name : 'unknown'}`,
      );
    }
  }

  private switchIsOn(
    kind: NotificationSwitch,
    settings: NotificationSettingsRow,
  ): boolean {
    if (kind === 'ESSENTIAL') return true;
    return settings[SWITCH_FIELD[kind]];
  }
}
