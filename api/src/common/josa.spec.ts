import { josa } from './josa';

describe('josa', () => {
  it('picks 가 after a vowel and 이 after a final consonant', () => {
    expect(josa('모아 스튜디오', '이/가')).toBe('모아 스튜디오가');
    expect(josa('한그릇 라멘', '이/가')).toBe('한그릇 라멘이');
  });

  it('picks 과 after a final consonant', () => {
    expect(josa('서윤의 작은 취향', '과/와')).toBe('서윤의 작은 취향과');
    expect(josa('모아 스튜디오', '과/와')).toBe('모아 스튜디오와');
  });

  it('picks 은 and 는 by the final consonant', () => {
    expect(josa('라멘', '은/는')).toBe('라멘은');
    expect(josa('카페', '은/는')).toBe('카페는');
  });

  it('reads a trailing number for the particle', () => {
    expect(josa('조건 버전 2', '을/를')).toBe('조건 버전 2를');
    expect(josa('조건 버전 3', '을/를')).toBe('조건 버전 3을');
  });

  it('reads every digit by its Korean name', () => {
    // 영·일·삼·육·칠·팔은 받침이 있고 이·사·오·구는 없다.
    const withFinal = ['0', '1', '3', '6', '7', '8'];
    const without = ['2', '4', '5', '9'];
    for (const d of withFinal) expect(josa(d, '이/가')).toBe(`${d}이`);
    for (const d of without) expect(josa(d, '이/가')).toBe(`${d}가`);
  });

  it('writes both forms after a non-hangul word', () => {
    expect(josa('Cora', '이/가')).toBe('Cora이(가)');
    expect(josa('Cora', '과/와')).toBe('Cora과(와)');
    expect(josa('Cora', '을/를')).toBe('Cora을(를)');
    expect(josa('Cora', '은/는')).toBe('Cora은(는)');
  });
});
