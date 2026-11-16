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
  test('an ordinary profile save keeps the card values', () async {
    final server = _ProfileServer(
      stored: _profile(headline: '출근 전 30초', cardPhotoUrl: _cardUrl),
    );

    final saved = await _repo(
      server,
    ).save(displayName: '서윤', regionSido: '서울특별시', contentFocus: '손목 루틴');

    // PUT은 전체 교체라서, 카드 값을 서버의 현재 값 그대로 다시 보내야 지워지지 않는다.
    final body = _body(server.puts.single);
    expect(body['cardHeadline'], '출근 전 30초');
    expect(body['cardPhotoPath'], 'creator-cards/u1/abc.jpg');
    expect(body['contentFocus'], '손목 루틴');
    expect(saved.displayName, '서윤');
  });

  test('keeps the card photo path even when the url has a query', () async {
    final server = _ProfileServer(
      stored: _profile(cardPhotoUrl: '$_cardUrl?v=3'),
    );

    await _repo(server).save(displayName: '서윤', regionSido: '서울특별시');

    expect(
      _body(server.puts.single)['cardPhotoPath'],
      'creator-cards/u1/abc.jpg',
    );
  });

  test(
    'a new headline replaces the old one and the photo is still kept',
    () async {
      final server = _ProfileServer(
        stored: _profile(headline: '옛 한 줄', cardPhotoUrl: _cardUrl),
      );

      await _repo(
        server,
      ).save(displayName: '서윤', regionSido: '서울특별시', cardHeadline: '새 한 줄');

      final body = _body(server.puts.single);
      expect(body['cardHeadline'], '새 한 줄');
      expect(body['cardPhotoPath'], 'creator-cards/u1/abc.jpg');
    },
  );

  test(
    'a new card photo replaces the old one and the headline is kept',
    () async {
      final server = _ProfileServer(
        stored: _profile(headline: '옛 한 줄', cardPhotoUrl: _cardUrl),
      );

      await _repo(server).save(
        displayName: '서윤',
        regionSido: '서울특별시',
        cardPhotoPath: 'creator-cards/u1/new.png',
      );

      final body = _body(server.puts.single);
      expect(body['cardHeadline'], '옛 한 줄');
      expect(body['cardPhotoPath'], 'creator-cards/u1/new.png');
    },
  );

  test('an empty headline clears it', () async {
    final server = _ProfileServer(
      stored: _profile(headline: '옛 한 줄', cardPhotoUrl: _cardUrl),
    );

    await _repo(
      server,
    ).save(displayName: '서윤', regionSido: '서울특별시', cardHeadline: '');

    expect(_body(server.puts.single)['cardHeadline'], '');
  });

  test(
    'sends both new card values without reading the profile first',
    () async {
      final server = _ProfileServer(stored: _profile());

      await _repo(server).save(
        displayName: '서윤',
        regionSido: '서울특별시',
        cardHeadline: '한 줄',
        cardPhotoPath: 'creator-cards/u1/c.jpg',
      );

      expect(server.gets, isEmpty);
      final body = _body(server.puts.single);
      expect(body['cardHeadline'], '한 줄');
      expect(body['cardPhotoPath'], 'creator-cards/u1/c.jpg');
    },
  );

  test('the first save has no card to keep', () async {
    final server = _ProfileServer();

    await _repo(server).save(displayName: '서윤', regionSido: '서울특별시');

    final body = _body(server.puts.single);
    expect(body['cardHeadline'], isNull);
    expect(body['cardPhotoPath'], isNull);
  });

  test(
    'does not save when the current card photo path cannot be found',
    () async {
      final server = _ProfileServer(
        stored: _profile(cardPhotoUrl: 'https://cdn.example.test/other/1.jpg'),
      );

      await expectLater(
        _repo(server).save(displayName: '서윤', regionSido: '서울특별시'),
        throwsA(isA<CreatorProfileFailure>()),
      );
      // 경로를 모른 채 보내면 사진이 지워지므로 PUT까지 가지 않는다.
      expect(server.puts, isEmpty);
    },
  );

  test('does not save when the current profile cannot be read', () async {
    final server = _ProfileServer(stored: _profile())..respond = (r) => 500;

    await expectLater(
      _repo(server).save(displayName: '서윤', regionSido: '서울특별시'),
      throwsA(isA<CreatorProfileFailure>()),
    );
    expect(server.puts, isEmpty);
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
