import 'dart:convert';

import 'package:cora/features/collaboration/data/api_collaboration_repository.dart';
import 'package:cora/features/collaboration/domain/collaboration.dart';
import 'package:cora/features/collaboration/domain/collaboration_repository.dart';
import 'package:cora/features/offer_terms/domain/offer_terms.dart';
import 'package:cora/features/view_report/domain/view_report.dart';
import 'package:cora_api/api.dart' as api;
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_http_client.dart';

ApiCollaborationRepository _repo(FakeHttpClient fake) =>
    ApiCollaborationRepository(
      api.ApiClient(basePath: 'http://127.0.0.1:3000')..client = fake,
    );

Map<String, Object?> _json({String stage = 'COUNTING'}) => {
  'brandProgress': null,
  'campaign': null,
  'campaignBudgetLeft': null,
  'canCancel': false,
  'canRequestCancel': false,
  'conversationId': null,
  'contractStatus': 'NONE',
  'extraRevisionsAllowed': 0,
  'cancelRequest': null,
  'counterpart': {'name': '한그릇 라멘', 'photoUrl': 'https://example.test/s.jpg'},
  'countingEndsAt': '2026-11-18T12:00:00.000Z',
  'currentViews': 4320,
  'earnedSoFar': 43200,
  'escrowAmount': 100000,
  'expectedRefund': null,
  'id': 'c0ffee11-aaaa-bbbb-cccc-000000000001',
  'kind': 'STORE_OFFER',
  'nextAction': null,
  'payoutScheduledFor': null,
  'payoutStatus': 'NONE',
  'role': 'CREATOR',
  'securedAmount': null,
  'settlement': null,
  'viewReportStatus': 'NONE',
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
  'title': null,
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
      c.terms!.reward,
      const Reward(
        voucher: Voucher(name: '식사권', value: 40000, people: 2),
        viewPay: ViewPay(ratePerThousand: 10000, cap: 100000),
      ),
    );
    expect(c.payoutStatus, PayoutStatus.none);
  });

  test('fetch maps a brand contract without a terms copy', () async {
    final fake = FakeHttpClient()
      ..body = jsonEncode({
        ..._json(stage: 'MATCHED'),
        'kind': 'BRAND_CONTRACT',
        'terms': null,
        'role': 'COMMISSIONER',
        'counterpart': {'name': '하루 한 컵', 'photoUrl': null},
      });

    final c = await _repo(fake).fetch('col-1');

    expect(c.kind, CollaborationKind.brandContract);
    expect(c.isStoreOffer, isFalse);
    expect(c.terms, isNull);
    expect(c.stage, CollaborationStage.other);
    expect(c.hasVoucher, isFalse);
    expect(c.hasPerView, isFalse);
    expect(() => c.offerTerms, throwsStateError);
  });

  test('fetch maps the brand contract progress, next action, secured amount '
      'and budget left', () async {
    final fake = FakeHttpClient()
      ..body = jsonEncode({
        ..._json(stage: 'NEGOTIATING'),
        'kind': 'BRAND_CONTRACT',
        'terms': null,
        'role': 'COMMISSIONER',
        'counterpart': {'name': '서윤의 작은 취향', 'photoUrl': null},
        'title': '출근 전 30초, 오늘의 손목 루틴',
        'campaign': {
          'id': 'campaign-1',
          'brandName': '모아 스튜디오',
          'headline': '나만의 아침 루틴 속 작은 포인트',
        },
        'brandProgress': {
          'doneCount': 2,
          'current': 3,
          'currentNote': 'WAITING_OTHER_CONFIRM',
        },
        'securedAmount': 350000,
        'campaignBudgetLeft': {'left': 0, 'over': 50000},
        'nextAction': 'RESPOND_TERMS',
      });

    final c = await _repo(fake).fetch('col-1');

    expect(c.title, '출근 전 30초, 오늘의 손목 루틴');
    expect(c.campaign?.brandName, '모아 스튜디오');
    expect(c.campaign?.headline, '나만의 아침 루틴 속 작은 포인트');
    expect(c.brandProgress?.doneCount, 2);
    expect(c.brandProgress?.current, 3);
    expect(c.brandProgress?.note, BrandProgressNote.waitingOtherConfirm);
    expect(c.securedAmount, 350000);
    expect(c.campaignBudgetLeft?.left, 0);
    expect(c.campaignBudgetLeft?.over, 50000);
    expect(c.nextAction, CollaborationNextAction.respondTerms);
  });

  test('the next action, progress note and budget are null when the server '
      'sends none', () async {
    final fake = FakeHttpClient()
      ..body = jsonEncode({
        ..._json(stage: 'AGREED'),
        'kind': 'BRAND_CONTRACT',
        'terms': null,
        'brandProgress': {'doneCount': 6, 'current': null, 'currentNote': null},
        'nextAction': 'SIGN_CONTRACT',
      });

    final c = await _repo(fake).fetch('col-1');

    expect(c.nextAction, CollaborationNextAction.signContract);
    expect(c.brandProgress?.current, isNull);
    expect(c.brandProgress?.note, isNull);
    expect(c.campaignBudgetLeft, isNull);
    expect(c.securedAmount, isNull);
  });

  test('fetch maps a store offer to the store offer kind', () async {
    final fake = FakeHttpClient()..body = jsonEncode(_json());

    final c = await _repo(fake).fetch('col-1');

    expect(c.kind, CollaborationKind.storeOffer);
    expect(c.isStoreOffer, isTrue);
  });

  test('fetch maps the view report status, NONE to null', () async {
    final fake = FakeHttpClient()..body = jsonEncode(_json());
    expect((await _repo(fake).fetch('col-1')).viewReportStatus, isNull);

    for (final (wire, expected) in [
      ('COUNTING', ViewReportStatus.counting),
      ('UNCONFIRMED', ViewReportStatus.unconfirmed),
      ('CONFIRMED', ViewReportStatus.confirmed),
      ('DISPUTED', ViewReportStatus.disputed),
    ]) {
      fake.body = jsonEncode({..._json(), 'viewReportStatus': wire});
      expect((await _repo(fake).fetch('col-1')).viewReportStatus, expected);
    }
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
