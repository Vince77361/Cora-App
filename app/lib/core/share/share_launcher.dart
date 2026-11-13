import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

/// 기기의 공유 창을 여는 포트. 화면이 `share_plus`를 직접 쓰지 않게 한다.
abstract class ShareLauncher {
  /// [text]를 공유 창에 넘긴다. 창을 열지 못하면 예외가 난다.
  Future<void> shareText(String text);
}

/// 기본은 실제 공유 창이다. 테스트가 가짜로 바꿔 끼운다.
final shareLauncherProvider = Provider<ShareLauncher>(
  (ref) => SharePlusShareLauncher(),
);

class SharePlusShareLauncher implements ShareLauncher {
  @override
  Future<void> shareText(String text) async {
    await SharePlus.instance.share(ShareParams(text: text));
  }
}
