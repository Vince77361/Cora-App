import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/cora_colors.dart';
import '../../../../core/theme/cora_shapes.dart';
import '../../../../core/theme/cora_text_styles.dart';
import '../../../../core/ui/cora_pressable.dart';

/// 대화방 메뉴가 여는 확인·선택 시트의 공통 틀(차단, 신고, 협의 그만두기: 캔버스에 없는 화면). 요청 거절 시트와
/// 같은 모양이다. 키보드가 올라오면 시트가 그만큼 밀려 올라간다.
Future<T?> showChatSheet<T>(BuildContext context, WidgetBuilder builder) {
  final c = context.colors;
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    // 바탕은 시트 안에서 칠한다. 시트가 열린 채 밝기가 바뀌어도 따라가게 한다.
    backgroundColor: Colors.transparent,
    barrierColor: c.scrim.withValues(alpha: 0.4),
    elevation: 0,
    showDragHandle: false,
    builder: (context) => DecoratedBox(
      decoration: BoxDecoration(
        color: context.colors.background,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(CoraRadius.xxl),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: builder(context),
      ),
    ),
  );
}

/// 차단·신고·그만두기 시트가 같이 쓰는 확인 흐름. [runAction]은 요청 중 다시 눌러도 한 번만 부르고, 성공(null)이면
/// 시트를 `true`로 닫고, 실패하면 시트를 연 채 [error]에 문구를 남긴다. 요청 중에는 [busy]가 참이라 버튼과 줄을 끈다.
mixin ChatSheetAction<T extends StatefulWidget> on State<T> {
  bool busy = false;
  String? error;

  Future<void> runAction(Future<String?> Function() action) async {
    if (busy) return;
    setState(() {
      busy = true;
      error = null;
    });
    final failure = await action();
    if (!mounted) return;
    if (failure == null) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        busy = false;
        error = failure;
      });
    }
  }
}

/// 시트 안쪽 여백: 위 28·좌우 16·아래 32(홈 막대가 더 크면 그만큼). 글이 길어지면 스크롤된다.
class ChatSheetBody extends StatelessWidget {
  const ChatSheetBody({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final bottom = math.max(32.0, MediaQuery.viewPaddingOf(context).bottom);
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, 28, 16, bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

/// 제목(19/700)과 설명 글. 좌우 8을 더 들여 버튼과 글줄을 맞춘다.
class ChatSheetHeading extends StatelessWidget {
  const ChatSheetHeading({super.key, required this.title, this.body});

  final String title;
  final String? body;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(
              title,
              style: CoraTextStyles.heading.copyWith(color: c.text),
            ),
          ),
          if (body != null) ...[
            const SizedBox(height: 8),
            Text(
              body!,
              style: CoraTextStyles.bodySmall.copyWith(color: c.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}

/// 시트 안에 보이는 실패 문구. 스크린 리더가 바로 읽는다.
class ChatSheetError extends StatelessWidget {
  const ChatSheetError({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Semantics(
      liveRegion: true,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: CoraTextStyles.meta.copyWith(color: context.colors.text),
      ),
    ),
  );
}

/// 이유 하나를 고르는 줄(높이 56 이상, 좌우 8). 오른쪽의 동그라미가 고른 것에서 라임으로 찬다.
class ChatReasonRow extends StatelessWidget {
  const ChatReasonRow({
    super.key,
    required this.label,
    required this.picked,
    required this.onTap,
  });

  final String label;
  final bool picked;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      container: true,
      button: true,
      inMutuallyExclusiveGroup: true,
      selected: picked,
      label: label,
      onTap: onTap,
      child: ExcludeSemantics(
        child: CoraPressable(
          onTap: onTap ?? () {},
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                spacing: 12,
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: CoraTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w400,
                        color: c.text,
                      ),
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: picked ? c.accent : Colors.transparent,
                      shape: BoxShape.circle,
                      border: picked
                          ? null
                          : Border.all(color: c.line, width: 1.5),
                    ),
                    child: SizedBox.square(
                      dimension: 24,
                      child: picked
                          ? Center(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: c.onAccent,
                                  shape: BoxShape.circle,
                                ),
                                child: const SizedBox.square(dimension: 8),
                              ),
                            )
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
