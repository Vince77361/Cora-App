import 'package:cora/core/theme/cora_theme.dart';
import 'package:cora/features/auth/domain/current_user_provider.dart';
import 'package:cora/features/offer_terms/domain/offer_terms.dart';
import 'package:cora/features/offer_terms/domain/proposal_draft.dart';
import 'package:cora/features/offer_terms/presentation/pages/reward_budget_page.dart';
import 'package:cora/features/offer_terms/presentation/pages/review_send_page.dart';
import 'package:cora/features/server_config/domain/server_config_repository.dart';
import 'package:cora/features/store_onboarding/domain/my_store.dart';
import 'package:cora/features/store_onboarding/domain/store_repository_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/pump_cora_app.dart';
import '../server_config/fake_server_config_repository.dart';
import '../store_onboarding/fake_store_repository.dart';

/// 서버에 닿지 않은 실패를 흉내 낸다. 화면은 예외의 종류가 아니라 실패했다는 사실만 본다.
class SendFailure implements Exception {
  const SendFailure();
}

/// 보낸 조건을 모으고 원하면 실패하는 [ReviewSendPage.onSend].
class SendRecorder {
  final sent = <OfferTerms>[];
  bool fail = false;

  /// 설정하면 [fail]보다 먼저 이 예외를 던진다(보내는 쪽이 주는 실패 문구를 본다).
  Exception? failure;

  Future<void> call(OfferTerms terms) async {
    sent.add(terms);
    if (failure != null) throw failure!;
    if (fail) throw const SendFailure();
  }
}

/// 가게 이름이 있는 로그인한 사장님. [defaultTerms]가 모집 조건이다(없으면 서버 설정의 기본값에서 시작).
FakeStoreRepository storeWith({
  OfferTerms? defaultTerms,
  String name = '한그릇 라멘',
}) {
  final base = sampleStore(name: name, status: StoreStatus.published);
  return FakeStoreRepository(
    store: MyStore(
      id: base.id,
      status: base.status,
      onboardingStep: StoreOnboardingStep.done,
      industry: base.industry,
      name: base.name,
      defaultTerms: defaultTerms,
    ),
  );
}

enum ProposalStart { budget, review }

/// F1이나 F2를 바로 띄운다. 가게 사장님 계정과 가짜 저장소(서버 설정, 가게)를 끼운다.
Future<void> pumpProposal(
  WidgetTester tester, {
  ProposalStart start = ProposalStart.budget,
  ProposalTarget target = const RecruitTarget(),
  SendRecorder? recorder,
  FakeServerConfigRepository? config,
  FakeStoreRepository? stores,
  bool dark = false,
  double textScale = 1,
}) async {
  usePhone(tester);
  final send = recorder ?? SendRecorder();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        currentUserIdProvider.overrideWithValue('user-1'),
        storeRepositoryProvider.overrideWithValue(stores ?? storeWith()),
        serverConfigRepositoryProvider.overrideWithValue(
          config ?? FakeServerConfigRepository(),
        ),
      ],
      child: MaterialApp(
        theme: dark ? coraDarkTheme : coraLightTheme,
        builder: (context, app) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: app!,
        ),
        home: switch (start) {
          ProposalStart.budget => RewardBudgetPage(
            target: target,
            onSend: send.call,
          ),
          ProposalStart.review => ReviewSendPage(
            target: target,
            onSend: send.call,
          ),
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
}
