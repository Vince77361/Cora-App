import 'package:cora/features/auth/data/fake_sign_in_adapter.dart';
import 'package:cora/features/auth/domain/auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late List<({String email, String password})> signIns;
  late FakeSignInAdapter adapter;

  setUp(() {
    signIns = [];
    adapter = FakeSignInAdapter(
      signInDevAccount: ({required email, required password}) async {
        signIns.add((email: email, password: password));
      },
    );
  });

  Matcher invalidCode() => throwsA(
    isA<AuthFailure>().having(
      (e) => e.kind,
      'kind',
      AuthFailureKind.invalidCode,
    ),
  );

  test('the fixed dev code is 000000', () {
    expect(FakeSignInAdapter.devCode, '000000');
  });

  test('requesting a code sends nothing and signs nobody in', () async {
    await adapter.requestPhoneCode('01000000001');

    expect(signIns, isEmpty);
  });

  test('only the fixed code passes for a phone number', () async {
    await expectLater(
      adapter.verifyPhoneCode(phoneDigits: '01000000001', code: '123456'),
      invalidCode(),
    );
    await expectLater(
      adapter.verifyPhoneCode(phoneDigits: '01000000001', code: ''),
      invalidCode(),
    );
    expect(signIns, isEmpty);

    await adapter.verifyPhoneCode(
      phoneDigits: '01000000001',
      code: FakeSignInAdapter.devCode,
    );

    expect(signIns, hasLength(1));
  });

  test(
    'the same phone number always signs in to the same dev account',
    () async {
      for (var i = 0; i < 2; i++) {
        await adapter.verifyPhoneCode(
          phoneDigits: '01000000001',
          code: FakeSignInAdapter.devCode,
        );
      }
      await adapter.verifyPhoneCode(
        phoneDigits: '01000000002',
        code: FakeSignInAdapter.devCode,
      );

      expect(signIns[0], signIns[1]);
      expect(signIns[2].email, isNot(signIns[0].email));
      expect(signIns[2].password, isNot(signIns[0].password));
    },
  );

  test('dev accounts use the reserved dev email domain', () async {
    await adapter.verifyPhoneCode(
      phoneDigits: '01000000001',
      code: FakeSignInAdapter.devCode,
    );
    await adapter.signInWithKakao();
    await adapter.signInWithNaver();

    for (final signIn in signIns) {
      expect(signIn.email, endsWith('@${FakeSignInAdapter.devEmailDomain}'));
      expect(signIn.password.length, greaterThanOrEqualTo(6));
      expect(signIn.password, isNot(signIn.email));
    }
    expect(signIns[0].email, contains('01000000001'));
  });

  test('kakao and naver are fixed, different dev accounts', () async {
    await adapter.signInWithKakao();
    await adapter.signInWithKakao();
    await adapter.signInWithNaver();

    expect(signIns[0], signIns[1]);
    expect(signIns[0].email, startsWith('kakao@'));
    expect(signIns[2].email, startsWith('naver@'));
    expect(signIns[2].email, isNot(signIns[0].email));
  });

  test('only the dev band 010-0000-XXXX is accepted', () async {
    for (final phone in [
      '',
      '0100000000',
      '010000000011',
      '01012342841',
      '01000010000',
      '01100000001',
      '0100000abcd',
      'abc',
    ]) {
      await expectLater(
        adapter.verifyPhoneCode(
          phoneDigits: phone,
          code: FakeSignInAdapter.devCode,
        ),
        // 인증번호가 틀린 것이 아니므로 invalidCode가 아니라 번호 형식 실패다.
        throwsA(
          isA<AuthFailure>()
              .having((e) => e.kind, 'kind', AuthFailureKind.unknown)
              .having((e) => e.code, 'code', 'invalid_phone'),
        ),
        reason: phone,
      );
    }
    expect(signIns, isEmpty);
  });

  test('the seeded dev numbers are accepted', () async {
    for (final phone in ['01000000001', '01000000002', '01000000003']) {
      await adapter.verifyPhoneCode(
        phoneDigits: phone,
        code: FakeSignInAdapter.devCode,
      );
    }
    expect(signIns, hasLength(3));
  });
}
