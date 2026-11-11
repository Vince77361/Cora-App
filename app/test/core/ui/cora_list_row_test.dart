import 'package:cora/core/theme/cora_colors.dart';
import 'package:cora/core/theme/cora_theme.dart';
import 'package:cora/core/ui/cora_list_row.dart';
import 'package:cora/core/ui/cora_network_photo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/cora_test_app.dart';

Widget _row({
  String? photoUrl,
  bool highlighted = false,
  VoidCallback? onAction,
  VoidCallback? onTap,
}) => CoraListRow(
  photoUrl: photoUrl,
  title: '하루 한 컵',
  subtitle: '리빙 릴스, 팔로워 640명, 오늘 지원',
  actionLabel: '오퍼 보내기',
  actionHighlighted: highlighted,
  onAction: onAction ?? () {},
  onTap: onTap,
);

Finder _actionBox() =>
    find.ancestor(of: find.text('오퍼 보내기'), matching: find.byType(DecoratedBox));

void main() {
  testWidgets('without a photo shows the first letter in a 46 circle', (
    tester,
  ) async {
    await tester.pumpWidget(coraTestApp(_row()));

    expect(find.text('하'), findsOneWidget);
    expect(find.byType(CoraNetworkPhoto), findsNothing);
    final circle = find.byType(ClipOval);
    expect(tester.getSize(circle), const Size(46, 46));
  });

  testWidgets('with a photo url uses the network photo', (tester) async {
    await tester.pumpWidget(
      coraTestApp(_row(photoUrl: 'http://127.0.0.1:1/a.png')),
    );
    expect(find.byType(CoraNetworkPhoto), findsOneWidget);
    expect(find.text('하'), findsNothing);
  });

  testWidgets('text sizes follow the canvas: 15/500 title, 12 subtitle', (
    tester,
  ) async {
    await tester.pumpWidget(coraTestApp(_row()));

    final title = tester.widget<Text>(find.text('하루 한 컵')).style!;
    expect(title.fontSize, 15);
    expect(title.fontWeight, FontWeight.w500);
    final sub = tester.widget<Text>(find.text('리빙 릴스, 팔로워 640명, 오늘 지원')).style!;
    expect(sub.fontSize, 12);
    expect(sub.color, CoraColors.light.textSecondary);
  });

  testWidgets('action button is 38 tall; highlighted is lime in light', (
    tester,
  ) async {
    await tester.pumpWidget(coraTestApp(_row(highlighted: true)));

    final box = tester.widget<DecoratedBox>(_actionBox().first);
    expect((box.decoration as BoxDecoration).color, const Color(0xFFC6FF3D));
    expect(tester.getSize(_actionBox().first).height, 38);
    final label = tester.widget<Text>(find.text('오퍼 보내기')).style!;
    expect(label.color, const Color(0xFF1F2A00));
    expect(label.fontSize, 13);
    expect(label.fontWeight, FontWeight.w500);
  });

  testWidgets('plain action is surface; dark highlighted is light gray', (
    tester,
  ) async {
    await tester.pumpWidget(coraTestApp(_row()));
    expect(
      (tester.widget<DecoratedBox>(_actionBox().first).decoration
              as BoxDecoration)
          .color,
      const Color(0xFFF8F9FA),
    );

    await tester.pumpWidget(
      coraTestApp(_row(highlighted: true), theme: coraDarkTheme),
    );
    await tester.pumpAndSettle();
    expect(
      (tester.widget<DecoratedBox>(_actionBox().first).decoration
              as BoxDecoration)
          .color,
      const Color(0xFFF2F3F5),
    );
    expect(
      tester.widget<Text>(find.text('오퍼 보내기')).style!.color,
      const Color(0xFF0F1012),
    );
  });

  testWidgets('action and row taps are separate', (tester) async {
    var actions = 0;
    var rows = 0;
    await tester.pumpWidget(
      coraTestApp(_row(onAction: () => actions++, onTap: () => rows++)),
    );

    await tester.tap(find.text('오퍼 보내기'));
    await tester.pumpAndSettle();
    expect((actions, rows), (1, 0));

    await tester.tap(find.text('하루 한 컵'));
    await tester.pumpAndSettle();
    expect((actions, rows), (1, 1));
  });

  testWidgets('row has 12/10 padding and 12 gaps', (tester) async {
    await tester.pumpWidget(
      coraTestApp(
        const SizedBox(
          width: 358,
          child: CoraListRow(
            title: '성수 한 끼',
            subtitle: '맛집 릴스',
            actionLabel: '프로필',
          ),
        ),
      ),
    );
    final row = tester.getRect(find.byType(CoraListRow));
    final circle = tester.getRect(find.byType(ClipOval));
    expect(circle.left - row.left, 12);
    expect(circle.top - row.top, 10);
    final title = tester.getTopLeft(find.text('성수 한 끼'));
    expect(title.dx - circle.right, 12);
  });

  testWidgets('does not overflow at 1.3x text with long text', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      coraTestApp(
        const CoraListRow(
          title: '아주아주아주 긴 크리에이터 이름이에요 정말로',
          subtitle: '라멘 리뷰, 팔로워 1.2만, 2일 전 지원했고 오늘도 새 글이 올라왔어요',
          actionLabel: '오퍼 보내기',
        ),
        textScaler: const TextScaler.linear(1.3),
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
