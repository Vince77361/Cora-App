import 'dart:math';

import 'package:cora/core/id/uuid_v4.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('makes a version 4 uuid in the canonical shape', () {
    final id = uuidV4();
    expect(
      id,
      matches(
        RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        ),
      ),
    );
  });

  test('does not repeat across many calls', () {
    final ids = {for (var i = 0; i < 1000; i++) uuidV4()};
    expect(ids, hasLength(1000));
  });

  test('is deterministic for a seeded random', () {
    expect(uuidV4(Random(7)), uuidV4(Random(7)));
  });
}
