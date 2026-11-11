import 'dart:async';

import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/gestures.dart' show GestureBinding;
import 'package:flutter/material.dart';

import '../../core/theme/cora_theme.dart';
import 'demo_paths.dart';
import 'demo_router.dart';

/// 모든 화면에서 iOS 가장자리 밀기로 뒤로 갈 수 있게 한다.
const _cupertino = PageTransitionsTheme(
  builders: {
    TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
    TargetPlatform.android: CupertinoPageTransitionsBuilder(),
  },
);

/// 시연에서 라이트·다크를 바꾸는 스위치. 목록 화면의 버튼이 바꾼다.
final ValueNotifier<ThemeMode> demoThemeMode = ValueNotifier(ThemeMode.light);

class DemoApp extends StatelessWidget {
  const DemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: demoThemeMode,
      builder: (context, mode, _) => MaterialApp.router(
        title: 'Cora 시연',
        debugShowCheckedModeBanner: false,
        theme: coraLightTheme.copyWith(pageTransitionsTheme: _cupertino, inputDecorationTheme: const InputDecorationThemeData()),
        darkTheme: coraDarkTheme.copyWith(pageTransitionsTheme: _cupertino, inputDecorationTheme: const InputDecorationThemeData()),
        themeMode: mode,
        routerConfig: demoRouter,
        // 시연 중 목록으로 돌아가는 숨은 길: 화면 어디서나 두 손가락으로 0.6초 누른다.
        // 보이는 요소를 더하지 않고, 손짓 경쟁에 끼지 않는 Listener라 카드·스크롤과 겹치지 않는다.
        builder: (context, child) => _TwoFingerHome(child: child!),
      ),
    );
  }
}

class _TwoFingerHome extends StatefulWidget {
  const _TwoFingerHome({required this.child});

  final Widget child;

  @override
  State<_TwoFingerHome> createState() => _TwoFingerHomeState();
}

class _TwoFingerHomeState extends State<_TwoFingerHome> {
  final Set<int> _down = {};
  Timer? _timer;

  void _update() {
    _timer?.cancel();
    if (_down.length == 2) {
      _timer = Timer(const Duration(milliseconds: 600), () {
        // 손가락이 떨어질 때 아래 화면의 누르기가 실행되지 않게 두 손가락의 손짓을 취소한다.
        for (final p in _down.toList()) {
          GestureBinding.instance.cancelPointer(p);
        }
        _down.clear();
        demoRouter.go(DemoPaths.index);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (e) => setState(() {
        _down.add(e.pointer);
        _update();
      }),
      onPointerUp: (e) => setState(() {
        _down.remove(e.pointer);
        _update();
      }),
      onPointerCancel: (e) => setState(() {
        _down.remove(e.pointer);
        _update();
      }),
      child: widget.child,
    );
  }
}
