import 'dart:convert';

import 'package:cora/features/collaboration/data/api_collaboration_repository.dart';
import 'package:cora/features/collaboration/domain/collaboration.dart';
import 'package:cora/features/collaboration/domain/collaboration_repository.dart';
import 'package:cora/features/offer_terms/domain/offer_terms.dart';
import 'package:cora_api/api.dart' as api;
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_http_client.dart';

ApiCollaborationRepository _repo(FakeHttpClient fake) =>
    ApiCollaborationRepository(
      api.ApiClient(basePath: 'http://127.0.0.1:3000')..client = fake,
    );

Map<String, Object?> _json({String stage = 'COUNTING'}) => {
  'canCancel': false,
  'canRequestCancel': false,
  'cancelRequest': null,
  'counterpart': {'name': '한그릇 라멘', 'photoUrl': 'https://example.test/s.jpg'},
  'countingEndsAt': '2026-11-18T12:00:00.000Z',
  'currentViews': 4320,
  'earnedSoFar': 43200,
  'escrowAmount': 100000,
  'expectedRefund': null,
  'id': 'c0ffee11-aaaa-bbbb-cccc-000000000001',
  'kind': 'STORE_OFFER',
  'payoutScheduledFor': null,
  'payoutStatus': 'NONE',
  'role': 'CREATOR',
  'settlement': null,
  'stage': stage,
  'steps': [
    {'key': 'ACCEPTED', 'state': 'DONE', 'at': '2026-11-10T03:00:00.000Z'},
    {'key': 'PAID', 'state': 'DONE', 'at': '2026-11-10T04:00:00.000Z'},
    {'key': 'VISIT', 'state': 'DONE', 'at': null},
    {'key': 'SUBMIT', 'state': 'DONE', 'at': '2026-11-11T12:00:00.000Z'},
    {'key': 'SETTLE', 'state': 'NOW', 'at': null},
  ],
  'store': null,
  'submitDueAt': '2026-11-23T03:00:00.000Z',
  'submittedUrl': 'https://www.instagram.com/reel/abc',
  'terms': {
    'format': 'REELS',
    'pieces': 1,
    'voucherName': '식사권',
    'voucherValue': 40000,
    'voucherPeople': 2,
    'fixedCash': 0,
    'viewRatePerThousand': 10000,
    'perViewCap': 100000,
    'usageRights': 'STORE_REPOST_3M',
    'maxCashBurden': 100000,
    'settlementMethod': 'PER_VIEW',
  },
};

void main() {
  test('fetch maps the wire fields to the domain model', () async {
    final fake = FakeHttpClient()..body = jsonEncode(_json());

    final c = await _repo(fake).fetch('col-1');

    expect(fake.requests.single.url.path, '/collaborations/col-1');
    expect(c.stage, CollaborationStage.counting);
    expect(c.counterpartName, '한그릇 라멘');
    expect(c.counterpartPhotoUrl, 'https://example.test/s.jpg');
    expect(c.escrowAmount, 100000);
    expect((c.earnedSoFar, c.currentViews), (43200, 4320));
    expect(c.countingEndsAt, DateTime.utc(2026, 11, 18, 12));
    expect(c.steps.map((s) => s.key), StepKey.values);
    expect(c.steps.last.state, StepState.now);
    expect(c.steps.first.at, DateTime.utc(2026, 11, 10, 3));
    expect(
      c.terms.reward,
      const Reward(
        voucher: Voucher(name: '식사권', value: 40000, people: 2),
        viewPay: ViewPay(ratePerThousand: 10000, cap: 100000),
      ),
    );
    expect(c.payoutStatus, PayoutStatus.none);
  });

  test('fetchActive and fetchDone ask for their scope', () async {
    final fake = FakeHttpClient()..body = jsonEncode([_json()]);

    final active = await _repo(fake).fetchActive();
    await _repo(fake).fetchDone();

    expect(active, hasLength(1));
    expect(fake.requests[0].url.queryParameters, {'scope': 'active'});
    expect(fake.requests[1].url.queryParameters, {'scope': 'done'});
  });

  test(
    'submitLink posts the url and returns the updated collaboration',
    () async {
      final fake = FakeHttpClient()
        ..statusCode = 201
        ..body = jsonEncode(_json());

      final c = await _repo(fake).submitLink('col-1', 'https://x.test/a');

      final request = fake.requests.single as dynamic;
      expect(request.method, 'POST');
      expect(request.url.path, '/collaborations/col-1/submission');
      expect(jsonDecode(request.body as String), {'url': 'https://x.test/a'});
      expect(c.stage, CollaborationStage.counting);
    },
  );

  test('keeps the server message of a 4xx but not of a 5xx', () async {
    final fake = FakeHttpClient()
      ..statusCode = 409
      ..body = jsonEncode({
        'error': {
          'code': 'CONFLICT',
          'message': '내 계정의 게시물만 제출할 수 있어요.',
          'details': null,
        },
      });
    await expectLater(
      _repo(fake).submitLink('col-1', 'https://x.test/a'),
      throwsA(
        isA<CollaborationFailure>()
            .having((e) => e.conflict, 'conflict', isTrue)
            .having((e) => e.message, 'message', '내 계정의 게시물만 제출할 수 있어요.'),
      ),
    );

    final broken = FakeHttpClient()
      ..statusCode = 500
      ..body = jsonEncode({
        'error': {
          'code': 'INTERNAL',
          'message': 'stack trace',
          'details': null,
        },
      });
    await expectLater(
      _repo(broken).fetch('col-1'),
      throwsA(
        isA<CollaborationFailure>().having((e) => e.message, 'message', isNull),
      ),
    );
  });
}
