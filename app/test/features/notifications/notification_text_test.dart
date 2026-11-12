import 'package:cora/core/navigation/app_routes.dart';
import 'package:cora/features/notifications/presentation/notification_routes.dart';
import 'package:cora/features/notifications/presentation/notification_text.dart';
import 'package:cora/features/onboarding/domain/user_role.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('relativeTimeLabel', () {
    // 한국 시간 2026-11-12 12:00.
    final now = DateTime.utc(2026, 11, 12, 3);

    test('labels times like the canvas', () {
      expect(
        relativeTimeLabel(now, now.subtract(const Duration(seconds: 20))),
        '방금',
      );
      expect(
        relativeTimeLabel(now, now.subtract(const Duration(minutes: 12))),
        '12분 전',
      );
      expect(
        relativeTimeLabel(now, now.subtract(const Duration(hours: 1))),
        '1시간 전',
      );
      expect(
        relativeTimeLabel(now, now.subtract(const Duration(days: 1))),
        '어제',
      );
      expect(
        relativeTimeLabel(now, now.subtract(const Duration(days: 3))),
        '11월 9일',
      );
    });

    test('rounds down to whole minutes and hours', () {
      expect(
        relativeTimeLabel(now, now.subtract(const Duration(seconds: 59))),
        '방금',
      );
      expect(
        relativeTimeLabel(now, now.subtract(const Duration(seconds: 60))),
        '1분 전',
      );
      expect(
        relativeTimeLabel(now, now.subtract(const Duration(minutes: 59))),
        '59분 전',
      );
      expect(
        relativeTimeLabel(now, now.subtract(const Duration(minutes: 119))),
        '1시간 전',
      );
      expect(
        relativeTimeLabel(now, now.subtract(const Duration(hours: 11))),
        '11시간 전',
      );
    });

    test('treats a time in the future as just now', () {
      expect(relativeTimeLabel(now, now.add(const Duration(minutes: 5))), '방금');
    });

    test('counts days on the Korean calendar, not the phone time zone', () {
      // 한국 시간 11-12 00:10인데 알림은 11-11 23:50(20분 전). 날이 바뀌었으므로 `어제`다.
      final justAfterMidnight = DateTime.utc(2026, 11, 11, 15, 10);
      expect(
        relativeTimeLabel(
          justAfterMidnight,
          justAfterMidnight.subtract(const Duration(minutes: 20)),
        ),
        '어제',
      );
      // 같은 한국 날짜 안(11-12 00:05 → 00:10)은 분으로 센다.
      expect(
        relativeTimeLabel(
          justAfterMidnight,
          justAfterMidnight.subtract(const Duration(minutes: 5)),
        ),
        '5분 전',
      );
      // UTC로는 11-10이지만 한국 시간으로는 11-11 08:00이라 하루 전이다.
      expect(
        relativeTimeLabel(justAfterMidnight, DateTime.utc(2026, 11, 10, 23)),
        '어제',
      );
    });

    test('adds the year when it differs', () {
      expect(
        relativeTimeLabel(now, DateTime.utc(2025, 12, 30, 3)),
        '2025년 12월 30일',
      );
      // 한국 시간으로는 이미 2026년 1월 1일이라 해가 같다.
      expect(
        relativeTimeLabel(
          DateTime.utc(2026, 11, 12),
          DateTime.utc(2025, 12, 31, 15),
        ),
        '1월 1일',
      );
    });
  });

  group('locationFor', () {
    test('sends store notifications to the home tabs', () {
      expect(
        locationFor('STORE_APPLICANTS', null, UserRole.store),
        '/store?tab=applicants',
      );
      expect(
        locationFor('STORE_SENT_OFFERS', null, UserRole.store),
        '/store?tab=sent-offers',
      );
    });

    test('sends an offer to the received offers', () {
      expect(
        locationFor('OFFER_INBOX', null, UserRole.creator),
        AppRoutes.creatorOffers,
      );
    });

    test('sends a payment to the pay screen of that collaboration', () {
      expect(
        locationFor('PAYMENT', 'c-1', UserRole.store),
        '/store/collaborations/c-1/pay',
      );
      expect(locationFor('PAYMENT', null, UserRole.store), isNull);
    });

    test('picks the collaboration screen by role', () {
      expect(
        locationFor('COLLABORATION', 'c-1', UserRole.store),
        '/store/collaborations/c-1',
      );
      expect(
        locationFor('COLLABORATION', 'c-1', UserRole.creator),
        '/creator/collaborations/c-1',
      );
      expect(locationFor('COLLABORATION', 'c-1', UserRole.brand), isNull);
      expect(locationFor('COLLABORATION', null, UserRole.store), isNull);
    });

    test('sends settlements to the wallet', () {
      expect(
        locationFor('WALLET', null, UserRole.creator),
        NotificationRoutes.wallet,
      );
      expect(NotificationRoutes.wallet, '/creator/wallet');
    });

    test('returns null for kinds it does not know', () {
      expect(locationFor('MATCH', 'x', UserRole.creator), isNull);
      expect(locationFor('', null, UserRole.store), isNull);
    });
  });

  test('reads the bell with the unread count', () {
    expect(NotificationTexts.bell(0), '알림');
    expect(NotificationTexts.bell(3), '알림, 새 알림 3개');
  });
}
