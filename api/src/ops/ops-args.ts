import { COMMAND_SPECS, CommandSpec } from './commands/command-specs';

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

export interface ParsedOpsCommand {
  spec: CommandSpec;
  operator: string;
  reason: string;
  // 명령별 값. uuid·text는 문자열, int는 숫자다.
  values: Record<string, string | number>;
}

export type ParseResult =
  { ok: true; command: ParsedOpsCommand } | { ok: false; error: string };

// 명령줄(`<명령> --이름 값 ...`)을 읽는다. 서버를 띄우기 전에 부르므로 순수 함수이고, 틀린 입력은 DB에 닿기 전에 거절한다.
// 알 수 없는 옵션, 두 번 준 옵션, 값이 없는 옵션, 형식이 틀린 값, 빠진 필수 옵션(--operator, --reason 포함)은 모두 거절이다.
export function parseOpsArgs(argv: string[]): ParseResult {
  const [name, ...rest] = argv;
  if (!name) return { ok: false, error: '실행할 명령을 적어 주세요.' };
  const spec = COMMAND_SPECS.find((s) => s.name === name);
  if (!spec) return { ok: false, error: `모르는 명령이에요: ${name}` };

  const allowed = new Set([
    ...spec.flags.map((f) => f.name),
    ...(spec.readOnly ? [] : ['operator', 'reason']),
  ]);
  const raw = new Map<string, string>();
  for (let i = 0; i < rest.length; i += 1) {
    const token = rest[i];
    if (!token.startsWith('--')) {
      return { ok: false, error: `옵션이 아니에요: ${token}` };
    }
    const eq = token.indexOf('=');
    const flag = eq === -1 ? token.slice(2) : token.slice(2, eq);
    let value: string | undefined;
    if (eq !== -1) {
      value = token.slice(eq + 1);
    } else if (i + 1 < rest.length && !rest[i + 1].startsWith('--')) {
      value = rest[i + 1];
      i += 1;
    }
    if (!allowed.has(flag)) {
      return {
        ok: false,
        error: `${name}에서 쓸 수 없는 옵션이에요: --${flag}`,
      };
    }
    if (raw.has(flag)) {
      return { ok: false, error: `--${flag}를 두 번 적었어요.` };
    }
    if (value === undefined || value.trim() === '') {
      return { ok: false, error: `--${flag}에 값이 필요해요.` };
    }
    raw.set(flag, value);
  }

  const values: Record<string, string | number> = {};
  for (const flag of spec.flags) {
    const value = raw.get(flag.name);
    if (value === undefined) {
      if (flag.optional) continue;
      return { ok: false, error: `--${flag.name}(${flag.help})가 필요해요.` };
    }
    if (flag.kind === 'uuid' && !UUID.test(value)) {
      return { ok: false, error: `--${flag.name}는 id(UUID) 형식이어야 해요.` };
    }
    if (flag.kind === 'int') {
      if (!/^\d{1,15}$/.test(value)) {
        return {
          ok: false,
          error: `--${flag.name}는 0 이상의 정수여야 해요.`,
        };
      }
      values[flag.name] = Number(value);
    } else {
      values[flag.name] = value;
    }
  }
  if (!spec.readOnly) {
    if (!raw.has('operator')) {
      return { ok: false, error: '--operator(실행한 사람)가 필요해요.' };
    }
    if (!raw.has('reason')) {
      return { ok: false, error: '--reason(사유)이 필요해요.' };
    }
  }
  return {
    ok: true,
    command: {
      spec,
      operator: raw.get('operator') ?? '',
      reason: raw.get('reason') ?? '',
      values,
    },
  };
}

export function usageLines(): string[] {
  return [
    '사용법: yarn ops <명령> [옵션]   (먼저 yarn build)',
    '읽기 전용인 show를 뺀 모든 명령은 --operator <이름> --reason <사유>가 필수이고, 감사 기록을 남긴다.',
    '',
    ...COMMAND_SPECS.flatMap((s) => [
      `  ${s.name} ${[
        ...s.flags.map((f) =>
          f.optional ? `[--${f.name} <${f.help}>]` : `--${f.name} <${f.help}>`,
        ),
        ...(s.readOnly ? [] : ['--operator <이름> --reason <사유>']),
      ].join(' ')}`,
      `      ${s.summary}`,
    ]),
  ];
}
