import 'package:cora/core/text/josa.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('picks 가 after a vowel and 이 after a final consonant', () {
    expect(josa('모아 스튜디오', JosaPair.iGa), '모아 스튜디오가');
    expect(josa('하루 한 컵', JosaPair.iGa), '하루 한 컵이');
  });

  test('picks 과 and 와 by the final consonant', () {
    expect(josa('서윤의 작은 취향', JosaPair.gwaWa), '서윤의 작은 취향과');
    expect(josa('모아 스튜디오', JosaPair.gwaWa), '모아 스튜디오와');
  });

  test('picks 은 and 는 by the final consonant', () {
    expect(josa('라멘', JosaPair.eunNeun), '라멘은');
    expect(josa('카페', JosaPair.eunNeun), '카페는');
  });

  test('picks 을 and 를 by the final consonant', () {
    expect(josa('라멘', JosaPair.eulReul), '라멘을');
    expect(josa('카페', JosaPair.eulReul), '카페를');
  });

  test('reads a trailing digit by its Korean name', () {
    // 영·일·삼·육·칠·팔은 받침이 있고 이·사·오·구는 없다.
    for (final d in ['0', '1', '3', '6', '7', '8']) {
      expect(josa('버전 $d', JosaPair.iGa), '버전 $d이');
    }
    for (final d in ['2', '4', '5', '9']) {
      expect(josa('버전 $d', JosaPair.iGa), '버전 $d가');
    }
  });

  test('ignores trailing spaces when picking the form', () {
    expect(josa('라멘 ', JosaPair.eunNeun), '라멘 은');
  });

  test('writes both forms after a word it cannot read', () {
    expect(josa('Cora', JosaPair.iGa), 'Cora이(가)');
    expect(josa('Cora', JosaPair.gwaWa), 'Cora과(와)');
    expect(josa('Cora', JosaPair.eulReul), 'Cora을(를)');
    expect(josa('Cora', JosaPair.eunNeun), 'Cora은(는)');
    expect(josa('', JosaPair.iGa), '이(가)');
  });
}
