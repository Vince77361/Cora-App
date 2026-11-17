import 'package:cora/features/negotiation/domain/terms_version.dart';
import 'package:cora/features/negotiation/presentation/terms_text.dart';
import 'package:cora/features/offer_terms/domain/offer_terms.dart' show ViewPay;
import 'package:flutter_test/flutter_test.dart';

import 'fake_negotiation_repository.dart';

void main() {
  test('describes history lines for system, me and the other side', () {
    final first = termsVersion(proposedBy: TermsProposer.system);
    final mine = termsVersion(
      version: 2,
      proposedBy: TermsProposer.creator,
      changedFields: const [TermsField.fee, TermsField.startDate],
    );
    final theirs = termsVersion(
      version: 3,
      proposedBy: TermsProposer.brand,
      changedFields: const [TermsField.revision],
    );

    expect(
      historyLine(first, mine: false, counterpartRoleName: '브랜드'),
      '버전 1 · 브랜드의 최초 제안',
    );
    expect(
      historyLine(mine, mine: true, counterpartRoleName: '브랜드'),
      '버전 2 · 내가 제작비·일정 수정 제안',
    );
    expect(
      historyLine(theirs, mine: false, counterpartRoleName: '브랜드'),
      '버전 3 · 브랜드가 수정 범위 수정 제안',
    );
    expect(
      historyLine(mine, mine: false, counterpartRoleName: '크리에이터'),
      '버전 2 · 크리에이터가 제작비·일정 수정 제안',
    );
  });

  test('names every field the way the history line and the cells do', () {
    expect(
      [for (final f in TermsField.values) fieldName(f)],
      [
        '콘텐츠 제목',
        '제작비',
        '성과 추가',
        '일정',
        '제작물',
        '제품 제공',
        '수정 범위',
        '활용 권한',
        '지급 조건',
      ],
    );
    expect(cellName(TermsField.startDate), '제작 시작');
  });

  test('labels a changed fee with its previous value', () {
    final previous = termsVersion(fee: 300000);

    expect(changedFromLabel(TermsField.fee, previous), '300,000원에서 변경');
    expect(
      changedFromLabel(
        TermsField.startDate,
        termsVersion(startDate: DateTime(2026, 11, 16)),
      ),
      '11월 16일에서 변경',
    );
    expect(changedFromLabel(TermsField.performance, termsVersion()), '없음에서 변경');
  });

  test('shows the max cash as a change only when it differs from the '
      'previous version', () {
    expect(
      maxCashLine(
        termsVersion(version: 2, fee: 350000, previousMaxCash: 300000),
      ),
      '300,000원 → 350,000원',
    );
    expect(
      maxCashLine(
        termsVersion(version: 2, fee: 350000, previousMaxCash: 350000),
      ),
      '350,000원',
    );
    expect(maxCashLine(termsVersion(fee: 350000)), '350,000원');
  });

  test('fills the version numbers into the bottom notice and shortens it for '
      'version 1', () {
    expect(
      versionNotice(2),
      '버전 1에 했던 수락은 버전 2에 적용되지 않아요. 합의 기록과 최종 계약 체결은 별도예요.',
    );
    expect(
      versionNotice(4),
      '버전 3에 했던 수락은 버전 4에 적용되지 않아요. 합의 기록과 최종 계약 체결은 별도예요.',
    );
    expect(versionNotice(1), '합의 기록과 최종 계약 체결은 별도예요.');
  });

  test('labels the performance add-on and the agreement status', () {
    expect(
      performanceLabel(
        termsVersion(
          performance: const ViewPay(ratePerThousand: 2000, cap: 60000),
        ),
      ),
      '1,000회당 2,000원 · 최대 60,000원',
    );
    expect(performanceLabel(termsVersion()), '없음');
    expect(agreementStatus(TermsAgreement.waitingBrand), '브랜드 확인 대기 중');
    expect(agreementStatus(TermsAgreement.waitingCreator), '크리에이터 확인 대기 중');
    expect(agreementStatus(TermsAgreement.none), '양쪽 확인 대기 중');
    expect(agreementStatus(TermsAgreement.agreed), '합의됨');
    expect(confirmLine('나', confirmed: true), '나 · 확인함');
    expect(confirmLine('브랜드', confirmed: false), '브랜드 · 대기');
  });

  test('puts the right particle on the proposal toast and the basis line', () {
    expect(proposedToast(2), '조건 버전 2를 제안했어요.');
    expect(proposedToast(3), '조건 버전 3을 제안했어요.');
    expect(proposalBasis(2), '버전 2를 바탕으로 고쳐요.');
    expect(proposalBasis(3), '버전 3을 바탕으로 고쳐요.');
  });

  test('labels the start date options with the Korean weekday', () {
    expect(startDateOptionLabel(DateTime(2026, 11, 18)), '11월 18일 (수)');
    expect(startDateOptionLabel(DateTime(2026, 11, 22)), '11월 22일 (일)');
    expect(startDateOptionLabel(DateTime(2026, 11, 23)), '11월 23일 (월)');
  });
}
