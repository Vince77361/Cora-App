import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../core/navigation/cora_transitions.dart';
import '../../../../core/regions.dart';
import '../../../../core/theme/cora_colors.dart';
import '../../../../core/theme/cora_shadows.dart';
import '../../../../core/theme/cora_shapes.dart';
import '../../../../core/theme/cora_text_styles.dart';
import '../../../../core/ui/cora_pressable.dart';
import '../../../../core/ui/cora_primary_button.dart';
import '../../../../core/ui/cora_step_header.dart';
import '../viewmodels/creator_profile_setup_view_model.dart';

/// 크리에이터 최소 프로필 만들기. 이 화면은 기획 캔버스에 없다. 모양은 가장 가까운 화면인
/// NEditProfile(원형 사진, `사진 바꾸기` 버튼)과 NStoreLink(제목, 입력 칸, 아래 버튼)를 따른다.
///
/// 활동 이름과 시·도가 있어야 `시작하기`가 켜진다. 저장되면 크리에이터 홈으로 간다.
class CreatorProfileSetupPage extends ConsumerStatefulWidget {
  const CreatorProfileSetupPage({super.key});

  static const saveFailed = '저장하지 못했어요. 다시 시도해 주세요.';
  static const photoTooLarge = '사진이 너무 커요. 5MB 이하로 골라 주세요.';

  // 캔버스에 없는 문구(사진 올리기 주소를 한 시간에 30번 넘게 받은 경우).
  static const rateLimited = '사진을 너무 많이 올렸어요. 잠시 뒤에 다시 시도해 주세요.';

  @visibleForTesting
  static const nameFieldKey = ValueKey<String>('creatorProfile.name');
  @visibleForTesting
  static const regionTileKey = ValueKey<String>('creatorProfile.region');
  @visibleForTesting
  static const sigunguFieldKey = ValueKey<String>('creatorProfile.sigungu');
  @visibleForTesting
  static const focusFieldKey = ValueKey<String>('creatorProfile.focus');
  @visibleForTesting
  static const instagramFieldKey = ValueKey<String>('creatorProfile.instagram');
  @visibleForTesting
  static const sidoListKey = ValueKey<String>('creatorProfile.sidoList');

  @override
  ConsumerState<CreatorProfileSetupPage> createState() =>
      _CreatorProfileSetupPageState();
}

class _CreatorProfileSetupPageState
    extends ConsumerState<CreatorProfileSetupPage> {
  final _name = TextEditingController();
  final _sigungu = TextEditingController();
  final _focus = TextEditingController();
  final _instagram = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _sigungu.dispose();
    _focus.dispose();
    _instagram.dispose();
    super.dispose();
  }

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      // 첫 화면으로 들어왔으면 쌓인 화면이 없다. 역할을 다시 고를 수 있게 A1로 간다.
      context.go(AppRoutes.role);
    }
  }

  Future<void> _chooseRegion(String? current) async {
    FocusManager.instance.primaryFocus?.unfocus();
    final picked = await Navigator.of(context, rootNavigator: true)
        .push<String>(
          CoraTransitions.sheet<String>(
            _SidoSheet(selected: current),
          ).createRoute(context),
        );
    if (picked == null || !mounted) return;
    ref
        .read(creatorProfileSetupViewModelProvider.notifier)
        .setRegionSido(picked);
  }

  Future<void> _submit() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final saved = await ref
        .read(creatorProfileSetupViewModelProvider.notifier)
        .submit();
    if (saved && mounted) context.go(AppRoutes.creator);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final vm = ref.read(creatorProfileSetupViewModelProvider.notifier);
    final s = ref.watch(creatorProfileSetupViewModelProvider).value;
    final state = s ?? const CreatorProfileSetupState();
    final bottom = math.max(32.0, MediaQuery.viewPaddingOf(context).bottom);
    final message = switch (state.error) {
      CreatorProfileSetupError.photoTooLarge =>
        CreatorProfileSetupPage.photoTooLarge,
      CreatorProfileSetupError.saveFailed => CreatorProfileSetupPage.saveFailed,
      CreatorProfileSetupError.rateLimited =>
        CreatorProfileSetupPage.rateLimited,
      null => null,
    };

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // 캔버스 NStoreLink 머리글: 높이 64, 좌우 8.
            SizedBox(
              height: 64,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: CoraBackButton(onPressed: _back),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.only(top: 24, bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '어떤 이름으로\n활동하나요?',
                            style: CoraTextStyles.headline.copyWith(
                              color: c.text,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '가게 사장님에게 이 이름으로 보여요.',
                            style: CoraTextStyles.body.copyWith(
                              color: c.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    _PhotoPicker(
                      photo: state.photo?.bytes,
                      onPick: vm.pickPhoto,
                    ),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        spacing: 10,
                        children: [
                          _TextBox(
                            fieldKey: CreatorProfileSetupPage.nameFieldKey,
                            label: '활동 이름',
                            controller: _name,
                            onChanged: vm.setDisplayName,
                            maxLength: 20,
                          ),
                          _RegionTile(
                            tileKey: CreatorProfileSetupPage.regionTileKey,
                            value: state.regionSido,
                            onTap: () => _chooseRegion(state.regionSido),
                          ),
                          _TextBox(
                            fieldKey: CreatorProfileSetupPage.sigunguFieldKey,
                            label: '구·군 (선택)',
                            controller: _sigungu,
                            onChanged: vm.setRegionSigungu,
                            maxLength: 20,
                          ),
                          _TextBox(
                            fieldKey: CreatorProfileSetupPage.focusFieldKey,
                            label: '주로 만드는 콘텐츠 (선택)',
                            hint: '예: 맛집 릴스',
                            controller: _focus,
                            onChanged: vm.setContentFocus,
                            maxLength: 30,
                          ),
                          _TextBox(
                            fieldKey: CreatorProfileSetupPage.instagramFieldKey,
                            label: '인스타그램 아이디 (선택)',
                            controller: _instagram,
                            onChanged: vm.setInstagramHandle,
                            // 서버가 받는 글자만(영문, 숫자, 점, 밑줄, 맨 앞의 @).
                            formatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[A-Za-z0-9._@]'),
                              ),
                            ],
                            maxLength: 31,
                            keyboardType: TextInputType.url,
                          ),
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
                  if (message != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Semantics(
                        liveRegion: true,
                        child: Text(
                          message,
                          textAlign: TextAlign.center,
                          style: CoraTextStyles.meta.copyWith(
                            color: c.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  CoraPrimaryButton(
                    label: '시작하기',
                    look: CoraPrimaryButtonLook.accent,
                    onPressed: state.canSubmit ? _submit : null,
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

/// 입력 칸 한 개(NStoreLink): 모서리 20, `surface` 바탕, 안쪽 14/16, 라벨 13/500 → 6 → 값 15.
class _TextBox extends StatelessWidget {
  const _TextBox({
    required this.fieldKey,
    required this.label,
    required this.controller,
    required this.onChanged,
    required this.maxLength,
    this.hint,
    this.formatters = const [],
    this.keyboardType,
  });

  final Key fieldKey;
  final String label;
  final String? hint;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final int maxLength;
  final List<TextInputFormatter> formatters;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final valueStyle = CoraTextStyles.body.copyWith(
      height: CoraTextStyles.bodySmall.height,
      color: c.text,
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(CoraRadius.field),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: MergeSemantics(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: CoraTextStyles.label.copyWith(color: c.textSecondary),
              ),
              const SizedBox(height: 6),
              TextField(
                key: fieldKey,
                controller: controller,
                onChanged: onChanged,
                keyboardType: keyboardType,
                textInputAction: TextInputAction.next,
                style: valueStyle,
                cursorColor: c.text,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(maxLength),
                  ...formatters,
                ],
                // 앱 테마의 입력칸 테두리(실선)를 쓰지 않는다. 칸 모양은 바깥 상자가 그린다.
                // `InputDecoration.collapsed`도 테마의 테두리를 물려받아 직접 끈다.
                decoration: InputDecoration(
                  isCollapsed: true,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  hintText: hint,
                  hintStyle: valueStyle.copyWith(color: c.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 활동 지역(시·도) 칸. 누르면 시트에서 고른다.
class _RegionTile extends StatelessWidget {
  const _RegionTile({
    required this.tileKey,
    required this.value,
    required this.onTap,
  });

  final Key tileKey;
  final String? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final valueStyle = CoraTextStyles.body.copyWith(
      height: CoraTextStyles.bodySmall.height,
    );
    return Semantics(
      container: true,
      button: true,
      onTap: onTap,
      child: CoraPressable(
        onTap: onTap,
        child: DecoratedBox(
          key: tileKey,
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(CoraRadius.field),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '활동 지역',
                        style: CoraTextStyles.label.copyWith(
                          color: c.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        value ?? '시·도 고르기',
                        style: valueStyle.copyWith(
                          color: value == null ? c.textSecondary : c.text,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                CustomPaint(
                  size: const Size.square(18),
                  painter: _ChevronDownPainter(c.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 시·도 고르기 시트. 17개를 한 줄씩 보여 주고 누르면 그 값으로 닫는다.
class _SidoSheet extends StatelessWidget {
  const _SidoSheet({required this.selected});

  final String? selected;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final bottom = MediaQuery.viewPaddingOf(context).bottom;
    return Material(
      color: Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 8),
            child: Text(
              '활동 지역',
              style: CoraTextStyles.heading.copyWith(color: c.text),
            ),
          ),
          Expanded(
            child: ListView(
              key: CreatorProfileSetupPage.sidoListKey,
              padding: EdgeInsets.fromLTRB(8, 0, 8, bottom + 16),
              children: [
                for (final sido in sidoList)
                  _SidoRow(
                    label: sido,
                    selected: sido == selected,
                    onTap: () => Navigator.of(context).pop(sido),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SidoRow extends StatelessWidget {
  const _SidoRow({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      container: true,
      button: true,
      selected: selected,
      onTap: onTap,
      child: CoraPressable(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: CoraTextStyles.bodyLarge.copyWith(color: c.text),
                  ),
                ),
                if (selected)
                  CustomPaint(
                    size: const Size.square(18),
                    painter: _CheckPainter(c.text),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 맨 위 원형 사진 자리(NEditProfile): 104 원, 오른쪽 아래에 36 둥근 `사진 바꾸기` 버튼. 아래에
/// 글자 버튼이 있다. 사진을 고르면 원 안에 보인다.
class _PhotoPicker extends StatelessWidget {
  const _PhotoPicker({required this.photo, required this.onPick});

  final Uint8List? photo;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      children: [
        ExcludeSemantics(
          child: CoraPressable(
            onTap: onPick,
            child: SizedBox(
              width: 104,
              height: 104,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipOval(
                      child: ColoredBox(
                        color: c.avatarPlaceholder,
                        child: photo == null
                            ? const SizedBox.expand()
                            : Image.memory(
                                photo!,
                                fit: BoxFit.cover,
                                gaplessPlayback: true,
                                errorBuilder: (context, error, stack) =>
                                    const SizedBox.expand(),
                              ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: c.avatarEditButton,
                        shape: BoxShape.circle,
                        boxShadow: CoraShadows.avatarEdit(c.avatarEditShadow),
                      ),
                      child: SizedBox.square(
                        dimension: 36,
                        child: Center(
                          child: CustomPaint(
                            size: const Size.square(18),
                            painter: _CameraPainter(c.text),
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
        const SizedBox(height: 8),
        Semantics(
          container: true,
          button: true,
          onTap: onPick,
          child: CoraPressable(
            onTap: onPick,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 44),
              child: Center(
                widthFactor: 1,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    photo == null ? '사진 고르기 (선택)' : '사진 바꾸기',
                    style: CoraTextStyles.label.copyWith(
                      color: c.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 캔버스의 카메라 아이콘: viewBox 24, 두께 2, `M4 8h3l2-3h6l2 3h3v11H4z`와 중심 (12,13) 반지름 3.5 원.
class _CameraPainter extends CustomPainter {
  const _CameraPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 24;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * k
      ..strokeJoin = StrokeJoin.round;
    final body = Path()
      ..moveTo(4 * k, 8 * k)
      ..relativeLineTo(3 * k, 0)
      ..relativeLineTo(2 * k, -3 * k)
      ..relativeLineTo(6 * k, 0)
      ..relativeLineTo(2 * k, 3 * k)
      ..relativeLineTo(3 * k, 0)
      ..lineTo(23 * k, 19 * k)
      ..lineTo(4 * k, 19 * k)
      ..close();
    canvas.drawPath(body, paint);
    canvas.drawCircle(Offset(12 * k, 13 * k), 3.5 * k, paint);
  }

  @override
  bool shouldRepaint(_CameraPainter old) => old.color != color;
}

class _ChevronDownPainter extends CustomPainter {
  const _ChevronDownPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 24;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * k
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(
      Path()
        ..moveTo(6 * k, 9 * k)
        ..lineTo(12 * k, 15 * k)
        ..lineTo(18 * k, 9 * k),
      paint,
    );
  }

  @override
  bool shouldRepaint(_ChevronDownPainter old) => old.color != color;
}

/// 캔버스의 체크 아이콘 경로 `M5 12l5 5 9-10`(viewBox 24).
class _CheckPainter extends CustomPainter {
  const _CheckPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 24;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4 * k
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(
      Path()
        ..moveTo(5 * k, 12 * k)
        ..relativeLineTo(5 * k, 5 * k)
        ..relativeLineTo(9 * k, -10 * k),
      paint,
    );
  }

  @override
  bool shouldRepaint(_CheckPainter old) => old.color != color;
}
