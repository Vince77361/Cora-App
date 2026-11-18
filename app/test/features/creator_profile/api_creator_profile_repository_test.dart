import 'dart:convert';

import 'package:cora/features/creator_profile/data/api_creator_profile_repository.dart';
import 'package:cora/features/creator_profile/domain/creator_profile_repository.dart';
import 'package:cora_api/api.dart' as api;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../../support/fake_http_client.dart';

const _cardUrl =
    'https://x.supabase.co/storage/v1/object/public/photos/creator-cards/u1/abc.jpg';

/// GET은 서버에 저장된 프로필로, PUT은 받은 값을 그대로 돌려주는 가짜 서버.
class _ProfileServer extends FakeHttpClient {
  _ProfileServer({this.stored});

  /// 서버에 저장된 프로필 본문. null이면 프로필이 없어 GET이 404다.
  Map<String, Object?>? stored;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    if (request.method == 'GET') {
      if (stored == null) {
        statusCode = 404;
        body = jsonEncode({
          'error': {
            'code': 'NOT_FOUND',
            'message': '크리에이터 프로필이 아직 없어요.',
            'details': null,
          },
        });
      } else {
        statusCode = 200;
        body = jsonEncode(stored);
      }
    } else {
      statusCode = 200;
      body = jsonEncode(_profile());
    }
    return super.send(request);
  }

  List<http.BaseRequest> get puts =>
      requests.where((r) => r.method == 'PUT').toList();
  List<http.BaseRequest> get gets =>
      requests.where((r) => r.method == 'GET').toList();
}

Map<String, Object?> _profile({String? headline, String? cardPhotoUrl}) => {
  'userId': 'u1',
  'displayName': '서윤',
  'contentFocus': null,
  'photoUrl': null,
  'regionSido': '서울특별시',
  'regionSigungu': null,
  'instagramConnected': false,
  'followers': null,
  'instagramHandle': null,
  'cardHeadline': headline,
  'cardPhotoUrl': cardPhotoUrl,
};

ApiCreatorProfileRepository _repo(FakeHttpClient fake) =>
    ApiCreatorProfileRepository(
      api.ApiClient(basePath: 'http://127.0.0.1:3000')..client = fake,
    );

Map<String, dynamic> _body(http.BaseRequest request) =>
    jsonDecode((request as http.Request).body) as Map<String, dynamic>;

void main() {
  test('a profile save sends the profile and no card values', () async {
    final server = _ProfileServer(
      stored: _profile(headline: '출근 전 30초', cardPhotoUrl: _cardUrl),
    );

    final saved = await _repo(
      server,
    ).save(displayName: '서윤', regionSido: '서울특별시', contentFocus: '손목 루틴');

    // 카드의 한 줄과 사진은 대표 게시물(1번)이 정한다. 프로필 저장은 서버의 카드 값을 읽지도 보내지도 않는다.
    expect(server.gets, isEmpty);
    final body = _body(server.puts.single);
    expect(body['cardHeadline'], isNull);
    expect(body['cardPhotoPath'], isNull);
    expect(body['contentFocus'], '손목 루틴');
    expect(saved.displayName, '서윤');
  });

  test('saves even when the card photo is a featured post photo', () async {
    // 카드 사진이 대표 게시물(featured-posts/…)에서 오면 예전의 creator-cards 경로 규칙으로는 되찾을 수 없다.
    final server = _ProfileServer(
      stored: _profile(
        headline: '한 줄',
        cardPhotoUrl:
            'https://x.supabase.co/storage/v1/object/public/photos/featured-posts/u1/p.jpg',
      ),
    );

    await _repo(server).save(displayName: '서윤', regionSido: '서울특별시');

    expect(server.puts, hasLength(1));
  });

  test('a save that fails raises a CreatorProfileFailure', () async {
    final server = _ProfileServer(stored: _profile())..respond = (r) => 500;

    await expectLater(
      _repo(server).save(displayName: '서윤', regionSido: '서울특별시'),
      throwsA(isA<CreatorProfileFailure>()),
    );
  });

  test('fetch maps the card values', () async {
    final server = _ProfileServer(
      stored: _profile(headline: '한 줄', cardPhotoUrl: _cardUrl),
    );

    final profile = await _repo(server).fetchMine();

    expect(profile!.cardHeadline, '한 줄');
    expect(profile.cardPhotoUrl, _cardUrl);
  });
}
