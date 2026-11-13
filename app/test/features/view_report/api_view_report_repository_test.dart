import 'dart:convert';

import 'package:cora/features/view_report/data/api_view_report_repository.dart';
import 'package:cora/features/view_report/domain/view_report.dart';
import 'package:cora/features/view_report/domain/view_report_repository.dart';
import 'package:cora_api/api.dart' as api;
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_http_client.dart';

ApiViewReportRepository _repo(FakeHttpClient fake) => ApiViewReportRepository(
  api.ApiClient(basePath: 'http://127.0.0.1:3000')..client = fake,
);

Map<String, Object?> _json({
  String status = 'UNCONFIRMED',
  Object? evidence,
  String source = 'CONNECTED_ACCOUNT',
}) => {
  'status': status,
  'views': 12500,
  'postUrl': 'https://www.instagram.com/p/DAbC123/',
  'periodStart': '2026-11-04T03:00:00.000Z',
  'periodEnd': '2026-11-11T03:00:00.000Z',
  'source': source,
  'calc': {
    'viewPay': 25000,
    'ratePerThousand': 2000,
    'cap': 60000,
    'capApplied': false,
    'fixedCash': 0,
    'refund': 35000,
    'payout': 25000,
  },
  'confirmDueAt': '2026-11-13T03:00:00.000Z',
  'canConfirm': true,
  'canDispute': true,
  'canUploadEvidence': false,
  'evidence': evidence,
};

void main() {
  test('fetch maps the wire fields to the domain model', () async {
    final fake = FakeHttpClient()..body = jsonEncode(_json());

    final r = await _repo(fake).fetch('col-1');

    expect(fake.requests.single.url.path, '/collaborations/col-1/view-report');
    expect(r.status, ViewReportStatus.unconfirmed);
    expect(r.views, 12500);
    expect(r.source, ViewReportSource.connectedAccount);
    expect(r.periodStart, DateTime.utc(2026, 11, 4, 3));
    expect(r.calc!.payout, 25000);
    expect(r.calc!.refund, 35000);
    expect(r.calc!.capApplied, isFalse);
    expect(r.confirmDueAt, DateTime.utc(2026, 11, 13, 3));
    expect(
      (r.canConfirm, r.canDispute, r.canUploadEvidence),
      (true, true, false),
    );
    expect(r.evidence, isNull);
  });

  test('reads a capture whose signed address could not be made', () async {
    final fake = FakeHttpClient()
      ..body = jsonEncode(
        _json(
          source: 'CAPTURE_PENDING',
          evidence: {'imageUrl': null, 'statedViews': 12500},
        ),
      );

    final r = await _repo(fake).fetch('col-1');

    expect(r.source, ViewReportSource.capturePending);
    expect(r.evidence!.imageUrl, isNull);
    expect(r.evidence!.statedViews, 12500);
  });

  test('confirm, dispute and evidence post to their paths', () async {
    final fake = FakeHttpClient()
      ..statusCode = 201
      ..body = jsonEncode(_json(status: 'CONFIRMED'));
    final repo = _repo(fake);

    final confirmed = await repo.confirm('col-1');
    await repo.dispute('col-1', '조회수가 달라요');
    await repo.submitEvidence('col-1', 'evidence/u/a.jpg', 9000);

    expect(confirmed.status, ViewReportStatus.confirmed);
    final requests = fake.requests.cast<dynamic>();
    expect(requests[0].url.path, '/collaborations/col-1/view-report/confirm');
    expect(requests[1].url.path, '/collaborations/col-1/view-report/dispute');
    expect(jsonDecode(requests[1].body as String), {'reason': '조회수가 달라요'});
    expect(requests[2].url.path, '/collaborations/col-1/view-evidence');
    expect(jsonDecode(requests[2].body as String), {
      'path': 'evidence/u/a.jpg',
      'views': 9000,
    });
  });

  test('keeps the server message of a 4xx but not of a 5xx', () async {
    final fake = FakeHttpClient()
      ..statusCode = 409
      ..body = jsonEncode({
        'error': {'code': 'CONFLICT', 'message': '이미 확인됐어요.', 'details': null},
      });

    await expectLater(
      _repo(fake).confirm('col-1'),
      throwsA(
        isA<ViewReportFailure>()
            .having((e) => e.conflict, 'conflict', true)
            .having((e) => e.message, 'message', '이미 확인됐어요.'),
      ),
    );

    fake
      ..statusCode = 500
      ..body = jsonEncode({
        'error': {'code': 'INTERNAL', 'message': '내부 사정', 'details': null},
      });
    await expectLater(
      _repo(fake).confirm('col-1'),
      throwsA(
        isA<ViewReportFailure>().having((e) => e.message, 'message', isNull),
      ),
    );
  });

  test('marks a 404 as not found', () async {
    final fake = FakeHttpClient()
      ..statusCode = 404
      ..body = jsonEncode({
        'error': {'code': 'NOT_FOUND', 'message': '없어요.', 'details': null},
      });

    await expectLater(
      _repo(fake).fetch('col-1'),
      throwsA(
        isA<ViewReportFailure>().having((e) => e.notFound, 'notFound', true),
      ),
    );
  });
}
