import 'package:cora_api/api.dart' as api;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client_provider.dart';
import '../../../../core/theme/cora_colors.dart';
import '../../../../core/theme/cora_text_styles.dart';
import '../../../../core/ui/cora_primary_button.dart';
import '../../../../core/ui/cora_secondary_button.dart';
import '../../../../core/ui/cora_pressable.dart';
import '../../../offer_terms/presentation/offer_terms_text.dart';

/// 개발 전용 가짜 결제창(캔버스에 없다). 실제 PG 결제창 자리에서 결제 결과를 직접 고른다.
///
/// 승인과 실패는 서버의 개발 전용 경로(`POST /dev/fake-payments/:id/approve|fail`)를 부른다.
/// 이 경로는 OpenAPI에 없어서 생성된 클라이언트의 `invokeAPI`로 부르고, 토큰은 클라이언트가 붙인다.
/// 이 화면은 개발 환경에서만 라우트에 등록된다(`kDevScreensCompiledIn && config.isDev`).
///
/// 어떤 버튼이든 누르면 창이 닫힌다. 결제가 됐는지는 창이 아니라 서버 상태로 정해지므로, 닫힌 뒤
/// 결제 화면이 서버에 묻는다. `닫기`는 아무것도 보내지 않아서 "창만 닫은" 경우를 흉내 낸다.
class FakeCheckoutPage extends ConsumerStatefulWidget {
  const FakeCheckoutPage({super.key, required this.paymentId, this.amount});

  final String paymentId;
  final int? amount;

  static const heading = '개발용 결제창';
  static const approve = '결제 승인';
  static const fail = '결제 실패';
  static const close = '닫기';

  /// 개발 도구라 캔버스에 없는 문구.
  static const sendFailed = '결과를 보내지 못했어요.';

  @override
  ConsumerState<FakeCheckoutPage> createState() => _FakeCheckoutPageState();
}

class _FakeCheckoutPageState extends ConsumerState<FakeCheckoutPage> {
  bool _sending = false;
  bool _failedToSend = false;

  Future<void> _settle(String result) async {
    if (_sending) return;
    setState(() {
      _sending = true;
      _failedToSend = false;
    });
    try {
      final path =
          '/dev/fake-payments/${Uri.encodeComponent(widget.paymentId)}/$result';
      final response = await ref
          .read(apiClientProvider)
          .invokeAPI(
            path,
            'POST',
            const <api.QueryParam>[],
            null,
            {},
            {},
            null,
          );
      if (response.statusCode >= 400) throw StateError('dev route failed');
    } catch (_) {
      if (mounted) {
        setState(() {
          _sending = false;
          _failedToSend = true;
        });
      }
      return;
    }
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final amount = widget.amount;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 56, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                FakeCheckoutPage.heading,
                style: CoraTextStyles.label.copyWith(color: c.textSecondary),
              ),
              if (amount != null) ...[
                const SizedBox(height: 8),
                Text(
                  wonExact(amount),
                  style: CoraTextStyles.headline.copyWith(color: c.text),
                ),
              ],
              const Spacer(),
              if (_failedToSend)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      FakeCheckoutPage.sendFailed,
                      textAlign: TextAlign.center,
                      style: CoraTextStyles.meta.copyWith(color: c.text),
                    ),
                  ),
                ),
              CoraPrimaryButton(
                label: FakeCheckoutPage.approve,
                onPressed: _sending ? null : () => _settle('approve'),
                look: CoraPrimaryButtonLook.accent,
              ),
              const SizedBox(height: 8),
              CoraSecondaryButton(
                label: FakeCheckoutPage.fail,
                onPressed: _sending ? null : () => _settle('fail'),
              ),
              const SizedBox(height: 8),
              Semantics(
                container: true,
                button: true,
                label: FakeCheckoutPage.close,
                onTap: _sending ? null : context.pop,
                child: ExcludeSemantics(
                  child: CoraPressable(
                    onTap: _sending ? null : context.pop,
                    child: SizedBox(
                      height: 48,
                      child: Center(
                        child: Text(
                          FakeCheckoutPage.close,
                          style: CoraTextStyles.bodySmall.copyWith(
                            color: c.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
