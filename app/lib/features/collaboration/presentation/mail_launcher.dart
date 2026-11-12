import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

/// 메일 작성 화면을 연다. 열 수 없으면(메일 앱이 없는 기기) false.
abstract class MailLauncher {
  Future<bool> compose({String? to, required String subject});
}

/// `mailto:` 주소. 제목의 빈칸·대괄호·한글은 퍼센트 인코딩한다(`+`가 아니라 `%20`이어야 메일 앱이
/// 제대로 읽는다). 받는 사람이 없으면 `mailto:?subject=…`다.
Uri mailtoUri({String? to, required String subject}) => Uri.parse(
  'mailto:${to == null ? '' : Uri.encodeComponent(to)}'
  '?subject=${Uri.encodeComponent(subject)}',
);

class UrlLauncherMailLauncher implements MailLauncher {
  const UrlLauncherMailLauncher();

  @override
  Future<bool> compose({String? to, required String subject}) async {
    try {
      return await launchUrl(mailtoUri(to: to, subject: subject));
    } catch (_) {
      return false;
    }
  }
}

final mailLauncherProvider = Provider<MailLauncher>(
  (ref) => const UrlLauncherMailLauncher(),
);
