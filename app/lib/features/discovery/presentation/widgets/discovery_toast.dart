import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/cora_colors.dart';
import '../../../../core/theme/cora_shadows.dart';
import '../../../../core/theme/cora_swipe_tokens.dart';
import '../../../../core/theme/cora_text_styles.dart';
import '../../../../core/ui/cora_pressable.dart';

/// 카드 위에 3초 뜨는 알림 문구(캔버스 01). 바탕은 라이트가 흰색+그림자, 다크가 `#2A2D33`이다.
/// 서로 관심이 닿은 알림은 두 모드 모두 라임 바탕이다. [action]을 누르면 [onAction]이 불린다.
/// [creator]이면 08의 알림이다(캔버스 DarkCreatorDiscover): 다크에서 바탕이 `#0F1012`, 글자가 `#F2F3F5`이고
/// 그림자(rgba(23,24,28,0.16))가 남는다. 라이트는 01과 같다.
/// [onDismiss]는 3초 뒤에 한 번 불린다. 새 알림은 [key]가 달라야 3초를 다시 센다.
class DiscoveryToastBanner extends StatefulWidget {
  const DiscoveryToastBanner({
    super.key,
    required this.message,
    required this.onDismiss,
    this.action,
    this.onAction,
    this.match = false,
    this.creator = false,
  }) : assert((action == null) == (onAction == null));

  final String message;
  final String? action;
  final VoidCallback? onAction;
  final VoidCallback onDismiss;

  /// 서로 관심이 닿은 알림(라임 바탕).
  final bool match;

  /// 08(크리에이터의 발견)의 알림.
  final bool creator;

  static const duration = Duration(seconds: 3);

  @override
  State<DiscoveryToastBanner> createState() => _DiscoveryToastBannerState();
}

class _DiscoveryToastBannerState extends State<DiscoveryToastBanner> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(DiscoveryToastBanner.duration, widget.onDismiss);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final deep = widget.creator && dark;
    final surface = deep ? c.background : c.toastSurface;
    final shadow = deep
        ? CoraSwipeTokens.creatorToastShadowDark
        : c.toastShadow;
    final textStyle = CoraTextStyles.bodySmall.copyWith(
      fontWeight: widget.match ? FontWeight.w500 : FontWeight.w400,
      color: widget.match ? c.onAccent : (deep ? c.text : c.onToast),
    );
    final actionStyle = CoraTextStyles.bodySmall.copyWith(
      fontWeight: widget.match ? FontWeight.w900 : FontWeight.w700,
      color: widget.match ? c.text : c.accent,
    );
    return Semantics(
      container: true,
      liveRegion: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: widget.match ? c.accent : surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: widget.match
              ? null
              : [
                  BoxShadow(
                    color: shadow,
                    offset: const Offset(0, 8),
                    blurRadius: CoraShadows.blurRadiusFor(24),
                  ),
                ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            spacing: 10,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(widget.message, style: textStyle),
                ),
              ),
              if (widget.action != null)
                Semantics(
                  button: true,
                  onTap: widget.onAction,
                  child: ExcludeSemantics(
                    child: CoraPressable(
                      onTap: widget.onAction!,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(widget.action!, style: actionStyle),
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
