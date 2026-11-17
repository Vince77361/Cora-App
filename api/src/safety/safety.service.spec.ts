import { AppError } from '../common/errors/app-error';
import { SafetyService } from './safety.service';

const USER = '11111111-1111-4111-8111-111111111111';
const ROOM = '33333333-3333-4333-8333-333333333333';

// 입력 검사는 DB·방·알림에 닿기 전에 끝나야 한다: 무엇이든 건드리면 던지는 가짜로 확인한다.
function untouchable(): never {
  throw new Error('입력 검사 전에 의존성을 건드렸어요.');
}
const trap = new Proxy({}, { get: untouchable });

// 방 조회만 손으로 만든 가짜로 두고 나머지는 건드리면 던진다.
function serviceWith(conversations: object): SafetyService {
  return new SafetyService(
    trap as never,
    conversations as never,
    trap as never,
    trap as never,
    trap as never,
    trap as never,
    trap as never,
    trap as never,
    { now: () => new Date('2026-12-01T03:00:00.000Z') },
  );
}

const code = async (run: Promise<unknown>): Promise<string | undefined> => {
  try {
    await run;
  } catch (error) {
    return error instanceof AppError ? error.code : 'OTHER';
  }
  return undefined;
};

describe('SafetyService input checks', () => {
  it('answers 404 for a malformed room id before reading anything', async () => {
    const service = serviceWith({});
    expect(await code(service.block(USER, 'not-a-uuid'))).toBe('NOT_FOUND');
    expect(
      await code(
        service.report(USER, {
          targetKind: 'CONVERSATION',
          targetId: 'not-a-uuid',
          reason: 'SPAM',
        }),
      ),
    ).toBe('NOT_FOUND');
    expect(
      await code(
        service.report(USER, {
          targetKind: 'USER',
          targetId: 'not-a-uuid',
          reason: 'SPAM',
        }),
      ),
    ).toBe('NOT_FOUND');
  });

  it('answers 404 for a user who is not in any of my rooms and for myself', async () => {
    const asked: string[] = [];
    const service = serviceWith({
      isRoomPartner: (_me: string, other: string) => {
        asked.push(other);
        return Promise.resolve(false);
      },
    });
    expect(
      await code(
        service.report(USER, {
          targetKind: 'USER',
          targetId: ROOM,
          reason: 'ABUSE',
        }),
      ),
    ).toBe('NOT_FOUND');
    expect(asked).toEqual([ROOM]);
  });

  it('refuses a detail longer than 500 characters counted as code points before reading anything', async () => {
    // 서비스는 DTO와 별개로 코드 포인트로 다시 센다(DB 제약과 같은 단위): DTO를 거치지 않고 들어와도 501자는 여기서 막힌다.
    const service = serviceWith({});
    expect(
      await code(
        service.report(USER, {
          targetKind: 'CONVERSATION',
          targetId: ROOM,
          reason: 'OTHER',
          detail: '😀'.repeat(501),
        }),
      ),
    ).toBe('VALIDATION_FAILED');
  });
});
