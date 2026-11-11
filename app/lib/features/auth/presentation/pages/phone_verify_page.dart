import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/cora_colors.dart';
import '../../../../core/theme/cora_shapes.dart';
import '../../../../core/theme/cora_text_styles.dart';
import '../../../../core/ui/cora_pressable.dart';
import '../../../../core/ui/cora_primary_button.dart';
import '../auth_messages.dart';
import '../viewmodels/phone_verify_view_model.dart';

/// E2 휴대폰 인증(NVerify / DarkNVerify).
///
/// 시스템 키보드 없이 화면의 숫자 키패드 하나로 입력한다. 처음에는 키패드가 휴대폰 번호
/// 칸을 채우고, 번호 11자리가 차면 인증번호를 보낸 뒤 인증번호 칸을 채운다. 캔버스는 보낸
/// 뒤의 모습만 그려 두어서 이 흐름은 그 모습에서 해석했다.
///
/// 로그인에 성공하면 세션이 바뀌고 라우터가 화면을 옮기므로 이 화면은 이동하지 않는다.
class PhoneVerifyPage extends ConsumerWidget {
  const PhoneVerifyPage({super.key});

  @visibleForTesting
  static const backKey = ValueKey<String>('PhoneVerifyPage.back');
  @visibleForTesting
  static const phoneFieldKey = ValueKey<String>('PhoneVerifyPage.phoneField');
  @visibleForTesting
  static const resendKey = ValueKey<String>('PhoneVerifyPage.resend');
  @visibleForTesting
  static const keypadKey = ValueKey<String>('PhoneVerifyPage.keypad');
  @visibleForTesting
  static ValueKey<String> codeBoxKey(int index) =>
      ValueKey<String>('PhoneVerifyPage.codeBox.$index');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final s =
        ref.watch(phoneVerifyViewModelProvider).value ??
        const PhoneVerifyState();
    final vm = ref.read(phoneVerifyViewModelProvider.notifier);
    final bottom = math.max(32.0, MediaQuery.viewPaddingOf(context).bottom);
    final ready = s.sent && s.codeComplete && !s.busy;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const _Header(),
            // 작은 화면이나 큰 글자에서는 가운데만 스크롤된다. 키패드와 버튼은 늘 아래에 있다.
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '문자로 받은\n인증번호를 넣어주세요.',
                            style: CoraTextStyles.headline.copyWith(
                              color: c.text,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // 보내기 전에는 비워 두고 자리만 지킨다(빈 글자도 한 줄 높이를 가진다).
                          Text(
                            s.sent ? '${_masked(s.phone)}로 보냈어요.' : '',
                            style: CoraTextStyles.bodySmall.copyWith(
                              color: c.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 28, 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _PhoneField(state: s, onTap: vm.editPhone),
                          const SizedBox(height: 10),
                          _CodeBoxes(state: s),
                          const SizedBox(height: 10),
                          _TimerRow(state: s, onResend: vm.resend),
                        ],
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
                  _Keypad(onDigit: vm.pressDigit, onBackspace: vm.backspace),
                  const SizedBox(height: 14),
                  CoraPrimaryButton(
                    look: CoraPrimaryButtonLook.accent,
                    label: s.sent && s.codeComplete ? '확인' : '6자리를 모두 넣어주세요',
                    onPressed: ready ? vm.submit : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// `01012342841` → `010-****-2841`. 가운데 네 자리를 가린다.
  static String _masked(String digits) =>
      '${digits.substring(0, 3)}-****-${digits.substring(7)}';
}

/// 머리글. 높이 64, 3칸 격자(60 / 1fr / 60): 뒤로, 제목, 빈칸.
class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SizedBox(
      height: 64,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            SizedBox(
              width: 60,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Semantics(
                  container: true,
                  button: true,
                  label: '뒤로',
                  excludeSemantics: true,
                  onTap: () => context.pop(),
                  child: CoraPressable(
                    onTap: () => context.pop(),
                    child: SizedBox.square(
                      key: PhoneVerifyPage.backKey,
                      dimension: 44,
                      child: Center(
                        child: CustomPaint(
                          size: const Size.square(24),
                          painter: _BackArrowPainter(color: c.text),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: Text(
                  '휴대폰 인증',
                  textAlign: TextAlign.center,
                  style: CoraTextStyles.bodyLarge.copyWith(color: c.text),
                ),
              ),
            ),
            const SizedBox(width: 60),
          ],
        ),
      ),
    );
  }
}

/// 캔버스 SVG: viewBox 24, 선 굵기 2.4, 둥근 끝과 꺾임, 경로 `M15 5l-7 7 7 7`.
class _BackArrowPainter extends CustomPainter {
  _BackArrowPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 24;
    final path = Path()
      ..moveTo(15 * k, 5 * k)
      ..lineTo(8 * k, 12 * k)
      ..lineTo(15 * k, 19 * k);
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4 * k
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..isAntiAlias = true,
    );
  }

  @override
  bool shouldRepaint(_BackArrowPainter old) => old.color != color;
}

/// 둥근 칸 하나. [active]면 안쪽에 2px 테두리가 생긴다(CSS `inset 0 0 0 2px`).
class _Field extends StatelessWidget {
  const _Field({
    super.key,
    required this.radius,
    required this.active,
    required this.child,
  });

  final double radius;
  final bool active;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final shape = BorderRadius.circular(radius);
    return DecoratedBox(
      decoration: BoxDecoration(color: c.surface, borderRadius: shape),
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          borderRadius: shape,
          border: active ? Border.all(color: c.focusRing, width: 2) : null,
        ),
        child: child,
      ),
    );
  }
}

/// 휴대폰 번호 칸. 보낸 뒤에 누르면 번호를 다시 고칠 수 있다.
class _PhoneField extends StatelessWidget {
  const _PhoneField({required this.state, required this.onTap});

  final PhoneVerifyState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final formatted = _format(state.phone);
    return Semantics(
      container: true,
      button: state.sent,
      label: '휴대폰 번호 $formatted',
      excludeSemantics: true,
      onTap: state.sent ? onTap : null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: _Field(
          key: PhoneVerifyPage.phoneFieldKey,
          radius: CoraRadius.field,
          // 보내기 전에는 번호를 받는 중이다.
          active: !state.sent,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '휴대폰 번호',
                  style: CoraTextStyles.fieldLabel.copyWith(
                    color: c.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formatted,
                  style: CoraTextStyles.fieldValue.copyWith(color: c.text),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// `01012342841` → `010-1234-2841`. 입력하는 만큼만 하이픈을 붙인다.
  static String _format(String digits) {
    if (digits.length <= 3) return digits;
    if (digits.length <= 7) {
      return '${digits.substring(0, 3)}-${digits.substring(3)}';
    }
    return '${digits.substring(0, 3)}-${digits.substring(3, 7)}-${digits.substring(7)}';
  }
}

/// 인증번호 6칸. 지금 입력할 칸에 안쪽 테두리가 생긴다.
class _CodeBoxes extends StatelessWidget {
  const _CodeBoxes({required this.state});

  final PhoneVerifyState state;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      container: true,
      label: '인증번호 6자리',
      child: Row(
        children: [
          for (var i = 0; i < PhoneVerifyState.codeLength; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(
              child: SizedBox(
                height: 60,
                child: _Field(
                  key: PhoneVerifyPage.codeBoxKey(i),
                  radius: CoraRadius.lg,
                  // 보낸 뒤에만 인증번호 칸이 입력 중이다.
                  active: state.sent && i == state.code.length,
                  child: Center(
                    child: Text(
                      i < state.code.length ? state.code[i] : '',
                      style: CoraTextStyles.digit.copyWith(color: c.text),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// `남은 시간 2:41` ↔ `다시 보내기`. 안내가 있으면 남은 시간 자리에 대신 보인다.
class _TimerRow extends StatelessWidget {
  const _TimerRow({required this.state, required this.onResend});

  final PhoneVerifyState state;
  final VoidCallback onResend;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final notice = state.notice;
    final text = switch (notice) {
      PhoneVerifyNotice.wrongCode => AuthMessages.wrongCode,
      PhoneVerifyNotice.tryLater => AuthMessages.tryLater,
      null => state.sent ? '남은 시간 ${_format(state.remaining)}' : '',
    };
    final canResend = state.phoneComplete && !state.busy;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Semantics(
              liveRegion: notice != null,
              child: Text(
                text,
                style: CoraTextStyles.meta.copyWith(color: c.textSecondary),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Semantics(
            container: true,
            button: true,
            enabled: canResend,
            label: '다시 보내기',
            excludeSemantics: true,
            onTap: canResend ? onResend : null,
            child: CoraPressable(
              onTap: canResend ? onResend : null,
              child: SizedBox(
                key: PhoneVerifyPage.resendKey,
                height: 40,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: c.subtleAction,
                    borderRadius: BorderRadius.circular(CoraRadius.pill),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Center(
                      widthFactor: 1,
                      child: Text(
                        '다시 보내기',
                        style: CoraTextStyles.label.copyWith(
                          color: canResend ? c.onSubtleAction : c.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 남은 시간을 `m:ss`로. 1초가 안 남아도 0:00이 되기 전까지는 올림해서 보여 준다.
  static String _format(Duration remaining) {
    final seconds = (remaining.inMilliseconds + 999) ~/ 1000;
    final m = seconds ~/ 60;
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

/// 숫자 키패드. 3열, 순서 `1 2 3 / 4 5 6 / 7 8 9 / (빈칸) 0 ←`.
class _Keypad extends StatelessWidget {
  const _Keypad({required this.onDigit, required this.onBackspace});

  final void Function(String digit) onDigit;
  final VoidCallback onBackspace;

  static const _rows = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
    ['', '0', '←'],
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      key: PhoneVerifyPage.keypadKey,
      children: [
        for (var r = 0; r < _rows.length; r++) ...[
          if (r > 0) const SizedBox(height: 6),
          Row(
            children: [
              for (var i = 0; i < 3; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                Expanded(child: _key(_rows[r][i])),
              ],
            ],
          ),
        ],
      ],
    );
  }

  Widget _key(String label) {
    if (label.isEmpty) {
      // 캔버스의 빈 칸 자리. 눌러도 아무 일도 없으므로 스크린 리더에도 숨긴다.
      return const ExcludeSemantics(child: SizedBox(height: 50));
    }
    final backspace = label == '←';
    return _KeypadKey(
      label: label,
      semanticLabel: backspace ? '지우기' : label,
      onTap: backspace ? onBackspace : () => onDigit(label),
    );
  }
}

class _KeypadKey extends StatelessWidget {
  const _KeypadKey({
    required this.label,
    required this.semanticLabel,
    required this.onTap,
  });

  final String label;
  final String semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      container: true,
      button: true,
      label: semanticLabel,
      excludeSemantics: true,
      onTap: onTap,
      child: CoraPressable(
        onTap: onTap,
        child: SizedBox(
          height: 50,
          child: Center(
            child: Text(
              label,
              style: CoraTextStyles.keypad.copyWith(color: c.text),
            ),
          ),
        ),
      ),
    );
  }
}
