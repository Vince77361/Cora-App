import 'package:cora/core/navigation/app_routes.dart';
import 'package:cora/features/instagram_connect/domain/instagram_connection.dart';
import 'package:cora/features/offer_terms/domain/offer_terms.dart';
import 'package:cora/features/proposals/domain/counter_proposal_repository.dart';
import 'package:cora/features/proposals/domain/creator_series.dart';
import 'package:cora/features/store_browse/domain/store_detail.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/load_app_fonts.dart';
import '../instagram_connect/fake_instagram_repository.dart';
import '../store_browse/creator_app_harness.dart';
import '../store_browse/fake_store_browse_repository.dart';
import 'fake_counter_proposal_repository.dart';

const _connected = InstagramConnection(handle: 'seoyun', followers: 1200);

Future<void> _openCounter(WidgetTester tester) async {
  await tester.tap(find.text('한그릇 라멘'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('내 방식으로 제안'));
  await tester.pumpAndSettle();
}

/// 시리즈 줄 끝의 `시리즈 추가` 카드(가로로 밀어야 보인다)를 눌러 시트를 연다.
Future<void> _openAddSheet(WidgetTester tester) async {
  await tester.ensureVisible(find.text('시리즈 추가'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('시리즈 추가'));
  await tester.pumpAndSettle();
}

/// F6의 `희망 보상`을 눌러 연 시트에서 고정 현금 알약을 고르고 닫는다.
Future<void> _pickFixedCash(WidgetTester tester, String chip) async {
  await tester.tap(find.text('희망 보상'));
  await tester.pumpAndSettle();
  await tester.tap(find.text(chip));
  await tester.pumpAndSettle();
  await tester.tap(find.text('확인'));
  await tester.pumpAndSettle();
}

Future<void> _review(WidgetTester tester) async {
  await tester.ensureVisible(find.text('검토하고 보내기'));
  await tester.tap(find.text('검토하고 보내기'));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadAppFonts);

  testWidgets('F6 shows the canvas copy with my series', (tester) async {
    final counter = FakeCounterProposalRepository(series: sampleSeries);
    await pumpCreatorApp(tester, counter: counter);
    await _openCounter(tester);

    expect(topPath(tester), '/creator/stores/1/propose');
    expect(find.text('내 방식으로 제안'), findsOneWidget);
    expect(find.text('한그릇 라멘'), findsOneWidget);
    expect(find.text('성수동 · 방문 1회 · 오후 3시 – 5시 촬영 가능'), findsOneWidget);
    expect(
      find.text(
        '가게 조건: 식사권 40,000원 · 2인 + 1,000회당 2,000원, 1인 최대 60,000원 · 추가 부담 없음',
      ),
      findsOneWidget,
    );
    expect(find.text('내 시리즈로 만들기'), findsOneWidget);
    for (final text in [
      '한 그릇 일기',
      '30초 릴스 · 손 중심',
      '동네 점심 지도',
      '카드뉴스 5장',
      '소리로 먹는 집',
      'ASMR 릴스',
      '시리즈 추가',
      '아이디어',
      '희망 보상',
      '식사권 + 조회수 수당',
      '표현 원칙',
      '없음',
      '검토하고 보내기',
    ]) {
      expect(find.text(text), findsOneWidget, reason: text);
    }
    // 시리즈가 있으면 형식 고르기는 없다.
    expect(find.text('쇼츠'), findsNothing);
  });

  testWidgets('F6 lists my series and adds a new one', (tester) async {
    final counter = FakeCounterProposalRepository(series: sampleSeries);
    await pumpCreatorApp(tester, counter: counter);
    await _openCounter(tester);

    await _openAddSheet(tester);
    await tester.enterText(
      find.byKey(const ValueKey<String>('seriesAdd.name')),
      '이 가게의 하루가 넘치는 이름입니다 하나둘셋',
    );
    expect(
      tester
          .widget<TextField>(
            find.byKey(const ValueKey<String>('seriesAdd.name')),
          )
          .controller!
          .text,
      hasLength(20),
    );
    await tester.enterText(
      find.byKey(const ValueKey<String>('seriesAdd.name')),
      '라멘 한 컷',
    );
    await tester.tap(find.text('카드뉴스'));
    await tester.enterText(
      find.byKey(const ValueKey<String>('seriesAdd.note')),
      '컷 하나로 끝',
    );
    await tester.tap(find.text('추가'));
    await tester.pumpAndSettle();

    expect(counter.series, hasLength(4));
    expect(counter.series.last.name, '라멘 한 컷');
    expect(counter.series.last.format, ContentFormat.cardNews);
    expect(counter.series.last.note, '컷 하나로 끝');
    expect(find.text('라멘 한 컷'), findsOneWidget);
    expect(find.text('컷 하나로 끝'), findsOneWidget);
  });

  testWidgets('F6 keeps the series sheet open with the server message', (
    tester,
  ) async {
    final counter = FakeCounterProposalRepository(series: sampleSeries)
      ..failAddSeries = const CounterProposalFailure(
        message: '시리즈는 5개까지 만들 수 있어요.',
      );
    await pumpCreatorApp(tester, counter: counter);
    await _openCounter(tester);

    await _openAddSheet(tester);
    expect(find.text('추가'), findsOneWidget);
    // 이름이 비면 추가할 수 없다.
    await tester.tap(find.text('추가'));
    await tester.pumpAndSettle();
    expect(counter.series, hasLength(3));

    await tester.enterText(
      find.byKey(const ValueKey<String>('seriesAdd.name')),
      '새 시리즈',
    );
    await tester.pump();
    await tester.tap(find.text('추가'));
    await tester.pumpAndSettle();

    expect(find.text('시리즈는 5개까지 만들 수 있어요.'), findsOneWidget);
    expect(find.text('시리즈 추가'), findsWidgets);
  });

  testWidgets('F6 hides the add card at the series limit', (tester) async {
    final counter = FakeCounterProposalRepository(
      series: [
        ...sampleSeries,
        ...sampleSeries
            .take(2)
            .map(
              (s) => CreatorSeries(
                id: '${s.id}-b',
                name: '${s.name} 2',
                format: s.format,
              ),
            ),
      ],
    );
    await pumpCreatorApp(tester, counter: counter);
    await _openCounter(tester);

    expect(find.text('시리즈 추가'), findsNothing);
  });

  testWidgets('F6 shows only the format picker without a series', (
    tester,
  ) async {
    final counter = FakeCounterProposalRepository();
    await pumpCreatorApp(tester, counter: counter);
    await _openCounter(tester);

    for (final format in ['쇼츠', '릴스', '카드뉴스', '블로그 글']) {
      expect(find.text(format), findsOneWidget, reason: format);
    }
    expect(find.text('한 그릇 일기'), findsNothing);

    // 블로그 글은 조회수를 셀 수 없어 조회수 수당이 빠진다.
    expect(find.text('식사권 + 조회수 수당'), findsOneWidget);
    await tester.tap(find.text('블로그 글'));
    await tester.pumpAndSettle();
    expect(find.text('식사권'), findsOneWidget);
    expect(find.text('식사권 + 조회수 수당'), findsNothing);
  });

  testWidgets('F6 limits the idea to 200 characters and the tags to three', (
    tester,
  ) async {
    await pumpCreatorApp(tester);
    await _openCounter(tester);

    final idea = find.byKey(const ValueKey<String>('counter.idea'));
    await tester.enterText(idea, '가' * 250);
    expect(tester.widget<TextField>(idea).controller!.text, hasLength(200));

    await tester.tap(find.text('표현 원칙'));
    await tester.pumpAndSettle();
    final input = find.byKey(const ValueKey<String>('principles.input'));
    for (final tag in ['#얼굴출연없음', '손만', '자막필수']) {
      await tester.enterText(input, tag);
      await tester.pump();
      await tester.tap(find.text('추가'));
      await tester.pumpAndSettle();
    }
    expect(find.text('꼬리표는 3개까지 달 수 있어요.'), findsOneWidget);
    expect(input, findsNothing);
    expect(find.text('#얼굴출연없음  ×'), findsOneWidget);

    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();
    expect(find.text('#얼굴출연없음 #손만 #자막필수'), findsOneWidget);
  });

  testWidgets('F6 limits one tag to ten characters', (tester) async {
    await pumpCreatorApp(tester);
    await _openCounter(tester);

    await tester.tap(find.text('표현 원칙'));
    await tester.pumpAndSettle();
    final input = find.byKey(const ValueKey<String>('principles.input'));
    await tester.enterText(input, '가나다라마바사아자차카');
    expect(tester.widget<TextField>(input).controller!.text, hasLength(10));
  });

  testWidgets('D2 carries the pitch into the idea field of F6', (tester) async {
    await pumpCreatorApp(tester);
    await tester.tap(find.text('한그릇 라멘'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '김 오르는 첫 숟가락을 슬로모션으로');
    await tester.tap(find.text('내 방식으로 제안'));
    await tester.pumpAndSettle();

    final idea = find.byKey(const ValueKey<String>('counter.idea'));
    expect(
      tester.widget<TextField>(idea).controller!.text,
      '김 오르는 첫 숟가락을 슬로모션으로',
    );
  });

  testWidgets('F6 sends a new proposal through F2 as version 2', (
    tester,
  ) async {
    final stores = FakeStoreBrowseRepository();
    final counter = FakeCounterProposalRepository(series: sampleSeries)
      ..afterSend = () {
        // 서버가 방금 낸 제안을 열린 제안으로 돌려준다. 이제 사장님의 답 차례다.
        stores.statuses['1'] = MyApplicationStatus.offered;
        stores.openOffers['1'] = const MyOpenOffer(
          offerId: 'offer-new',
          latestVersion: 2,
          myTurn: false,
        );
      };
    await pumpCreatorApp(
      tester,
      stores: stores,
      counter: counter,
      instagram: FakeInstagramRepository(connection: _connected),
    );
    await tester.tap(find.text('한그릇 라멘'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '첫 숟가락을 슬로모션으로');
    await tester.tap(find.text('내 방식으로 제안'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('동네 점심 지도'));
    await tester.pumpAndSettle();
    await _pickFixedCash(tester, '3만 원');
    // 희망 보상이 가게 조건보다 3만 원 많다.
    expect(find.text('식사권 + 3만 원 + 조회수 수당'), findsOneWidget);
    expect(find.textContaining('가게 부담 +30,000원'), findsOneWidget);

    await _review(tester);
    expect(find.text('3 / 3'), findsOneWidget);
    expect(find.text('카드뉴스 1편 · 3–5장'), findsOneWidget);
    expect(find.text('한그릇 라멘'), findsWidgets);
    // 크리에이터가 내는 제안에는 이용료 문장이 없다.
    expect(
      find.text('보낸다고 합의가 되는 건 아니에요. 상대가 수락하면 그때 결제해요. 보낸 조건은 판본 2로 고정돼요.'),
      findsOneWidget,
    );

    await tester.tap(find.text('이 조건으로 보내기'));
    await tester.pumpAndSettle();

    final sent = counter.sent.single;
    expect(sent.storeId, '1');
    expect(sent.offerId, isNull);
    expect(sent.proposal.seriesId, 's2');
    expect(sent.proposal.idea, '첫 숟가락을 슬로모션으로');
    expect(sent.proposal.terms.format, ContentFormat.cardNews);
    expect(sent.proposal.terms.reward.fixedCash, 30000);
    expect(sent.proposal.terms.reward.viewPay, isNotNull);
    // 가게 상세로 돌아와 안내를 보인다.
    expect(topPath(tester), '/creator/stores/1');
    expect(find.text('제안을 보냈어요.'), findsOneWidget);
    expect(find.text('3 / 3'), findsNothing);
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('제안을 보냈어요.'), findsNothing);
    // 가게 상세를 다시 읽어 사장님의 답을 기다린다.
    expect(find.text('사장님의 답을 기다리고 있어요.'), findsOneWidget);
    expect(find.text('조건 그대로 지원'), findsNothing);
  });

  testWidgets('F6 adds the next version to an open offer when it is my turn', (
    tester,
  ) async {
    final stores = FakeStoreBrowseRepository()
      ..statuses['1'] = MyApplicationStatus.offered
      ..openOffers['1'] = const MyOpenOffer(
        offerId: 'o-1',
        latestVersion: 2,
        myTurn: true,
      );
    final counter = FakeCounterProposalRepository();
    await pumpCreatorApp(
      tester,
      stores: stores,
      counter: counter,
      instagram: FakeInstagramRepository(connection: _connected),
    );
    await _openCounter(tester);
    await _review(tester);

    expect(
      find.text('보낸다고 합의가 되는 건 아니에요. 상대가 수락하면 그때 결제해요. 보낸 조건은 판본 3으로 고정돼요.'),
      findsOneWidget,
    );
    await tester.tap(find.text('이 조건으로 보내기'));
    await tester.pumpAndSettle();

    final sent = counter.sent.single;
    expect(sent.offerId, 'o-1');
    expect(sent.storeId, isNull);
    expect(find.text('제안을 보냈어요.'), findsOneWidget);
  });

  testWidgets('F6 asks for instagram before sending view pay', (tester) async {
    final instagram = FakeInstagramRepository();
    final counter = FakeCounterProposalRepository();
    await pumpCreatorApp(tester, counter: counter, instagram: instagram);
    await _openCounter(tester);
    await _review(tester);

    expect(find.text('인스타그램을 연동하면 수락할 수 있어요'), findsOneWidget);
    expect(find.text('연동하기'), findsOneWidget);
    expect(find.text('이 조건으로 보내기'), findsNothing);

    await tester.tap(find.text('연동하기'));
    await tester.pumpAndSettle();
    expect(find.text('인스타그램을\n연동해 주세요'), findsOneWidget);
    expect(counter.sent, isEmpty);

    // 연동하고 돌아오면 보낼 수 있다.
    instagram.connection = _connected;
    await tester.tap(find.bySemanticsLabel('뒤로'));
    await tester.pumpAndSettle();
    expect(find.text('이 조건으로 보내기'), findsOneWidget);
    expect(find.text('연동하기'), findsNothing);
  });

  testWidgets('F6 sends without instagram when view pay is off', (
    tester,
  ) async {
    final counter = FakeCounterProposalRepository();
    await pumpCreatorApp(
      tester,
      counter: counter,
      instagram: FakeInstagramRepository(),
    );
    await _openCounter(tester);
    await tester.tap(find.text('블로그 글'));
    await tester.pumpAndSettle();
    await _review(tester);

    expect(find.text('연동하기'), findsNothing);
    expect(find.text('이 조건으로 보내기'), findsOneWidget);
  });

  testWidgets('F6 shows the server message when sending fails', (tester) async {
    final counter = FakeCounterProposalRepository()
      ..failSend = const CounterProposalFailure(message: '이미 진행 중인 제안이 있어요.');
    await pumpCreatorApp(
      tester,
      counter: counter,
      instagram: FakeInstagramRepository(connection: _connected),
    );
    await _openCounter(tester);
    await _review(tester);
    await tester.tap(find.text('이 조건으로 보내기'));
    await tester.pumpAndSettle();

    expect(find.text('이미 진행 중인 제안이 있어요.'), findsOneWidget);
    expect(find.text('3 / 3'), findsOneWidget);
  });

  testWidgets('F6 cannot send without any reward', (tester) async {
    await pumpCreatorApp(tester);
    await _openCounter(tester);

    await tester.tap(find.text('희망 보상'));
    await tester.pumpAndSettle();
    // 제공 혜택을 없애고 조회수 수당을 끈다.
    await tester.tap(find.text('식사권 40,000원 · 2인'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('혜택 없음'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('조회수 수당').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();

    expect(find.text('보상을 하나 이상 정해 주세요.'), findsOneWidget);
    expect(
      tester.getSemantics(find.bySemanticsLabel('검토하고 보내기')),
      matchesSemantics(
        label: '검토하고 보내기',
        isButton: true,
        hasEnabledState: true,
        isEnabled: false,
        hasTapAction: false,
      ),
    );
  });

  testWidgets('F6 uses the canvas colors in dark mode', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await pumpCreatorApp(
      tester,
      counter: FakeCounterProposalRepository(series: sampleSeries),
    );
    await _openCounter(tester);

    Color fillOf(String text) {
      final box = tester.widget<DecoratedBox>(
        find
            .ancestor(of: find.text(text), matching: find.byType(DecoratedBox))
            .first,
      );
      return (box.decoration as BoxDecoration).color!;
    }

    // 고른 시리즈 #33363D, 아닌 시리즈와 값 칸 #1C1E22.
    expect(fillOf('한 그릇 일기'), const Color(0xFF33363D));
    expect(fillOf('동네 점심 지도'), const Color(0xFF1C1E22));
    expect(fillOf('희망 보상'), const Color(0xFF1C1E22));
    expect(fillOf('아이디어'), const Color(0xFF1C1E22));
  });

  testWidgets('does not overflow at 1.3x text scale', (tester) async {
    await pumpCreatorApp(
      tester,
      smallPhoneLargeText: true,
      counter: FakeCounterProposalRepository(series: sampleSeries),
    );
    await _openCounter(tester);
    expect(tester.takeException(), isNull);
    expect(find.text('검토하고 보내기'), findsOneWidget);

    await tester.ensureVisible(find.text('희망 보상'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('희망 보상'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows a retry card when my series cannot be read', (
    tester,
  ) async {
    final counter = FakeCounterProposalRepository()..failFetchSeries = true;
    await pumpCreatorApp(tester, counter: counter);
    await _openCounter(tester);

    expect(find.text('제안 화면을 불러오지 못했어요.'), findsOneWidget);
    counter.failFetchSeries = false;
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();
    expect(find.text('검토하고 보내기'), findsOneWidget);
  });

  testWidgets('back returns to the store detail', (tester) async {
    await pumpCreatorApp(tester);
    await _openCounter(tester);
    await tester.tap(find.bySemanticsLabel('뒤로'));
    await tester.pumpAndSettle();
    expect(topPath(tester), AppRoutes.creatorStore('1'));
  });
}
