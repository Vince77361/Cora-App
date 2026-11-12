import 'dart:convert';

import 'package:cora/features/notification_settings/data/api_notification_settings_repository.dart';
import 'package:cora/features/notification_settings/domain/notification_settings.dart';
import 'package:cora/features/notification_settings/domain/notification_settings_repository.dart';
import 'package:cora_api/api.dart' as api;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../../support/fake_http_client.dart';

ApiNotificationSettingsRepository _repo(FakeHttpClient fake) =>
    ApiNotificationSettingsRepository(
      api.ApiClient(basePath: 'http://127.0.0.1:3000')..client = fake,
    );

String _body({bool recommendations = false, String quietHours = 'NIGHT'}) =>
    jsonEncode({
      'enabledCount': recommendations ? 5 : 4,
      'messages': true,
      'mutualInterest': true,
      'offers': true,
      'quietHours': quietHours,
      'recommendations': recommendations,
      'settlement': true,
    });

void main() {
  test('fetch maps the five switches and quiet hours', () async {
    final fake = FakeHttpClient()..body = _body(quietHours: 'WEEKEND');

    final settings = await _repo(fake).fetch();

    expect(fake.requests.single.method, 'GET');
    expect(fake.requests.single.url.path, '/me/notification-settings');
    expect(settings.mutualInterest, isTrue);
    expect(settings.recommendations, isFalse);
    expect(settings.quietHours, QuietHours.weekend);
  });

  test('save puts the whole settings and returns the saved ones', () async {
    final fake = FakeHttpClient()..body = _body(recommendations: true);

    final saved = await _repo(fake).save(
      const NotificationSettings(
        mutualInterest: true,
        offers: true,
        messages: true,
        settlement: true,
        recommendations: true,
        quietHours: QuietHours.night,
      ),
    );

    final request = fake.requests.single as http.Request;
    expect(request.method, 'PUT');
    expect(request.url.path, '/me/notification-settings');
    expect(jsonDecode(request.body), {
      'messages': true,
      'mutualInterest': true,
      'offers': true,
      'quietHours': 'NIGHT',
      'recommendations': true,
      'settlement': true,
    });
    expect(saved.recommendations, isTrue);
  });

  test('any failure becomes one NotificationSettingsFailure', () async {
    final fake = FakeHttpClient()..statusCode = 500;

    await expectLater(
      _repo(fake).fetch(),
      throwsA(isA<NotificationSettingsFailure>()),
    );
    await expectLater(
      _repo(fake).save(defaultForTest),
      throwsA(isA<NotificationSettingsFailure>()),
    );
  });
}

const defaultForTest = NotificationSettings(
  mutualInterest: true,
  offers: true,
  messages: true,
  settlement: true,
  recommendations: false,
  quietHours: QuietHours.night,
);
