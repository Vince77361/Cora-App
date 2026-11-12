import { parseOpsArgs } from './ops-args';

const ID = '11111111-1111-4111-8111-111111111111';
const who = ['--operator', '김운영', '--reason', '확인 후 처리'];

describe('parseOpsArgs', () => {
  it('parses a command with its flags, operator and reason', () => {
    const r = parseOpsArgs([
      'force-payout',
      '--collaboration',
      ID,
      '--amount',
      '30000',
      ...who,
    ]);
    expect(r).toMatchObject({
      ok: true,
      command: {
        spec: { name: 'force-payout' },
        operator: '김운영',
        reason: '확인 후 처리',
        values: { collaboration: ID, amount: 30000 },
      },
    });
  });

  it('accepts --name=value', () => {
    const r = parseOpsArgs([
      'halt',
      `--collaboration=${ID}`,
      '--operator=김운영',
      '--reason=확인',
    ]);
    expect(r.ok).toBe(true);
  });

  it('requires operator and reason for every command except show', () => {
    expect(
      parseOpsArgs(['halt', '--collaboration', ID, '--reason', '확인']),
    ).toMatchObject({
      ok: false,
      error: expect.stringContaining('--operator') as string,
    });
    expect(
      parseOpsArgs(['halt', '--collaboration', ID, '--operator', '김운영']),
    ).toMatchObject({
      ok: false,
      error: expect.stringContaining('--reason') as string,
    });
    expect(
      parseOpsArgs([
        'halt',
        '--collaboration',
        ID,
        '--operator',
        ' ',
        '--reason',
        '확인',
      ]).ok,
    ).toBe(false);
    expect(parseOpsArgs(['show', '--collaboration', ID]).ok).toBe(true);
    // 읽기 전용은 감사 기록을 남기지 않으므로 operator를 받지 않는다.
    expect(parseOpsArgs(['show', '--collaboration', ID, ...who]).ok).toBe(
      false,
    );
  });

  it('rejects unknown commands and options, duplicates and missing values', () => {
    expect(parseOpsArgs([]).ok).toBe(false);
    expect(parseOpsArgs(['drop-table', ...who]).ok).toBe(false);
    expect(
      parseOpsArgs(['halt', '--collaboration', ID, '--force', 'yes', ...who])
        .ok,
    ).toBe(false);
    expect(
      parseOpsArgs([
        'halt',
        '--collaboration',
        ID,
        '--collaboration',
        ID,
        ...who,
      ]).ok,
    ).toBe(false);
    expect(
      parseOpsArgs([
        'halt',
        '--collaboration',
        '--operator',
        '김운영',
        '--reason',
        '확인',
      ]).ok,
    ).toBe(false);
    expect(parseOpsArgs(['halt', ID, ...who]).ok).toBe(false);
  });

  it('validates ids and whole numbers', () => {
    expect(
      parseOpsArgs(['halt', '--collaboration', 'not-a-uuid', ...who]).ok,
    ).toBe(false);
    for (const amount of ['-1', '1.5', '1e3', 'abc', '']) {
      expect(
        parseOpsArgs([
          'force-payout',
          '--collaboration',
          ID,
          '--amount',
          amount,
          ...who,
        ]).ok,
      ).toBe(false);
    }
    expect(
      parseOpsArgs([
        'resume-settlement',
        '--collaboration',
        ID,
        '--views',
        '0',
        ...who,
      ]).ok,
    ).toBe(true);
  });

  it('knows every command of the plan', () => {
    for (const [name, flag] of [
      ['halt', 'collaboration'],
      ['resume', 'collaboration'],
      ['force-refund', 'collaboration'],
      ['retry-payout', 'payout'],
      ['retry-refund', 'refund'],
      ['refund-payment', 'payment'],
    ]) {
      expect(parseOpsArgs([name, `--${flag}`, ID, ...who]).ok).toBe(true);
    }
  });
});
