import 'dart:io';

import 'package:cora/core/regions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('lists the 17 provinces in the order the server uses', () {
    expect(sidoList, hasLength(17));
    expect(sidoList.first, '서울특별시');
    expect(sidoList.last, '제주특별자치도');
    expect(sidoList.toSet(), hasLength(17));
  });

  test('matches the server SIDO_LIST file when it is next to the app', () {
    final file = File('../api/src/common/regions.ts');
    if (!file.existsSync()) return;
    final server = RegExp(
      r"'([^']+)',",
    ).allMatches(file.readAsStringSync()).map((m) => m.group(1)!).toList();
    expect(sidoList, server);
  });
}
