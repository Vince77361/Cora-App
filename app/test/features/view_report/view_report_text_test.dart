import 'package:cora/features/view_report/domain/view_report.dart';
import 'package:cora/features/view_report/presentation/view_report_text.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_view_report_repository.dart';

void main() {
  test('writes the period, source, formula and cap lines like the canvas', () {
    final report = sampleReport();
    final calc = report.calc!;

    expect(statusLabel(ViewReportStatus.counting), '집계 중');
    expect(statusLabel(ViewReportStatus.unconfirmed), '미확인');
    expect(statusLabel(ViewReportStatus.confirmed), '확인 완료');
    expect(statusLabel(ViewReportStatus.disputed), '이의 제기됨');

    expect(
      periodLabel(report.periodStart, report.periodEnd),
      '11월 4일 – 11월 10일 (7일)',
    );
    expect(sourceLabel(ViewReportSource.connectedAccount), '연결 계정');
    expect(sourceLabel(ViewReportSource.capturePending), '캡처 제출 · 확인 중');
    expect(sourceLabel(ViewReportSource.captureConfirmed), '캡처 제출 · 확인됨');
    expect(viewPayFormula(calc, 12500), '12,500회 × 1,000회당 2,000원 = 25,000원');
    expect(capLine(calc), '60,000원 · 상한 안');
    expect(
      capLine(
        const ViewReportCalc(
          ratePerThousand: 2000,
          cap: 60000,
          capApplied: true,
          fixedCash: 0,
          viewPay: 60000,
          refund: 0,
          payout: 60000,
        ),
      ),
      '60,000원 · 상한 적용',
    );
  });

  test('counts the period days in Korean time, also across the month end', () {
    // 한국 시간 10월 30일 오전 9시 ~ 14일 뒤.
    expect(
      periodLabel(DateTime.utc(2026, 10, 30), DateTime.utc(2026, 11, 13)),
      '10월 30일 – 11월 12일 (14일)',
    );
  });

  test('shortens the post link for the row', () {
    expect(
      postLinkLabel('https://www.instagram.com/p/DAbC123/'),
      'instagram.com/p/DAbC123',
    );
    expect(
      postLinkLabel('http://instagram.com/reel/x'),
      'instagram.com/reel/x',
    );
    expect(
      postLinkLabel('https://www.instagram.com/reel/abc/?views=12500#top'),
      'instagram.com/reel/abc',
    );
  });
}
