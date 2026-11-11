import { Injectable, Logger } from '@nestjs/common';
import { NotificationSwitch, UserRole } from '@prisma/client';
import { Clock } from '../common/clock';
import { PushPort } from '../integrations/push/push.port';
import {
  NOTIFICATION_CATALOG,
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
  dedupeKey?: string;
  // 대화방별 "알림 끄기"(5번 계획). 켜져 있으면 푸시하지 않는다.
  roomMuted?: boolean;
}

// 설정 행이 없는 사람의 기본값(E5의 처음 값).
const DEFAULT_SETTINGS: NotificationSettingsRow = {
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
