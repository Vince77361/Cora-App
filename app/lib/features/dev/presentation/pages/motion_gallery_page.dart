import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/cora_transitions.dart';
import '../../../../core/theme/cora_colors.dart';
import '../../../../core/theme/cora_shapes.dart';
import '../../../../core/theme/cora_text_styles.dart';
import '../../../../core/theme/cora_theme.dart';
import '../../../../core/ui/cora_error_view.dart';
import '../../../../core/ui/cora_glass_card.dart';
import '../../../../core/ui/cora_logo.dart';
import '../../../../core/ui/cora_pressable.dart';
import '../../../../core/ui/cora_primary_button.dart';
import '../../../../core/ui/cora_select_card.dart';

/// 개발용 모션 갤러리. 소유자가 실제 기기에서 전환 속도·곡선과 공용 위젯을 보고 승인한다.
///
/// 앱 라우터의 `/dev/motion`(개발 환경 전용)에 있다. 앱과 똑같은 [CoraTransitions] 페이지를
/// 쓰도록 안에 작은 GoRouter를 따로 두고, 라이트·다크 스위치는 이 안의 테마만 바꾼다.
///
/// 안쪽 라우터가 뒤로 가기를 먼저 받는다. [NavigatorPopHandler]가 안쪽에 쌓인 화면이 있는
/// 동안 바깥 경로(`/dev/motion`)의 닫힘을 막고 그 요청을 안쪽으로 돌린다. 그래서 Android
/// 뒤로 가기와 iOS 가장자리 밀기 모두 시연 화면부터 닫고, 갤러리 첫 화면에서만 갤러리를 나간다.
/// (ChildBackButtonDispatcher만 쓰면 Android는 맞지만, iOS에서는 바깥 경로의 밀기 감지가
/// 먼저 이겨 갤러리 전체가 닫힌다.)
class MotionGalleryPage extends StatefulWidget {
  const MotionGalleryPage({super.key});

  @override
  State<MotionGalleryPage> createState() => _MotionGalleryPageState();
}

class _MotionGalleryPageState extends State<MotionGalleryPage> {
  final _themeMode = ValueNotifier(ThemeMode.system);
  final _navigatorKey = GlobalKey<NavigatorState>();

  late final GoRouter _router = GoRouter(
    navigatorKey: _navigatorKey,
    routes: [
      GoRoute(
        path: '/',
        pageBuilder: (context, state) => CoraTransitions.fade(
          _GalleryHome(themeMode: _themeMode),
          key: state.pageKey,
        ),
      ),
      for (final demo in _Demo.values)
        GoRoute(
          path: '/${demo.name}',
          pageBuilder: (context, state) =>
              demo.page(_DemoPage(demo: demo), key: state.pageKey),
        ),
      GoRoute(
        path: '/creator/:id',
        pageBuilder: (context, state) => CoraTransitions.push(
          _CreatorDetailPage(id: int.parse(state.pathParameters['id']!)),
          key: state.pageKey,
        ),
      ),
    ],
  );

  @override
  void dispose() {
    _router.dispose();
    _themeMode.dispose();
    super.dispose();
  }

  // MaterialApp의 themeMode와 같은 규칙. 시스템이면 기기 설정을 따른다.
  // 스위치는 밝기만 바꾼다. 플랫폼(iOS 뒤로 밀기 여부를 정함)은 바깥 테마를 그대로 따른다.
  ThemeData _themeFor(BuildContext context, ThemeMode mode) {
    final dark = switch (mode) {
      ThemeMode.dark => true,
      ThemeMode.light => false,
      ThemeMode.system =>
        MediaQuery.platformBrightnessOf(context) == Brightness.dark,
    };
    return (dark ? coraDarkTheme : coraLightTheme).copyWith(
      platform: Theme.of(context).platform,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: _themeMode,
      builder: (context, mode, child) =>
          AnimatedTheme(data: _themeFor(context, mode), child: child!),
      child: NavigatorPopHandler<Object?>(
        onPopWithResult: (_) => _navigatorKey.currentState?.maybePop(),
        // 두 번째 MaterialApp.router 대신 맨 Router를 둔다. 앱의 MaterialApp은 하나이고,
        // 뒤로 가기는 위의 NavigatorPopHandler가 안쪽으로 넘긴다(두 번째 루트 dispatcher 없음).
        // 공유 요소 전환의 HeroController는 go_router가 자기 Navigator에 따로 붙인다.
        child: Router(
          routerDelegate: _router.routerDelegate,
          routeInformationParser: _router.routeInformationParser,
          routeInformationProvider: _router.routeInformationProvider,
        ),
      ),
    );
  }
}

enum _Demo {
  push(
    'push 전환',
    '오른쪽에서 24% 밀려 들어오며 나타나요. 밑의 화면은 왼쪽으로 8% 밀리며 어두워져요. iOS에서는 왼쪽 가장자리를 밀어 돌아갈 수 있어요.',
  ),
  sheet('sheet 전환', '아래에서 올라와요. 뒤 화면은 96%로 줄어들며 어두워져요. 위의 어두운 틈을 누르면 닫혀요.'),
  fade('fade 전환', '제자리에서 나타나요. 탭 전환과 로그인 전후에 써요.');

  const _Demo(this.title, this.description);

  final String title;
  final String description;

  Duration get duration => switch (this) {
    _Demo.push => CoraMotion.pushDuration,
    _Demo.sheet => CoraMotion.sheetDuration,
    _Demo.fade => CoraMotion.fadeDuration,
  };

  String get spec => '${duration.inMilliseconds}ms · easeOutCubic';

  Page<void> page(Widget child, {LocalKey? key}) => switch (this) {
    _Demo.push => CoraTransitions.push(child, key: key),
    _Demo.sheet => CoraTransitions.sheet(child, key: key),
    _Demo.fade => CoraTransitions.fade(child, key: key),
  };
}

// 캔버스 A1 문구 그대로.
const _roles = [
  (
    overline: '일을 맡기는 쪽',
    title: '가게를 알리고 싶어요',
    subtitle: '식당, 미용실, 공방 같은 동네 가게',
    next: '가게 링크로 시작하기',
  ),
  (
    overline: '일을 맡기는 쪽',
    title: '브랜드 제품을 알리고 싶어요',
    subtitle: '쇼핑몰, 제조사, 브랜드 담당자',
    next: '크리에이터 둘러보기',
  ),
  (
    overline: '일을 하는 쪽',
    title: '콘텐츠를 만들고 싶어요',
    subtitle: '팔로워가 적어도 누구나 시작할 수 있어요',
    next: '내 협업 원칙 정하기',
  ),
];

const _heroCreatorId = 42;

class _GalleryHome extends StatefulWidget {
  const _GalleryHome({required this.themeMode});

  final ValueNotifier<ThemeMode> themeMode;

  @override
  State<_GalleryHome> createState() => _GalleryHomeState();
}

class _GalleryHomeState extends State<_GalleryHome> {
  int _role = 0;
  bool _buttonOn = true;
  int _retries = 0;

  static const _modes = [ThemeMode.system, ThemeMode.light, ThemeMode.dark];

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16, 24, 16, bottom + 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: CoraLogo(),
                ),
              ),
              const SizedBox(height: 28),
              _Inset(
                child: Text(
                  '모션 갤러리',
                  style: CoraTextStyles.title.copyWith(color: c.text),
                ),
              ),
              const SizedBox(height: 8),
              _Inset(
                child: Text(
                  '화면 전환과 공용 위젯을 실제 기기에서 확인하는 개발용 화면이에요.',
                  style: CoraTextStyles.body.copyWith(color: c.textSecondary),
                ),
              ),
              const SizedBox(height: 20),
              ValueListenableBuilder<ThemeMode>(
                valueListenable: widget.themeMode,
                builder: (context, mode, _) => _Segmented(
                  options: const ['시스템', '라이트', '다크'],
                  selected: _modes.indexOf(mode),
                  onChanged: (i) => widget.themeMode.value = _modes[i],
                ),
              ),

              const _SectionLabel('화면 전환'),
              for (final demo in _Demo.values) ...[
                _DemoRow(
                  title: demo.title,
                  subtitle: demo.spec,
                  onTap: () => context.push('/${demo.name}'),
                ),
                const SizedBox(height: 8),
              ],
              _HeroCard(onTap: () => context.push('/creator/$_heroCreatorId')),

              const _SectionLabel('선택 카드 · A1'),
              for (final (i, role) in _roles.indexed) ...[
                if (i > 0) const SizedBox(height: 10),
                CoraSelectCard(
                  overline: role.overline,
                  title: role.title,
                  subtitle: role.subtitle,
                  selected: _role == i,
                  onTap: () => setState(() => _role = i),
                ),
              ],
              const SizedBox(height: 16),
              CoraPrimaryButton(label: _roles[_role].next, onPressed: () {}),

              const _SectionLabel('기본 버튼'),
              _Segmented(
                options: const ['켜짐', '꺼짐'],
                selected: _buttonOn ? 0 : 1,
                onChanged: (i) => setState(() => _buttonOn = i == 0),
              ),
              const SizedBox(height: 12),
              CoraPrimaryButton(
                label: '다음',
                onPressed: _buttonOn ? () {} : null,
              ),
              const SizedBox(height: 10),
              const CoraPrimaryButton(label: '다음', onPressed: null),

              const _SectionLabel('유리 카드'),
              const _GlassSample(),

              const _SectionLabel('로고'),
              const _Inset(
                child: Wrap(
                  spacing: 32,
                  runSpacing: 16,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [CoraLogo(), CoraLogo(size: 44)],
                ),
              ),

              const _SectionLabel('오류 화면'),
              DecoratedBox(
                // 실제 오류 화면처럼 `background` 위에 둔다. `surface` 위에서는
                // 보조 버튼 채움(`surfaceMuted`)이 묻혀 보인다.
                decoration: BoxDecoration(
                  color: c.background,
                  border: Border.all(color: c.line),
                  borderRadius: BorderRadius.circular(CoraRadius.xl),
                ),
                child: SizedBox(
                  height: 220,
                  child: CoraErrorView(
                    message: '서버에 연결하지 못했어요.',
                    onRetry: () => setState(() => _retries++),
                  ),
                ),
              ),
              if (_retries > 0) ...[
                const SizedBox(height: 8),
                _Inset(
                  child: Text(
                    '다시 시도를 $_retries번 눌렀어요.',
                    style: CoraTextStyles.caption.copyWith(
                      color: c.textSecondary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// 전환 시연 화면. push, sheet, fade가 같은 화면을 쓰고, 여기서 다시 다른 전환을 겹쳐 볼 수 있다.
class _DemoPage extends StatelessWidget {
  const _DemoPage({required this.demo});

  final _Demo demo;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _TopBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Inset(
                      child: Text(
                        demo.title,
                        style: CoraTextStyles.title.copyWith(color: c.text),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _Inset(
                      child: Text(
                        demo.description,
                        style: CoraTextStyles.body.copyWith(
                          color: c.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    _Inset(
                      child: Text(
                        demo.spec,
                        style: CoraTextStyles.caption.copyWith(
                          color: c.textSecondary,
                        ),
                      ),
                    ),
                    const _SectionLabel('이어서 겹쳐 보기'),
                    for (final next in _Demo.values) ...[
                      _DemoRow(
                        title: '이어서 ${next.name}',
                        subtitle: next.spec,
                        onTap: () => context.push('/${next.name}'),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, bottom + 32),
              child: CoraPrimaryButton(
                label: '닫기',
                onPressed: () => context.pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Hero 시연의 상세 화면. 카드의 사진이 그대로 커지며 이어진다.
class _CreatorDetailPage extends StatelessWidget {
  const _CreatorDetailPage({required this.id});

  final int id;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _TopBar(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: AspectRatio(
                aspectRatio: 1,
                child: Hero(
                  tag: CoraHeroTag.of('creator', id),
                  child: const _DemoPhoto(),
                ),
              ),
            ),
            const SizedBox(height: 24),
            _Inset(
              padding: 24,
              child: Text(
                '크리에이터 $id',
                style: CoraTextStyles.title.copyWith(color: c.text),
              ),
            ),
            const SizedBox(height: 8),
            _Inset(
              padding: 24,
              child: Text(
                '카드의 사진이 상세 화면으로 이어져요. 태그 ${CoraHeroTag.of('creator', id)}',
                style: CoraTextStyles.body.copyWith(color: c.textSecondary),
              ),
            ),
            const Spacer(),
            Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, bottom + 32),
              child: CoraPrimaryButton(
                label: '닫기',
                onPressed: () => context.pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    // 캔버스 Principles 머리: 높이 64, 왼쪽 여백 8, 누르는 칸 44.
    return SizedBox(
      height: 64,
      child: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Semantics(
            button: true,
            label: '뒤로',
            onTap: () => context.pop(),
            child: CoraPressable(
              onTap: () => context.pop(),
              child: SizedBox.square(
                dimension: 44,
                child: ExcludeSemantics(
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 22,
                    color: c.text,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 36, 8, 12),
      child: Semantics(
        header: true,
        child: Text(
          label,
          style: CoraTextStyles.label.copyWith(
            color: context.colors.textSecondary,
          ),
        ),
      ),
    );
  }
}

/// 카드 목록(좌우 16) 안에서 글자만 A1처럼 좌우 24에 맞춘다.
class _Inset extends StatelessWidget {
  const _Inset({required this.child, this.padding = 8});

  final Widget child;
  final double padding;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(horizontal: padding),
    child: child,
  );
}

/// 갤러리 안의 이동 줄. 캔버스 Principles 선택지(높이 56 이상, 모서리 18, `surface`) 모양이다.
class _DemoRow extends StatelessWidget {
  const _DemoRow({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      container: true,
      button: true,
      onTap: onTap,
      child: CoraPressable(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(CoraRadius.lg),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: CoraTextStyles.bodyLarge.copyWith(color: c.text),
                    ),
                    Text(
                      subtitle,
                      style: CoraTextStyles.caption.copyWith(
                        fontWeight: FontWeight.w400,
                        color: c.text.withValues(alpha: c.text.a * 0.75),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ExcludeSemantics(
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: c.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      container: true,
      button: true,
      onTap: onTap,
      child: CoraPressable(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(CoraRadius.lg),
          ),
          child: Row(
            children: [
              SizedBox.square(
                dimension: 64,
                child: Hero(
                  tag: CoraHeroTag.of('creator', _heroCreatorId),
                  child: const _DemoPhoto(),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '공유 요소 전환',
                      style: CoraTextStyles.bodyLarge.copyWith(color: c.text),
                    ),
                    Text(
                      '사진이 상세 화면으로 이어져요 · ${CoraHeroTag.of('creator', _heroCreatorId)}',
                      style: CoraTextStyles.caption.copyWith(
                        fontWeight: FontWeight.w400,
                        color: c.text.withValues(alpha: c.text.a * 0.75),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ExcludeSemantics(
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: c.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 사진 자리. 카드와 상세 화면이 같은 모서리(16)를 써서 날아가는 동안 모양이 튀지 않는다.
class _DemoPhoto extends StatelessWidget {
  const _DemoPhoto();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ClipRRect(
      borderRadius: BorderRadius.circular(CoraRadius.md),
      child: CustomPaint(
        painter: _PhotoPainter(
          base: c.text,
          left: c.background,
          right: c.accent,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _PhotoPainter extends CustomPainter {
  _PhotoPainter({required this.base, required this.left, required this.right});

  final Color base;
  final Color left;
  final Color right;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = base);
    // 로고의 겹친 원을 크게 그린다(viewBox 26 기준 좌표).
    final k = size.shortestSide / 26;
    final center = size.center(Offset.zero) - Offset(13 * k, 13 * k);
    Paint ring(Color color) => Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4 * k;
    canvas.drawCircle(center + Offset(9.5 * k, 13 * k), 5.5 * k, ring(left));
    canvas.drawCircle(center + Offset(16.5 * k, 13 * k), 5.5 * k, ring(right));
  }

  @override
  bool shouldRepaint(_PhotoPainter old) =>
      old.base != base || old.left != left || old.right != right;
}

/// 흐림이 잘 보이도록 무늬 위에 유리 카드를 얹는다. 카드 안은 캔버스 Principles의 머리 부분.
class _GlassSample extends StatelessWidget {
  const _GlassSample();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ClipRRect(
      borderRadius: BorderRadius.circular(CoraRadius.xl),
      child: CustomPaint(
        painter: _TexturePainter(
          base: c.accent,
          stripe: c.text,
          blob: c.background,
          dot: c.onAccent,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: CoraGlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: c.accent,
                        shape: BoxShape.circle,
                      ),
                      child: SizedBox.square(
                        dimension: 36,
                        child: Icon(
                          Icons.check_rounded,
                          size: 20,
                          color: c.onAccent,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '촬영 방식',
                            style: CoraTextStyles.label.copyWith(color: c.text),
                          ),
                          Text(
                            '3 / 7 단계',
                            style: CoraTextStyles.caption.copyWith(
                              fontWeight: FontWeight.w400,
                              color: c.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: SizedBox(
                    height: 4,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ColoredBox(color: c.line),
                        FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: 3 / 7,
                          child: ColoredBox(color: c.text),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  '질문',
                  style: CoraTextStyles.caption.copyWith(color: c.text),
                ),
                const SizedBox(height: 6),
                Text(
                  '얼굴이 나오는\n촬영도 괜찮나요?',
                  style: CoraTextStyles.title.copyWith(color: c.text),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TexturePainter extends CustomPainter {
  _TexturePainter({
    required this.base,
    required this.stripe,
    required this.blob,
    required this.dot,
  });

  final Color base;
  final Color stripe;
  final Color blob;
  final Color dot;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = base);
    // 굵은 사선 줄무늬: 흐림이 없으면 카드 뒤로 또렷하게 비친다.
    final stripePaint = Paint()
      ..color = stripe
      ..strokeWidth = 10;
    for (var x = -size.height; x < size.width; x += 28) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height, 0),
        stripePaint,
      );
    }
    canvas.drawCircle(
      Offset(size.width * 0.82, size.height * 0.2),
      56,
      Paint()..color = blob,
    );
    canvas.drawCircle(
      Offset(size.width * 0.18, size.height * 0.85),
      44,
      Paint()..color = dot,
    );
  }

  @override
  bool shouldRepaint(_TexturePainter old) =>
      old.base != base ||
      old.stripe != stripe ||
      old.blob != blob ||
      old.dot != dot;
}

/// 갤러리 설정용 둘·셋 칸 스위치. 고른 칸은 `surfaceSelected`(선택 카드와 같은 규칙).
class _Segmented extends StatelessWidget {
  const _Segmented({
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final List<String> options;
  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(CoraRadius.pill),
      ),
      child: Row(
        children: [
          for (final (i, option) in options.indexed)
            Expanded(
              child: Semantics(
                container: true,
                button: true,
                selected: i == selected,
                inMutuallyExclusiveGroup: true,
                onTap: () => onChanged(i),
                child: CoraPressable(
                  onTap: () => onChanged(i),
                  child: AnimatedContainer(
                    duration: CoraMotion.resolve(
                      context,
                      CoraMotion.stateDuration,
                    ),
                    curve: CoraMotion.standardCurve,
                    constraints: const BoxConstraints(minHeight: 40),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: i == selected ? c.surfaceSelected : c.surface,
                      borderRadius: BorderRadius.circular(CoraRadius.pill),
                    ),
                    child: AnimatedDefaultTextStyle(
                      duration: CoraMotion.resolve(
                        context,
                        CoraMotion.stateDuration,
                      ),
                      curve: CoraMotion.standardCurve,
                      style: CoraTextStyles.label.copyWith(
                        color: i == selected
                            ? c.onSurfaceSelected
                            : c.textSecondary,
                      ),
                      child: Text(option),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
