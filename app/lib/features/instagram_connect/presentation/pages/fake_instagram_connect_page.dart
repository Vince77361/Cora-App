import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../core/theme/cora_colors.dart';
import '../../../../core/theme/cora_text_styles.dart';
import '../../../../core/ui/cora_field_box.dart';
import '../../../../core/ui/cora_page_header.dart';
import '../../../../core/ui/cora_primary_button.dart';
import '../viewmodels/instagram_connect_view_model.dart';

/// 개발 전용 가짜 인스타그램 연결 화면(캔버스에 없다). 실제 승인 화면 자리에서 연결할 계정 아이디를
/// 직접 입력한다. 서버의 가짜 어댑터가 입력한 값을 아이디로 받아 연결한다. 개발 환경에서만 라우트에
/// 등록된다(`kDevScreensCompiledIn && config.isDev`).
class FakeInstagramConnectPage extends ConsumerStatefulWidget {
  const FakeInstagramConnectPage({super.key});

  static const heading = '개발용 인스타그램 연결';
  static const field = '인스타그램 아이디';
  static const connect = '연결하기';

  @override
  ConsumerState<FakeInstagramConnectPage> createState() =>
      _FakeInstagramConnectPageState();
}

class _FakeInstagramConnectPageState
    extends ConsumerState<FakeInstagramConnectPage> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _leave() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.creatorInstagram);
    }
  }

  Future<void> _connect() async {
    final ok = await ref
        .read(instagramConnectViewModelProvider.notifier)
        .complete(_controller.text);
    if (mounted && ok) _leave();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final state = ref.watch(instagramConnectViewModelProvider).value;
    final bottom = math.max(32.0, MediaQuery.viewPaddingOf(context).bottom);
    final busy = state?.busy ?? false;
    final canConnect = _controller.text.trim().isNotEmpty && !busy;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CoraPageHeader(
              title: FakeInstagramConnectPage.heading,
              onBack: _leave,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: CoraFieldBox(
                  label: FakeInstagramConnectPage.field,
                  controller: _controller,
                  enabled: !busy,
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) => canConnect ? _connect() : null,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, bottom),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (state?.error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Semantics(
                        liveRegion: true,
                        child: Text(
                          state!.error!,
                          textAlign: TextAlign.center,
                          style: CoraTextStyles.meta.copyWith(color: c.text),
                        ),
                      ),
                    ),
                  CoraPrimaryButton(
                    label: FakeInstagramConnectPage.connect,
                    onPressed: canConnect ? _connect : null,
                    look: CoraPrimaryButtonLook.accent,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
