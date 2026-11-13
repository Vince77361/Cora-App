import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/cora_colors.dart';
import '../../../../core/theme/cora_text_styles.dart';

/// 입력 시트(제공 혜택, 고정 현금 직접 입력)가 함께 쓰는 틀: 위 제목, 가운데 입력 칸들, 아래 버튼들.
/// 캔버스에 없는 화면이라 식사권 고치기와 같은 모양(제목 19/700, 좌우 16)으로 만들었다.
class OfferSheetFrame extends StatelessWidget {
  const OfferSheetFrame({
    super.key,
    required this.title,
    required this.fields,
    required this.actions,
    this.error,
  });

  final String title;
  final List<Widget> fields;
  final List<Widget> actions;

  /// 입력이 틀렸을 때 칸 아래에 보이는 문구.
  final String? error;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final media = MediaQuery.of(context);
    // 키보드가 올라오면 버튼이 키보드 위에 오고, 아니면 안전 영역 위에 오되 최소 32를 둔다.
    final bottom = media.viewInsets.bottom > 0
        ? media.viewInsets.bottom + 16
        : math.max(32.0, media.viewPadding.bottom);
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
              child: Semantics(
                header: true,
                child: Text(
                  title,
                  style: CoraTextStyles.heading.copyWith(color: c.text),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 10,
                  children: [
                    ...fields,
                    if (error != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Semantics(
                          liveRegion: true,
                          child: Text(
                            error!,
                            style: CoraTextStyles.meta.copyWith(color: c.text),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, bottom),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 8,
                children: actions,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
