import 'dart:convert';

import 'package:cora/features/notifications/data/api_notification_repository.dart';
import 'package:cora/features/notifications/domain/app_notification.dart';
import 'package:cora/features/notifications/domain/notification_repository.dart';
import 'package:cora_api/api.dart' as api;
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_http_client.dart';

ApiNotificationRepository _repo(FakeHttpClient fake) =>
    ApiNotificationRepository(
      api.ApiClient(basePath: 'http://127.0.0.1:3000')..client = fake,
    );

Map<String, Object?> _row({
  String id = 'n1',
  String tab = 'COLLABORATION',
  Object? glyph,
  Object? actor = const {'name': '모아 스튜디오', 'photoUrl': 'https://x.test/a.jpg'},
  Object target = const {'kind': 'COLLABORATION', 'id': 'c-1'},
}) => {
  'id': id,
  'tab': tab,
  'text': '모아 스튜디오가 조건 버전 2를 확인했어요.',
  'glyph': glyph,
  'actor': actor,
  'target': target,
  'createdAt': '2026-11-12T01:00:00.000Z',
  'read': false,
};

void main() {
  test('fetch asks for the tab and cursor and maps the rows', () async {
    final fake = FakeHttpClient()
      ..body = jsonEncode({
        'items': [
          _row(),
          _row(
            id: 'n2',
            tab: 'SETTLEMENT',
            glyph: 'WON',
            actor: null,
            target: {'kind': 'WALLET', 'id': null},
          ),
        ],
        'nextCursor': 'abc',
      });

    final page = await _repo(
      fake,
    ).fetch(NotificationTabFilter.collaboration, cursor: 'prev');

    final uri = fake.requests.single.url;
    expect(uri.path, '/notifications');
    expect(uri.queryParameters, {'tab': 'COLLABORATION', 'cursor': 'prev'});
    expect(page.nextCursor, 'abc');
    final first = page.items.first;
    expect(first.id, 'n1');
    expect(first.tab, NotificationTab.collaboration);
    expect(first.glyph, isNull);
    expect(first.actorName, '모아 스튜디오');
    expect(first.actorPhotoUrl, 'https://x.test/a.jpg');
    expect(first.targetKind, 'COLLABORATION');
    expect(first.targetId, 'c-1');
    expect(first.createdAt, DateTime.utc(2026, 11, 12, 1));
    expect(first.read, isFalse);
    final second = page.items.last;
    expect(second.tab, NotificationTab.settlement);
    expect(second.glyph, NotificationGlyph.won);
    expect(second.actorName, '');
    expect(second.actorPhotoUrl, isNull);
    expect(second.targetId, isNull);
  });

  test('fetch sends ALL for the first tab', () async {
    final fake = FakeHttpClient()
      ..body = jsonEncode({'items': <Object>[], 'nextCursor': null});

    final page = await _repo(fake).fetch(NotificationTabFilter.all);

    expect(fake.requests.single.url.queryParameters, {'tab': 'ALL'});
    expect(page.items, isEmpty);
    expect(page.nextCursor, isNull);
  });

  test('unreadCount reads the count', () async {
    final fake = FakeHttpClient()..body = jsonEncode({'count': 7});

    expect(await _repo(fake).unreadCount(), 7);
    expect(fake.requests.single.url.path, '/notifications/unread-count');
  });

  test('read and readAll post to the read endpoints', () async {
    final fake = FakeHttpClient()
      ..statusCode = 201
      ..body = '';
    final repo = _repo(fake);

    await repo.read('n1');
    await repo.readAll();

    expect(fake.requests.map((r) => '${r.method} ${r.url.path}'), [
      'POST /notifications/n1/read',
      'POST /notifications/read-all',
    ]);
  });

  test('turns every failure into a NotificationFailure', () async {
    final fake = FakeHttpClient()
      ..statusCode = 404
      ..body = '{"error":{"code":"NOT_FOUND","message":"없어요.","details":null}}';
    final repo = _repo(fake);

    await expectLater(repo.read('x'), throwsA(isA<NotificationFailure>()));
    await expectLater(repo.unreadCount(), throwsA(isA<NotificationFailure>()));
    await expectLater(
      repo.fetch(NotificationTabFilter.all),
      throwsA(isA<NotificationFailure>()),
    );
  });
}
