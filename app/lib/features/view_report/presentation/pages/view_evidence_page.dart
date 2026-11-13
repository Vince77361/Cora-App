import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../core/theme/cora_colors.dart';
import '../../../../core/theme/cora_shapes.dart';
import '../../../../core/theme/cora_text_styles.dart';
import '../../../../core/ui/cora_field_box.dart';
import '../../../../core/ui/cora_page_header.dart';
import '../../../../core/ui/cora_pressable.dart';
import '../../../../core/ui/cora_primary_button.dart';
import '../viewmodels/view_evidence_view_model.dart';

/// 조회수 캡처 올리기(캔버스에 없는 화면). 서버가 조회수를 읽지 못해 캡처를 요청했을 때 크리에이터가 인사이트
/// 화면의 캡처 한 장(5MB 이하)과 거기 적힌 조회수를 내고, 올린 뒤 F4의 자료 출처가 `캡처 제출 · 확인 중`이 된다.
class ViewEvidencePage extends ConsumerStatefulWidget {
  const ViewEvidencePage({super.key, required this.collaborationId});

  final String collaborationId;

  static const heading = '인사이트 화면을\n캡처해 올려 주세요';
  static const pickPhoto = '사진 고르기';
  static const changePhoto = '사진 바꾸기';
  static const field = '조회수';
  static const submit = '올리기';
  static const photoTooLarge = '사진이 너무 커요. 5MB 이하로 골라 주세요.';
  static const rateLimited = '사진을 너무 많이 올렸어요. 잠시 뒤에 다시 시도해 주세요.';
  static const failed = '올리지 못했어요. 다시 시도해 주세요.';

  /// 사진 칸의 높이(캔버스에 없다).
  static const photoHeight = 220.0;

  @override
  ConsumerState<ViewEvidencePage> createState() => _ViewEvidencePageState();
}

class _ViewEvidencePageState extends ConsumerState<ViewEvidencePage> {
  final _views = TextEditingController();

  @override
  void dispose() {
    _views.dispose();
    super.dispose();
  }

  ViewEvidenceViewModel get _vm =>
      ref.read(viewEvidenceViewModelProvider(widget.collaborationId).notifier);

  void _leave() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.creatorViewReport(widget.collaborationId));
    }
  }

  int? get _viewsValue => int.tryParse(_views.text.trim());

  Future<void> _submit() async {
    final views = _viewsValue;
    if (views == null) return;
    final ok = await _vm.submit(views);
    if (mounted && ok) _leave();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final state = ref.watch(
      viewEvidenceViewModelProvider(widget.collaborationId),
    );
    final bottom = math.max(32.0, MediaQuery.viewPaddingOf(context).bottom);
    final canSubmit = state.photo != null && _viewsValue != null && !state.busy;
    final error =
        state.message ??
        switch (state.error) {
          ViewEvidenceError.photoTooLarge => ViewEvidencePage.photoTooLarge,
          ViewEvidenceError.rateLimited => ViewEvidencePage.rateLimited,
          ViewEvidenceError.failed => ViewEvidencePage.failed,
          null => null,
        };
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
                        ViewEvidencePage.heading,
                        style: CoraTextStyles.headline.copyWith(color: c.text),
                      ),
                    ),
                    const SizedBox(height: 28),
                    _PhotoBox(
                      photo: state.photo?.bytes,
                      enabled: !state.busy,
                      onTap: _vm.pickPhoto,
                    ),
                    const SizedBox(height: 12),
                    CoraFieldBox(
                      label: ViewEvidencePage.field,
                      controller: _views,
                      enabled: !state.busy,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      maxLength: 10,
                      onChanged: (_) => setState(() {}),
                      onSubmitted: (_) => canSubmit ? _submit() : null,
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
                  if (error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Semantics(
                        liveRegion: true,
                        child: Text(
                          error,
                          textAlign: TextAlign.center,
                          style: CoraTextStyles.meta.copyWith(color: c.text),
                        ),
                      ),
                    ),
                  CoraPrimaryButton(
                    label: ViewEvidencePage.submit,
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

/// 사진 칸: 모서리 20, `surface`. 고르기 전에는 `사진 고르기`가 가운데에, 고른 뒤에는 사진이 채우고 오른쪽
/// 아래에 `사진 바꾸기` 알약이 있다.
class _PhotoBox extends StatelessWidget {
  const _PhotoBox({
    required this.photo,
    required this.enabled,
    required this.onTap,
  });

  final Uint8List? photo;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final picked = photo;
    final label = picked == null
        ? ViewEvidencePage.pickPhoto
        : ViewEvidencePage.changePhoto;
    return Semantics(
      container: true,
      button: true,
      enabled: enabled,
      label: label,
      onTap: enabled ? onTap : null,
      child: ExcludeSemantics(
        child: CoraPressable(
          onTap: enabled ? onTap : null,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(CoraRadius.field),
            child: SizedBox(
              height: ViewEvidencePage.photoHeight,
              child: ColoredBox(
                color: c.surface,
                child: picked == null
                    ? Center(
                        child: Text(
                          label,
                          style: CoraTextStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.w400,
                            color: c.textSecondary,
                          ),
                        ),
                      )
                    : Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.memory(
                            picked,
                            fit: BoxFit.cover,
                            alignment: Alignment.topCenter,
                            gaplessPlayback: true,
                            errorBuilder: (context, error, stack) =>
                                const SizedBox.expand(),
                          ),
                          Positioned(
                            right: 12,
                            bottom: 12,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: c.photoChip,
                                borderRadius: BorderRadius.circular(
                                  CoraRadius.pill,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 7,
                                ),
                                child: Text(
                                  label,
                                  style: CoraTextStyles.caption.copyWith(
                                    color: c.onPhotoChip,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
