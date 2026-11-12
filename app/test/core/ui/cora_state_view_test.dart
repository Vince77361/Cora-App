import 'package:cora/core/theme/cora_colors.dart';
import 'package:cora/core/theme/cora_theme.dart';
import 'package:cora/core/ui/cora_state_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/cora_test_app.dart';

/// 카드 바탕의 색. 카드는 `CoraStateView` 안의 첫 `DecoratedBox`다.
Color _cardColor(WidgetTester tester) {
  final box = tester.widget<DecoratedBox>(
    find
        .descendant(
          of: find.byType(CoraStateView),
          matching: find.byType(DecoratedBox),
        )
        .first,
  );
  return (box.decoration as BoxDecoration).color!;
}

void main() {
  testWidgets('shows the five canvas states with their exact wording', (
    tester,
  ) async {
    Future<void> pump(Widget view) async {
      await tester.pumpWidget(coraTestApp(view));
      await tester.pump();
    }

    await pump(CoraStateView.loading());
    expect(find.text('불러오는 중'), findsOneWidget);

    await pump(CoraStateView.allSeen(onOpenSaved: () {}));
    expect(find.text('오늘 추천을 모두 봤어요'), findsOneWidget);
    expect(find.text('관심과 저장에 담은 후보를 비교해 보세요. 내일 새 추천이 올라와요.'), findsOneWidget);
    expect(find.text('저장한 후보 보기'), findsOneWidget);

    await pump(CoraStateView.loadFailed(onRetry: () {}));
    expect(find.text('영상을 불러오지 못했어요'), findsOneWidget);
    expect(find.text('연결이 불안정해요. 잠시 뒤 다시 시도해 주세요.'), findsOneWidget);
    expect(find.text('다시 시도'), findsOneWidget);

    await pump(
      CoraStateView.empty(
        title: '아직 받은 제안이 없어요',
        description: '포트폴리오를 채우면 가게와 브랜드의 추천에 더 자주 보여요.',
        actionLabel: '콘텐츠 올리기',
        onAction: () {},
      ),
    );
    expect(find.text('아직 받은 제안이 없어요'), findsOneWidget);
    expect(find.text('포트폴리오를 채우면 가게와 브랜드의 추천에 더 자주 보여요.'), findsOneWidget);
    expect(find.text('콘텐츠 올리기'), findsOneWidget);

    await pump(CoraStateView.staleVersion(version: 3, onOpen: () {}));
    expect(find.text('이전 판본이라 수락할 수 없어요'), findsOneWidget);
    expect(find.text('상대가 판본 3을 보냈어요. 바뀐 조건을 확인한 뒤 수락해 주세요.'), findsOneWidget);
    expect(find.text('판본 3 보기'), findsOneWidget);
  });

  testWidgets(
    'puts the version number into the stale version text and button',
    (tester) async {
      await tester.pumpWidget(
        coraTestApp(CoraStateView.staleVersion(version: 12, onOpen: () {})),
      );
      expect(find.textContaining('판본 12을 보냈어요'), findsOneWidget);
      expect(find.text('판본 12 보기'), findsOneWidget);
    },
  );

  testWidgets('shows only a title when the empty state has no description or '
      'action', (tester) async {
    await tester.pumpWidget(
      coraTestApp(CoraStateView.empty(title: '아직 알림이 없어요.')),
    );
    expect(find.text('아직 알림이 없어요.'), findsOneWidget);
    expect(find.byType(GestureDetector), findsNothing);
  });

  testWidgets('calls onRetry from the load failed state', (tester) async {
    var retries = 0;
    await tester.pumpWidget(
      coraTestApp(CoraStateView.loadFailed(onRetry: () => retries++)),
    );
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();
    expect(retries, 1);
  });

  testWidgets('calls the action from the other action states', (tester) async {
    var saved = 0;
    await tester.pumpWidget(
      coraTestApp(CoraStateView.allSeen(onOpenSaved: () => saved++)),
    );
    await tester.tap(find.text('저장한 후보 보기'));
    await tester.pumpAndSettle();
    expect(saved, 1);

    var opened = 0;
    await tester.pumpWidget(
      coraTestApp(
        CoraStateView.staleVersion(version: 3, onOpen: () => opened++),
      ),
    );
    await tester.tap(find.text('판본 3 보기'));
    await tester.pumpAndSettle();
    expect(opened, 1);
  });

  testWidgets('announces loading and failure to screen readers', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(coraTestApp(CoraStateView.loading()));
    expect(
      tester.getSemantics(find.text('불러오는 중')),
      matchesSemantics(label: '불러오는 중', isLiveRegion: true),
    );

    await tester.pumpWidget(
      coraTestApp(
        CoraStateView.loadFailed(title: '사장님 홈을 불러오지 못했어요.', onRetry: () {}),
      ),
    );
    expect(
      tester.getSemantics(find.text('사장님 홈을 불러오지 못했어요.')),
      matchesSemantics(
        label: '사장님 홈을 불러오지 못했어요.\n연결이 불안정해요. 잠시 뒤 다시 시도해 주세요.',
        isLiveRegion: true,
      ),
    );
    expect(
      tester.getSemantics(find.text('다시 시도')),
      matchesSemantics(
        label: '다시 시도',
        isButton: true,
        hasEnabledState: true,
        isEnabled: true,
        hasTapAction: true,
      ),
    );
    semantics.dispose();
  });

  testWidgets('draws each state the same in light and dark tokens', (
    tester,
  ) async {
    final states = <Widget>[
      CoraStateView.loading(),
      CoraStateView.allSeen(onOpenSaved: () {}),
      CoraStateView.loadFailed(onRetry: () {}),
      CoraStateView.empty(title: '아직 받은 제안이 없어요'),
      CoraStateView.staleVersion(version: 3, onOpen: () {}),
    ];
    for (final (theme, colors) in [
      (coraLightTheme, CoraColors.light),
      (coraDarkTheme, CoraColors.dark),
    ]) {
      for (final view in states) {
        await tester.pumpWidget(coraTestApp(view, theme: theme));
        // 테마가 바뀔 때 AnimatedTheme이 색을 섞는 동안을 기다린다.
        await tester.pumpAndSettle();
        // 카드 바탕 `surface`, 글자 `text`·`textSecondary`, 단추 글자 `onChipAction`.
        expect(_cardColor(tester), colors.surface);
        for (final t in tester.widgetList<Text>(find.byType(Text))) {
          final color = t.style!.color;
          expect(
            [
              colors.text,
              colors.textSecondary,
              colors.onChipAction,
            ].contains(color),
            isTrue,
            reason: '"${t.data}" uses $color',
          );
        }
      }
    }
  });

  testWidgets('does not overflow at 1.3x text scale', (tester) async {
    final states = <Widget>[
      CoraStateView.loading(),
      CoraStateView.allSeen(onOpenSaved: () {}),
      CoraStateView.loadFailed(onRetry: () {}),
      CoraStateView.empty(
        title: '아직 받은 제안이 없어요',
        description: '포트폴리오를 채우면 가게와 브랜드의 추천에 더 자주 보여요.',
        actionLabel: '콘텐츠 올리기',
        onAction: () {},
      ),
      CoraStateView.staleVersion(version: 3, onOpen: () {}),
    ];
    for (final theme in [coraLightTheme, coraDarkTheme]) {
      for (final view in states) {
        await tester.pumpWidget(
          coraTestApp(
            view,
            theme: theme,
            textScaler: const TextScaler.linear(1.3),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
      }
    }
  });

  testWidgets('keeps its own size when the page gives it the whole body', (
    tester,
  ) async {
    // 페이지는 `Expanded`로 본문 전체(꽉 찬 제약)를 준다. 카드가 따라 늘어나면 안 된다.
    await tester.pumpWidget(
      MaterialApp(
        theme: coraLightTheme,
        home: Scaffold(
          body: Column(
            children: [
              Expanded(child: CoraStateView.loadFailed(onRetry: () {})),
            ],
          ),
        ),
      ),
    );
    final card = tester.getSize(
      find
          .descendant(
            of: find.byType(CoraStateView),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );
    expect(card.height, lessThan(150));
    // 단추는 글자 너비만큼만 차지한다.
    final chip = tester.getSize(
      find
          .ancestor(of: find.text('다시 시도'), matching: find.byType(Container))
          .first,
    );
    expect(chip.width, lessThan(120));
    expect(chip.height, 36);
    // 카드는 위쪽 끝에 붙는다.
    expect(tester.getTopLeft(find.byType(CoraStateView)).dy, 0);
  });
}
