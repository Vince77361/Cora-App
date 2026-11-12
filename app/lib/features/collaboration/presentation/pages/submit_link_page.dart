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
import '../viewmodels/submit_link_view_model.dart';

/// 링크 제출(캔버스에 없다). 올린 콘텐츠의 주소를 붙여 넣고 `제출하기`를 누르면 서버가 형식과 내 계정의
/// 게시물인지를 확인한다. 거절 문구는 서버가 정해 주고, 화면에 머물며 고쳐서 다시 낼 수 있다.
class SubmitLinkPage extends ConsumerStatefulWidget {
  const SubmitLinkPage({super.key, required this.collaborationId});

  final String collaborationId;

  static const heading = '올린 콘텐츠의\n링크를 붙여 주세요';
  static const field = '콘텐츠 링크';
  static const note = '제출한 뒤에는 고칠 수 없어요.';
  static const submit = '제출하기';

  @override
  ConsumerState<SubmitLinkPage> createState() => _SubmitLinkPageState();
}

class _SubmitLinkPageState extends ConsumerState<SubmitLinkPage> {
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
      context.go(AppRoutes.creatorCollaboration(widget.collaborationId));
    }
  }

  Future<void> _submit() async {
    final ok = await ref
        .read(submitLinkViewModelProvider(widget.collaborationId).notifier)
        .submit(_controller.text);
    if (mounted && ok) _leave();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final state = ref.watch(
      submitLinkViewModelProvider(widget.collaborationId),
    );
    final bottom = math.max(32.0, MediaQuery.viewPaddingOf(context).bottom);
    final canSubmit = _controller.text.trim().isNotEmpty && !state.busy;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CoraPageHeader(onBack: _leave),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        SubmitLinkPage.heading,
                        style: CoraTextStyles.headline.copyWith(color: c.text),
                      ),
                    ),
                    const SizedBox(height: 28),
                    CoraFieldBox(
                      label: SubmitLinkPage.field,
                      controller: _controller,
                      enabled: !state.busy,
                      keyboardType: TextInputType.url,
                      onChanged: (_) => setState(() {}),
                      onSubmitted: (_) => canSubmit ? _submit() : null,
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        SubmitLinkPage.note,
                        style: CoraTextStyles.meta.copyWith(
                          color: c.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, bottom),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (state.error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Semantics(
                        liveRegion: true,
                        child: Text(
                          state.error!,
                          textAlign: TextAlign.center,
                          style: CoraTextStyles.meta.copyWith(color: c.text),
                        ),
                      ),
                    ),
                  CoraPrimaryButton(
                    label: SubmitLinkPage.submit,
                    onPressed: canSubmit ? _submit : null,
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
