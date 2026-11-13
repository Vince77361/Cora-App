import 'package:cora/core/navigation/app_routes.dart';
import 'package:cora/core/ui/cora_state_view.dart';
import 'package:cora/features/collaboration/domain/collaboration.dart';
import 'package:cora/features/collaboration/domain/collaboration_repository.dart';
import 'package:cora/features/instagram_connect/domain/instagram_connection.dart';
import 'package:cora/features/offer_terms/domain/offer_terms.dart';
import 'package:cora/features/offers/domain/offer_view.dart';
import 'package:cora/features/payment/domain/payment_repository.dart';
import 'package:cora/features/proposals/domain/offer_version.dart';
import 'package:cora/features/proposals/domain/proposal.dart';
import 'package:cora/features/proposals/domain/proposal_repository.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import '../../support/load_app_fonts.dart';
import '../../support/pump_cora_app.dart';
import '../collaboration/fake_collaboration_repository.dart';
import '../instagram_connect/fake_instagram_repository.dart';
import '../payment/fake_payment_repository.dart';
import '../store_browse/creator_app_harness.dart' show pumpCreatorApp;
import '../store_browse/fake_store_browse_repository.dart';
import '../store_home/fake_store_home_repository.dart';
import '../store_home/store_home_harness.dart';
import 'fake_counter_proposal_repository.dart';
import 'fake_proposal_repository.dart';

const _storeTerms = OfferTerms(
  format: ContentFormat.reels,
  reward: Reward(
    voucher: Voucher(name: '식사권', value: 40000, people: 2),
    fixedCash: 30000,
    viewPay: ViewPay(ratePerThousand: 2000, cap: 60000),
  ),
);

OfferVersion _v1() => const OfferVersion(
  number: 1,
  authorParty: ProposalParty.store,
  terms: reelsTerms,
);

Future<void> _openStoreDetail(
  WidgetTester tester,
  FakeProposalRepository repo, {
  String id = 'p1',
  FakeStoreHomeRepository? home,
  List<Override> overrides = const [],
}) async {
  await pumpStoreHome(
    tester,
    home: home,
    overrides: [
      proposalRepositoryProvider.overrideWithValue(repo),
      paymentRepositoryProvider.overrideWithValue(FakePaymentRepository()),
      ...overrides,
    ],
  );
  routerOf(tester).push(AppRoutes.storeProposal(id));
  await tester.pumpAndSettle();
}

Future<void> _openCreatorDetail(
  WidgetTester tester,
  FakeProposalRepository repo, {
  FakeInstagramRepository? instagram,
  FakeStoreBrowseRepository? stores,
  FakeCounterProposalRepository? counter,
  FakeCollaborationRepository? collaborations,
  List<Override> overrides = const [],
}) async {
  await pumpCreatorApp(
    tester,
    collaborations: collaborations,
    instagram: instagram ?? FakeInstagramRepository(connection: _connected),
    stores: stores,
    counter: counter,
    overrides: [
      proposalRepositoryProvider.overrideWithValue(repo),
      ...overrides,
    ],
  );
  routerOf(tester).push(AppRoutes.creatorProposal('p1'));
  await tester.pumpAndSettle();
}

const _connected = InstagramConnection(handle: 'seoyun', followers: 1200);

FakeProposalRepository _repo(ProposalDetail detail) =>
    FakeProposalRepository(details: {detail.offerId: detail});

void main() {
  setUpAll(loadAppFonts);

  testWidgets('detail shows the F2 lines with the creator-only lines', (
    tester,
  ) async {
    await _openStoreDetail(tester, _repo(proposalDetail()));

    expect(find.text('판본 2'), findsOneWidget);
    expect(find.text('보낸 사람'), findsOneWidget);
    for (final text in [
      '모집',
      '한그릇 라멘',
      '결과물',
      '릴스 1편 · 30초 안팎',
      '제공 혜택',
      '식사권 40,000원 · 2인',
      '고정 현금',
      '없음',
      '조회수 수당',
      '1,000회당 2,000원 · 1인 최대 60,000원',
      '사용권',
      '가게 계정 재게시 3개월',
      '아이디어',
      '첫 숟가락을 클로즈업해요',
      '표현 원칙',
      '#손만나옴',
      '시리즈',
      '한 그릇 일기 · 30초 릴스 · 손 중심',
      '최대 현금 부담',
      '60,000원',
    ]) {
      expect(find.text(text), findsWidgets, reason: text);
    }
    // 사장님에게는 이용료 문장이 있다.
    expect(find.textContaining('이용료 6,000원은 별도예요.'), findsOneWidget);
    expect(find.textContaining('판본 2로 고정'), findsOneWidget);
  });

  testWidgets(
    'detail leaves the creator lines and the fee out for the creator',
    (tester) async {
      await _openCreatorDetail(
        tester,
        _repo(
          proposalDetail(
            myParty: ProposalParty.creator,
            latest: _v1(),
            group: ProposalGroup.waiting,
          ),
        ),
      );
      // 가게가 쓴 판본에는 아이디어·시리즈 줄이 없고, 크리에이터에게는 수수료 문장도 없다(P15).
      expect(find.text('아이디어'), findsNothing);
      expect(find.text('시리즈'), findsNothing);
      expect(find.text('받는 사람'), findsNothing);
      expect(find.text('보낸 사람'), findsOneWidget);
      expect(find.textContaining('이용료'), findsNothing);
      expect(find.textContaining('판본 1로 고정'), findsOneWidget);
    },
  );

  testWidgets('detail marks the rows that changed from the previous version', (
    tester,
  ) async {
    await _openStoreDetail(
      tester,
      _repo(
        proposalDetail(
          previous: const OfferVersion(
            number: 1,
            authorParty: ProposalParty.store,
            terms: _storeTerms,
          ),
          changed: {ProposalField.fixedCash, ProposalField.idea},
        ),
      ),
    );

    expect(find.text('바뀜'), findsNWidgets(3)); // 고정 현금, 아이디어, 최대 현금 부담
    expect(find.bySemanticsLabel(RegExp(r'^고정 현금, 없음, 바뀜$')), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp(r'^사용권, .*, 바뀜$')), findsNothing);
  });

  testWidgets('detail shows the owner three actions on their turn', (
    tester,
  ) async {
    await _openStoreDetail(tester, _repo(proposalDetail()));

    expect(find.text('이 판본 수락'), findsOneWidget);
    expect(find.text('고쳐서 다시 보내기'), findsOneWidget);
    expect(find.text('제안 종료'), findsOneWidget);
    expect(find.text('제안 취소'), findsNothing);
  });

  testWidgets('detail shows the creator three actions on their turn', (
    tester,
  ) async {
    await _openCreatorDetail(
      tester,
      _repo(proposalDetail(myParty: ProposalParty.creator, latest: _v1())),
    );

    expect(find.text('이 판본 수락'), findsOneWidget);
    expect(find.text('내 방식으로 제안'), findsOneWidget);
    expect(find.text('거절'), findsOneWidget);
    expect(find.textContaining('이용료'), findsNothing);
  });

  testWidgets('detail shows only cancel while waiting and nothing when ended', (
    tester,
  ) async {
    await _openStoreDetail(
      tester,
      _repo(proposalDetail(group: ProposalGroup.waiting)),
    );
    expect(find.text('제안 취소'), findsOneWidget);
    expect(find.text('이 판본 수락'), findsNothing);
    expect(find.text('제안 종료'), findsNothing);
  });

  testWidgets('detail shows no buttons for an ended proposal', (tester) async {
    await _openStoreDetail(
      tester,
      _repo(
        proposalDetail(
          group: ProposalGroup.ended,
          endKind: ProposalEndKind.ended,
          endReason: EndReason.terms,
        ),
      ),
    );
    expect(find.text('조건이 맞지 않아 종료'), findsOneWidget);
    for (final label in ['이 판본 수락', '고쳐서 다시 보내기', '제안 종료', '제안 취소']) {
      expect(find.text(label), findsNothing, reason: label);
    }
  });

  testWidgets('accepting as the owner opens the payment screen', (
    tester,
  ) async {
    final repo = _repo(proposalDetail());
    await _openStoreDetail(tester, repo);

    await tester.tap(find.text('이 판본 수락'));
    await tester.pumpAndSettle();

    expect(repo.accepted, [(offerId: 'p1', version: 2)]);
    expect(topPath(tester), AppRoutes.storePay('collab-1'));
  });

  testWidgets('accepting as the creator says so and opens the collaboration', (
    tester,
  ) async {
    final repo = _repo(
      proposalDetail(myParty: ProposalParty.creator, latest: _v1()),
    );
    await _openCreatorDetail(tester, repo);

    await tester.tap(find.text('이 판본 수락'));
    await tester.pumpAndSettle();
    expect(find.text('수락했어요.'), findsOneWidget);
    expect(find.text('사장님이 결제하면 알려드릴게요.'), findsOneWidget);

    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    expect(topPath(tester), AppRoutes.creatorCollaboration('collab-1'));
  });

  testWidgets('ending asks for one of four reasons', (tester) async {
    final repo = _repo(proposalDetail());
    await _openStoreDetail(tester, repo);

    await tester.tap(find.text('제안 종료'));
    await tester.pumpAndSettle();
    for (final reason in [
      '일정이 맞지 않아요',
      '조건이 맞지 않아요',
      '다른 분과 진행해요',
      '이유 없이 종료',
    ]) {
      expect(find.text(reason), findsOneWidget, reason: reason);
    }
    expect(repo.endedWith, isEmpty);

    repo.afterChange = (id) => repo.details[id] = proposalDetail(
      group: ProposalGroup.ended,
      endKind: ProposalEndKind.ended,
      endReason: EndReason.otherPartner,
    );
    await tester.tap(find.text('다른 분과 진행해요'));
    await tester.pumpAndSettle();

    expect(repo.endedWith, [(offerId: 'p1', reason: EndReason.otherPartner)]);
    expect(find.text('다른 분과 진행해 종료'), findsOneWidget);
    expect(find.text('제안 종료'), findsNothing);
  });

  testWidgets('the creator declines with a reason', (tester) async {
    final repo = _repo(
      proposalDetail(myParty: ProposalParty.creator, latest: _v1()),
    );
    await _openCreatorDetail(tester, repo);
    await tester.tap(find.text('거절'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('일정이 맞지 않아요'));
    await tester.pumpAndSettle();
    expect(repo.endedWith, [(offerId: 'p1', reason: EndReason.schedule)]);
  });

  testWidgets('a waiting owner cancels with a reason', (tester) async {
    final repo = _repo(proposalDetail(group: ProposalGroup.waiting));
    await _openStoreDetail(tester, repo);
    await tester.tap(find.text('제안 취소'));
    await tester.pumpAndSettle();
    expect(find.text('이유를 고르면 바로 끝나요. 끝난 제안은 되돌릴 수 없어요.'), findsOneWidget);
    await tester.tap(find.text('조건이 맞지 않아요'));
    await tester.pumpAndSettle();
    expect(repo.endedWith, [(offerId: 'p1', reason: EndReason.terms)]);
  });

  group('agreed proposal', () {
    ProposalDetail agreed({ProposalParty party = ProposalParty.store}) =>
        proposalDetail(
          myParty: party,
          group: ProposalGroup.ended,
          status: OfferView.accepted,
          endKind: ProposalEndKind.agreed,
          collaborationId: 'col-1',
        );

    List<Override> collab(CollaborationStage stage) => [
      collaborationRepositoryProvider.overrideWithValue(
        FakeCollaborationRepository(
          active: [collaboration(id: 'col-1', stage: stage)],
        ),
      ),
    ];

    testWidgets('the owner can cancel an accepted offer before paying', (
      tester,
    ) async {
      final repo = _repo(agreed());
      repo.afterChange = (id) => repo.details[id] = proposalDetail(
        group: ProposalGroup.ended,
        status: OfferView.cancelled,
        endKind: ProposalEndKind.ended,
      );
      await _openStoreDetail(
        tester,
        repo,
        overrides: collab(CollaborationStage.awaitingPayment),
      );

      expect(find.text('합의 완료 · 계약으로 이동'), findsOneWidget);
      await tester.tap(find.text('오퍼 취소'));
      await tester.pumpAndSettle();
      // 옛 취소 시트 그대로: 조건 요약과 `오퍼 취소`, 누르면 확인 단계.
      expect(find.text('하루 한 컵에게 보낸 오퍼'), findsOneWidget);
      expect(find.text('수락함, 결제를 기다려요'), findsOneWidget);
      expect(find.text('릴스 1편'), findsOneWidget);
      await tester.tap(find.text('오퍼 취소').last);
      await tester.pumpAndSettle();
      expect(find.text('이 오퍼를 취소할까요?'), findsOneWidget);
      expect(find.text('그대로 두기'), findsOneWidget);
      expect(repo.cancelled, isEmpty);

      await tester.tap(find.text('취소하기'));
      await tester.pumpAndSettle();
      expect(repo.cancelled, ['p1']);
      expect(find.text('이 오퍼를 취소할까요?'), findsNothing);
      expect(find.text('오퍼 취소'), findsNothing);
      expect(find.text('종료'), findsOneWidget);
    });

    testWidgets('the cancel sheet status line says how many days are left', (
      tester,
    ) async {
      await _openStoreDetail(
        tester,
        _repo(agreed()),
        home: FakeStoreHomeRepository(
          sent: [
            sentOffer(
              id: 'p1',
              view: OfferView.accepted,
              collaborationId: 'col-1',
              paymentDaysLeft: 3,
            ),
          ],
        ),
        overrides: collab(CollaborationStage.awaitingPayment),
      );

      await tester.tap(find.text('오퍼 취소'));
      await tester.pumpAndSettle();

      expect(find.text('수락함, 결제를 기다려요 · 3일 남음'), findsOneWidget);
    });

    testWidgets(
      'the agreed line is not pressable once the contract is cancelled',
      (tester) async {
        await _openStoreDetail(
          tester,
          _repo(agreed()),
          overrides: collab(CollaborationStage.cancelled),
        );

        expect(find.text('합의 완료 · 계약으로 이동'), findsOneWidget);
        expect(find.text('›'), findsNothing);
        await tester.tap(find.text('합의 완료 · 계약으로 이동'));
        await tester.pumpAndSettle();
        expect(topPath(tester), AppRoutes.storeProposal('p1'));
        // 취소한 계약에는 오퍼 취소도 없다.
        expect(find.text('오퍼 취소'), findsNothing);
      },
    );

    testWidgets('keeps the offer when the owner backs out', (tester) async {
      final repo = _repo(agreed());
      await _openStoreDetail(
        tester,
        repo,
        overrides: collab(CollaborationStage.awaitingPayment),
      );
      await tester.tap(find.text('오퍼 취소'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('오퍼 취소').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('그대로 두기'));
      await tester.pumpAndSettle();
      expect(repo.cancelled, isEmpty);
      expect(find.text('이 오퍼를 취소할까요?'), findsNothing);
      expect(find.text('오퍼 취소'), findsOneWidget);
    });

    testWidgets(
      'says so when the offer was already handled or cancelling fails',
      (tester) async {
        final repo = _repo(agreed())
          ..failCancel = const ProposalFailure(conflict: true);
        await _openStoreDetail(
          tester,
          repo,
          overrides: collab(CollaborationStage.awaitingPayment),
        );
        Future<void> tryCancel() async {
          await tester.tap(find.text('취소하기'));
          await tester.pumpAndSettle();
        }

        await tester.tap(find.text('오퍼 취소'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('오퍼 취소').last);
        await tester.pumpAndSettle();
        await tryCancel();
        expect(find.text('이미 처리된 오퍼예요.'), findsOneWidget);
        expect(find.text('이 오퍼를 취소할까요?'), findsOneWidget);

        repo.failCancel = const ProposalFailure();
        await tryCancel();
        expect(find.text('취소하지 못했어요. 다시 시도해 주세요.'), findsOneWidget);
      },
    );

    testWidgets('there is no cancel once paid, and none for the creator', (
      tester,
    ) async {
      await _openStoreDetail(
        tester,
        _repo(agreed()),
        overrides: collab(CollaborationStage.funded),
      );
      expect(find.text('오퍼 취소'), findsNothing);
      expect(find.text('합의 완료 · 계약으로 이동'), findsOneWidget);
    });

    testWidgets('the creator sees no cancel before payment either', (
      tester,
    ) async {
      await _openCreatorDetail(
        tester,
        _repo(agreed(party: ProposalParty.creator)),
        collaborations: FakeCollaborationRepository(
          active: [
            collaboration(
              id: 'col-1',
              stage: CollaborationStage.awaitingPayment,
            ),
          ],
        ),
      );
      expect(find.text('오퍼 취소'), findsNothing);
    });

    testWidgets(
      'the agreed line opens payment before paying and progress after',
      (tester) async {
        await _openStoreDetail(
          tester,
          _repo(agreed()),
          overrides: collab(CollaborationStage.awaitingPayment),
        );
        await tester.tap(find.text('합의 완료 · 계약으로 이동'));
        await tester.pumpAndSettle();
        expect(topPath(tester), AppRoutes.storePay('col-1'));
      },
    );

    testWidgets('the agreed line opens the progress screen once paid', (
      tester,
    ) async {
      await _openStoreDetail(
        tester,
        _repo(agreed()),
        overrides: collab(CollaborationStage.funded),
      );
      await tester.tap(find.text('합의 완료 · 계약으로 이동'));
      await tester.pumpAndSettle();
      expect(topPath(tester), AppRoutes.storeCollaboration('col-1'));
    });

    testWidgets('the agreed line opens the collaboration for the creator', (
      tester,
    ) async {
      await _openCreatorDetail(
        tester,
        _repo(agreed(party: ProposalParty.creator)),
      );
      await tester.tap(find.text('합의 완료 · 계약으로 이동'));
      await tester.pumpAndSettle();
      expect(topPath(tester), AppRoutes.creatorCollaboration('col-1'));
    });
  });

  testWidgets('shows the server message when ending fails', (tester) async {
    final repo = _repo(proposalDetail())
      ..failEnd = const ProposalFailure(message: '이미 끝난 제안이에요.');
    await _openStoreDetail(tester, repo);
    await tester.tap(find.text('제안 종료'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('이유 없이 종료'));
    await tester.pumpAndSettle();
    expect(find.text('이미 끝난 제안이에요.'), findsOneWidget);
    expect(find.text('제안 종료'), findsOneWidget);
  });

  testWidgets(
    'replying opens F1 with the latest terms and sends the next version',
    (tester) async {
      final repo = _repo(
        proposalDetail(
          latest: const OfferVersion(
            number: 2,
            authorParty: ProposalParty.creator,
            terms: _storeTerms,
            idea: '아이디어',
          ),
        ),
      );
      await _openStoreDetail(tester, repo);

      await tester.tap(find.text('고쳐서 다시 보내기'));
      await tester.pumpAndSettle();
      // F1은 최신 판본의 조건에서 시작한다: 고정 현금 3만 원 + 상한 6만 원 = 최대 현금 부담 90,000원.
      expect(find.text('보상을 정해요.'), findsOneWidget);
      expect(find.text('90,000원'), findsOneWidget);

      await tester.tap(find.text('검토하고 보내기'));
      await tester.pumpAndSettle();
      expect(find.textContaining('판본 3으로 고정되고'), findsOneWidget);
      expect(find.text('하루 한 컵'), findsWidgets);

      await tester.tap(find.text('이 조건으로 보내기'));
      await tester.pumpAndSettle();

      expect(repo.replies, hasLength(1));
      expect(repo.replies.single.offerId, 'p1');
      expect(repo.replies.single.terms.reward.fixedCash, 30000);
      expect(repo.replies.single.terms.format, ContentFormat.reels);
      expect(topPath(tester), AppRoutes.storeProposals);
      expect(find.text('제안을 보냈어요.'), findsOneWidget);
    },
  );

  testWidgets('shows the F2 failure message when replying fails', (
    tester,
  ) async {
    final repo = _repo(proposalDetail())
      ..failReply = const ProposalFailure(conflict: true);
    await _openStoreDetail(tester, repo);
    await tester.tap(find.text('고쳐서 다시 보내기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('검토하고 보내기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('이 조건으로 보내기'));
    await tester.pumpAndSettle();
    expect(find.text('이미 처리된 제안이에요.'), findsOneWidget);
    expect(find.text('이 조건으로 보내기'), findsOneWidget);
  });

  testWidgets(
    'shows the stale version state when the other party sent a newer one',
    (tester) async {
      final repo = _repo(proposalDetail())
        ..failAccept = const ProposalFailure(staleVersion: 3);
      await _openStoreDetail(tester, repo);

      await tester.tap(find.text('이 판본 수락'));
      await tester.pumpAndSettle();
      expect(find.byType(CoraStateView), findsOneWidget);
      expect(find.text('이전 판본이라 수락할 수 없어요'), findsOneWidget);
      expect(find.text('판본 3 보기'), findsOneWidget);

      repo
        ..failAccept = null
        ..details['p1'] = proposalDetail(
          latest: const OfferVersion(
            number: 3,
            authorParty: ProposalParty.creator,
            terms: reelsTerms,
          ),
        );
      await tester.tap(find.text('판본 3 보기'));
      await tester.pumpAndSettle();
      expect(find.text('판본 3'), findsOneWidget);
      expect(find.text('이 판본 수락'), findsOneWidget);
    },
  );

  testWidgets('asks a creator without instagram to connect before accepting', (
    tester,
  ) async {
    final repo = _repo(
      proposalDetail(
        myParty: ProposalParty.creator,
        latest: _v1(),
        needsInstagram: true,
      ),
    );
    await _openCreatorDetail(
      tester,
      repo,
      instagram: FakeInstagramRepository(),
    );

    expect(find.text('인스타그램을 연동하면 수락할 수 있어요'), findsOneWidget);
    expect(find.text('연동하기'), findsOneWidget);
    expect(find.text('이 판본 수락'), findsNothing);
  });

  testWidgets('the creator counters through F6 from the detail', (
    tester,
  ) async {
    final repo = _repo(
      proposalDetail(myParty: ProposalParty.creator, latest: _v1()),
    );
    await _openCreatorDetail(tester, repo);
    await tester.tap(find.text('내 방식으로 제안'));
    await tester.pumpAndSettle();
    expect(topPath(tester), AppRoutes.creatorStoreProposal('1'));
  });

  testWidgets('shows not found for a proposal that is not mine', (
    tester,
  ) async {
    await _openStoreDetail(tester, FakeProposalRepository(), id: 'nope');
    expect(find.text('제안을 찾을 수 없어요.'), findsOneWidget);
  });

  testWidgets('detail does not overflow at 1.3x text scale', (tester) async {
    await pumpStoreHome(
      tester,
      smallPhoneLargeText: true,
      overrides: [
        proposalRepositoryProvider.overrideWithValue(_repo(proposalDetail())),
      ],
    );
    routerOf(tester).push(AppRoutes.storeProposal('p1'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('이 판본 수락'), findsOneWidget);
  });
}
