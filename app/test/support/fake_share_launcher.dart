import 'package:cora/core/share/share_launcher.dart';

/// 손으로 쓴 가짜 공유 창. 넘겨받은 글을 모은다.
class FakeShareLauncher implements ShareLauncher {
  /// true이면 [shareText]가 예외를 던진다(공유 창을 열지 못한 경우).
  bool fail = false;

  final shared = <String>[];

  @override
  Future<void> shareText(String text) async {
    if (fail) throw StateError('공유 창을 열지 못했어요.');
    shared.add(text);
  }
}
