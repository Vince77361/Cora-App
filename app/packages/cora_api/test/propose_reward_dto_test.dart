//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

import 'package:cora_api/api.dart';
import 'package:test/test.dart';

// tests for ProposeRewardDto
void main() {
  // final instance = ProposeRewardDto();

  group('test ProposeRewardDto', () {
    // 내가 보고 있던 판본 번호. 최신이 아니면 409 STALE_VERSION이다.
    // int baseVersion
    test('to test the property `baseVersion`', () async {
      // TODO
    });

    // 제작비(원). 1만 원 단위, 10000~10000000. 빠지면 그대로.
    // int fee
    test('to test the property `fee`', () async {
      // TODO
    });

    // ContentFormat format
    test('to test the property `format`', () async {
      // TODO
    });

    // 게시 뒤 지급까지 걸리는 날(7 또는 14).
    // int payoutDays
    test('to test the property `payoutDays`', () async {
      // TODO
    });

    // 성과 추가. 빠지면 그대로, null이면 끈다. 블로그 글에는 붙일 수 없다.
    // RewardPerformanceDto performance
    test('to test the property `performance`', () async {
      // TODO
    });

    // int pieces
    test('to test the property `pieces`', () async {
      // TODO
    });

    // 제품 제공 여부. 빠지면 그대로.
    // bool productProvided
    test('to test the property `productProvided`', () async {
      // TODO
    });

    // RevisionScope revisionScope
    test('to test the property `revisionScope`', () async {
      // TODO
    });

    // 제작 시작(YYYY-MM-DD). 바꾸는 값은 한국 시간 오늘 이후.
    // DateTime startDate
    test('to test the property `startDate`', () async {
      // TODO
    });

    // 콘텐츠 제목(1~40자). 빠지면 그대로.
    // String title
    test('to test the property `title`', () async {
      // TODO
    });

    // BrandUsageRights usageRights
    test('to test the property `usageRights`', () async {
      // TODO
    });
  });
}
