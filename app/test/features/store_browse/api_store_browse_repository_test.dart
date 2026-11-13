import 'dart:convert';

import 'package:cora/features/store_browse/data/api_store_browse_repository.dart';
import 'package:cora/features/store_browse/domain/store_detail.dart';
import 'package:cora_api/api.dart' as api;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../../support/fake_http_client.dart';

ApiStoreBrowseRepository _repo(FakeHttpClient fake) => ApiStoreBrowseRepository(
  api.ApiClient(basePath: 'http://127.0.0.1:3000')..client = fake,
);

String _detail({Map<String, Object?>? myOpenOffer}) => jsonEncode({
  'id': 's1',
  'name': '한그릇 라멘',
  'industry': 'FOOD_CAFE',
  'category': '라멘집',
  'neighborhood': '성수동',
  'regionSido': '서울특별시',
  'regionSigungu': '성동구',
  'coverPhotoUrl': null,
  'intro': null,
  'bestShootingTime': null,
  'hours': null,
  'seats': null,
  'signatureMenu': null,
  'myApplicationStatus': 'OFFERED',
  'myOpenOffer': myOpenOffer,
  'defaultTerms': {
    'format': 'REELS',
    'pieces': 1,
    'fixedCash': 0,
    'maxCashBurden': 60000,
    'settlementMethod': 'PER_VIEW',
    'usageRights': 'STORE_REPOST_3M',
    'viewRatePerThousand': 2000,
    'perViewCap': 60000,
    'voucherName': '식사권',
    'voucherValue': 40000,
    'voucherPeople': 2,
  },
});

void main() {
  test('sends the one line pitch when applying', () async {
    final fake = FakeHttpClient()..body = '{}';

    // 응답 본문은 이 테스트가 보는 것이 아니라서 읽지 못해도 요청만 확인한다.
    await _repo(fake).apply('s1', pitch: '첫 숟가락').catchError((_) {});

    final request = fake.requests.single as http.Request;
    expect(request.method, 'POST');
    expect(request.url.path, '/stores/s1/applications');
    expect(jsonDecode(request.body), {'pitch': '첫 숟가락'});
  });

  test('applies without a pitch by sending no pitch', () async {
    final fake = FakeHttpClient()..body = '{}';

    await _repo(fake).apply('s1').catchError((_) {});

    final request = fake.requests.single as http.Request;
    expect(jsonDecode(request.body), {'pitch': null});
  });

  test('reads my open offer of the store', () async {
    final fake = FakeHttpClient()
      ..body = _detail(
        myOpenOffer: {'id': 'o1', 'latestVersion': 2, 'myTurn': false},
      );

    final detail = await _repo(fake).fetchDetail('s1');

    expect(
      detail.myOpenOffer,
      const MyOpenOffer(offerId: 'o1', latestVersion: 2, myTurn: false),
    );
    expect(detail.myApplicationStatus, MyApplicationStatus.offered);
  });

  test('has no open offer when the server sends none', () async {
    final fake = FakeHttpClient()..body = _detail();

    final detail = await _repo(fake).fetchDetail('s1');

    expect(detail.myOpenOffer, isNull);
  });
}
