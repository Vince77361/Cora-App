import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

/// 바깥 브라우저에서 주소를 연다. 열 수 없으면 false.
abstract class ExternalLinkLauncher {
  Future<bool> open(Uri url);
}

/// 서버가 돌려준 링크를 열기 전에 `http`·`https`인지 확인한다. 크리에이터가 낸 주소라 다른 스킴
/// (`javascript:`, `file:` 등)이 섞여 있어도 앱이 열지 않게 한다. 열 수 없는 주소면 null.
Uri? openableLink(String? raw) {
  final uri = Uri.tryParse((raw ?? '').trim());
  if (uri == null || !uri.hasAuthority) return null;
  return (uri.scheme == 'https' || uri.scheme == 'http') ? uri : null;
}

class UrlLauncherExternalLinkLauncher implements ExternalLinkLauncher {
  const UrlLauncherExternalLinkLauncher();

  @override
  Future<bool> open(Uri url) async {
    try {
      return await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}

final externalLinkLauncherProvider = Provider<ExternalLinkLauncher>(
  (ref) => const UrlLauncherExternalLinkLauncher(),
);
