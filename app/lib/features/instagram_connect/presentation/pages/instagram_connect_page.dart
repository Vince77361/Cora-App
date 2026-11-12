import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/config/app_config_provider.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/theme/cora_colors.dart';
import '../../../../core/theme/cora_shapes.dart';
import '../../../../core/theme/cora_text_styles.dart';
import '../../../../core/ui/cora_error_view.dart';
import '../../../../core/ui/cora_page_header.dart';
import '../../../../core/ui/cora_primary_button.dart';
import '../viewmodels/instagram_connect_view_model.dart';

/// 인스타그램 연동(캔버스에 없다; 캔버스의 `NInstagram`은 5번 계획의 가져오기 화면이다). 연동해야
/// 조회수를 세고 내 게시물만 제출할 수 있다. 개발 빌드에서는 아이디를 직접 입력하는 가짜 연결 화면이
/// 열리고, 연결되면 `@{아이디} 연동됨`을 보인다.
class InstagramConnectPage extends ConsumerWidget {
  const InstagramConnectPage({super.key});

  static const heading = '인스타그램을\n연동해 주세요';
  static const body = '조회수를 세고, 내 게시물만 제출할 수 있게 해요.';
  static const connect = '인스타그램 연동하기';
  static const loadFailed = '인스타그램 연동 상태를 불러오지 못했어요.';

  static String connected(String handle) => '@$handle 연동됨';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final async = ref.watch(instagramConnectViewModelProvider);
    final value = async.value;
    final bottom = math.max(32.0, MediaQuery.viewPaddingOf(context).bottom);
    final config = ref.watch(appConfigProvider);

    void leave() {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(AppRoutes.creatorOffers);
      }
    }

    Future<void> connect() async {
      final vm = ref.read(instagramConnectViewModelProvider.notifier);
      // 개발 빌드는 운영으로 컴파일하면 상수 false로 막혀 가짜 연결 화면으로 가는 코드가 빠진다.
      if (kDevScreensCompiledIn && config.isDev) {
        context.push(AppRoutes.devFakeInstagram);
      } else {
        await vm.begin();
      }
    }

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CoraPageHeader(onBack: leave),
            Expanded(
              child: switch (async) {
                AsyncData(:final value) => SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(
                          InstagramConnectPage.heading,
                          style: CoraTextStyles.headline.copyWith(
                            color: c.text,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        InstagramConnectPage.body,
                        style: CoraTextStyles.body.copyWith(
                          color: c.textSecondary,
                        ),
                      ),
                      if (value.connection != null) ...[
                        const SizedBox(height: 28),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: c.surface,
                            borderRadius: BorderRadius.circular(CoraRadius.xl),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Semantics(
                              liveRegion: true,
                              child: Text(
                                InstagramConnectPage.connected(
                                  value.connection!.handle,
                                ),
                                style: CoraTextStyles.bodyLarge.copyWith(
                                  color: c.text,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                AsyncError() => CoraErrorView(
                  message: InstagramConnectPage.loadFailed,
                  onRetry: () =>
                      ref.invalidate(instagramConnectViewModelProvider),
                ),
                _ => ColoredBox(
                  color: c.background,
                  child: const SizedBox.expand(),
                ),
              },
            ),
            if (value != null && value.connection == null)
              Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, bottom),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (value.error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Semantics(
                          liveRegion: true,
                          child: Text(
                            value.error!,
                            textAlign: TextAlign.center,
                            style: CoraTextStyles.meta.copyWith(color: c.text),
                          ),
                        ),
                      ),
                    CoraPrimaryButton(
                      label: InstagramConnectPage.connect,
                      onPressed: value.busy ? null : connect,
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
