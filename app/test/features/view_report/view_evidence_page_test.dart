import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cora/core/media/photo_picker.dart';
import 'package:cora/core/network/photo_uploader.dart';
import 'package:cora/core/ui/cora_primary_button.dart';
import 'package:cora/features/view_report/domain/view_report.dart';
import 'package:cora/features/view_report/domain/view_report_repository.dart';
import 'package:cora/features/view_report/presentation/pages/view_evidence_page.dart';
import 'package:cora/features/view_report/presentation/pages/view_report_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_photos.dart';
import '../../support/load_app_fonts.dart';
import 'fake_view_report_repository.dart';
import 'view_report_harness.dart';

/// 1 x 1 PNG. 미리보기가 실제로 그려 볼 수 있는 가장 작은 그림.
final _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
);

FakeViewReportRepository _requested() => FakeViewReportRepository(
  report: sampleReport(
    status: ViewReportStatus.counting,
    views: null,
    withCalc: false,
    canConfirm: false,
    canUploadEvidence: true,
  ),
);

/// F4를 열고 `캡처 올리기`로 올리기 화면까지 간다.
Future<void> _openUpload(
  WidgetTester tester, {
  required FakeViewReportRepository reports,
  FakePhotoPicker? picker,
  FakePhotoUploader? uploader,
  bool smallPhoneLargeText = false,
}) async {
  await pumpCreatorReport(
    tester,
    reports: reports,
    smallPhoneLargeText: smallPhoneLargeText,
    overrides: [
      photoPickerProvider.overrideWithValue(
        picker ??
            FakePhotoPicker(
              next: PickedPhoto(bytes: _png, contentType: 'image/png'),
            ),
      ),
      photoUploaderProvider.overrideWithValue(uploader ?? FakePhotoUploader()),
    ],
  );
  await tester.tap(find.text('캡처 올리기'));
  await tester.pumpAndSettle();
}

CoraPrimaryButton _submitButton(WidgetTester tester) =>
    tester.widget<CoraPrimaryButton>(find.byType(CoraPrimaryButton));

void main() {
  setUpAll(loadAppFonts);

  testWidgets('F4 offers the capture upload when the server asks for it', (
    tester,
  ) async {
    await pumpCreatorReport(tester, reports: _requested());

    expect(find.text('캡처 올리기'), findsOneWidget);
    expect(find.text('이의 제기'), findsOneWidget);
    expect(find.text('자료 확인했어요'), findsNothing);

    await tester.tap(find.text('캡처 올리기'));
    await tester.pumpAndSettle();
    expect(find.byType(ViewEvidencePage), findsOneWidget);
    expect(find.text('인사이트 화면을\n캡처해 올려 주세요'), findsOneWidget);
  });

  testWidgets('F4 does not offer the capture upload unless the server asks', (
    tester,
  ) async {
    await pumpCreatorReport(
      tester,
      reports: FakeViewReportRepository(
        report: sampleReport(canConfirm: false),
      ),
    );

    expect(find.text('캡처 올리기'), findsNothing);
  });

  testWidgets('uploads a capture with a view count and shows it as pending', (
    tester,
  ) async {
    final reports = _requested();
    final uploader = FakePhotoUploader()..path = 'evidence/user-1/capture.png';
    await _openUpload(tester, reports: reports, uploader: uploader);

    // 사진과 조회수가 모두 있어야 올릴 수 있다.
    expect(_submitButton(tester).onPressed, isNull);
    await tester.tap(find.text('사진 고르기'));
    await tester.pumpAndSettle();
    expect(find.text('사진 바꾸기'), findsOneWidget);
    expect(_submitButton(tester).onPressed, isNull);
    await tester.enterText(find.byType(TextField), '9000');
    await tester.pump();
    expect(_submitButton(tester).onPressed, isNotNull);

    await tester.tap(find.text('올리기'));
    await tester.pumpAndSettle();

    expect(uploader.lastPurpose, PhotoPurpose.viewEvidence);
    expect(uploader.lastContentType, 'image/png');
    expect(reports.evidence.single.path, 'evidence/user-1/capture.png');
    expect(reports.evidence.single.views, 9000);
    // F4로 돌아오고, 자료 출처가 캡처 제출 · 확인 중이다.
    expect(find.byType(ViewReportPage), findsOneWidget);
    expect(find.byType(ViewEvidencePage), findsNothing);
    expect(find.text('캡처 제출 · 확인 중'), findsOneWidget);
    expect(find.text('9,000회'), findsOneWidget);
    expect(find.text('캡처 올리기'), findsNothing);
  });

  testWidgets('does not submit when the photo upload fails', (tester) async {
    final reports = _requested();
    final uploader = FakePhotoUploader()..fail = true;
    await _openUpload(tester, reports: reports, uploader: uploader);

    await tester.tap(find.text('사진 고르기'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '9000');
    await tester.pump();
    await tester.tap(find.text('올리기'));
    await tester.pumpAndSettle();

    expect(reports.evidence, isEmpty);
    expect(find.text('올리지 못했어요. 다시 시도해 주세요.'), findsOneWidget);
    // 입력은 그대로라 다시 시도할 수 있다.
    expect(find.byType(ViewEvidencePage), findsOneWidget);
    expect(_submitButton(tester).onPressed, isNotNull);
  });

  testWidgets('shows the server message when the submission is refused', (
    tester,
  ) async {
    final reports = _requested();
    reports.failAction = const ViewReportFailure(
      conflict: true,
      message: '올린 파일을 찾을 수 없어요.',
    );
    await _openUpload(tester, reports: reports);

    await tester.tap(find.text('사진 고르기'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '9000');
    await tester.pump();
    await tester.tap(find.text('올리기'));
    await tester.pumpAndSettle();

    expect(find.text('올린 파일을 찾을 수 없어요.'), findsOneWidget);
    expect(find.byType(ViewEvidencePage), findsOneWidget);
  });

  testWidgets('says so when the picked photo is over 5MB', (tester) async {
    final picker = FakePhotoPicker(
      next: PickedPhoto(
        bytes: Uint8List(maxPhotoBytes + 1),
        contentType: 'image/jpeg',
      ),
    );
    await _openUpload(tester, reports: _requested(), picker: picker);

    await tester.tap(find.text('사진 고르기'));
    await tester.pumpAndSettle();

    expect(find.text('사진이 너무 커요. 5MB 이하로 골라 주세요.'), findsOneWidget);
    expect(find.text('사진 고르기'), findsOneWidget);
  });

  testWidgets('keeps the upload disabled while it is in progress', (
    tester,
  ) async {
    final reports = _requested();
    final hold = Completer<void>();
    final uploader = FakePhotoUploader()..hold = hold;
    await _openUpload(tester, reports: reports, uploader: uploader);

    await tester.tap(find.text('사진 고르기'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '9000');
    await tester.pump();
    await tester.tap(find.text('올리기'));
    await tester.pump();

    expect(_submitButton(tester).onPressed, isNull);
    hold.complete();
    await tester.pumpAndSettle();
    expect(reports.evidence.length, 1);
  });

  testWidgets('does not overflow at 1.3x text scale', (tester) async {
    await _openUpload(tester, reports: _requested(), smallPhoneLargeText: true);

    expect(tester.takeException(), isNull);
    expect(find.text('올리기'), findsOneWidget);
  });
}
