// 공유 플러그인의 플랫폼 인터페이스는 `share_plus`가 끌고 오는 패키지라 따로 의존으로 적지 않는다.
// ignore_for_file: depend_on_referenced_packages

import 'package:cora/core/share/share_launcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_plus_platform_interface/share_plus_platform_interface.dart';

import '../../support/fake_share_launcher.dart';

/// 공유 플러그인의 플랫폼 쪽을 손으로 대신한다.
class _FakeSharePlatform extends SharePlatform {
  final params = <ShareParams>[];

  @override
  Future<ShareResult> share(ShareParams params) async {
    this.params.add(params);
    return ShareResult.unavailable;
  }
}

void main() {
  // `SharePlus.instance`는 처음 쓸 때 플랫폼을 붙잡으므로, 쓰기 전에 가짜로 바꾼다.
  final platform = _FakeSharePlatform();
  SharePlatform.instance = platform;

  test('the share_plus launcher hands the text to the share sheet', () async {
    await SharePlusShareLauncher().shareText(
      'https://cora.page/l/hangeureut-ramen',
    );

    expect(platform.params.single.text, 'https://cora.page/l/hangeureut-ramen');
    expect(platform.params.single.uri, isNull);
  });

  test('the provider defaults to the real launcher and can be replaced', () {
    final real = ProviderContainer();
    addTearDown(real.dispose);
    expect(real.read(shareLauncherProvider), isA<SharePlusShareLauncher>());

    final fake = FakeShareLauncher();
    final replaced = ProviderContainer(
      overrides: [shareLauncherProvider.overrideWithValue(fake)],
    );
    addTearDown(replaced.dispose);
    expect(replaced.read(shareLauncherProvider), same(fake));
  });
}
