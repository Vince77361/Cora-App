export type FlagKind = 'uuid' | 'int' | 'text';

export interface FlagSpec {
  name: string;
  kind: FlagKind;
  help: string;
}

export interface CommandSpec {
  name: string;
  summary: string;
  // 읽기 전용 명령(show)만 --operator·--reason을 받지 않는다.
  readOnly?: boolean;
  flags: FlagSpec[];
}

// 모든 돈 정정은 이 명령으로만 한다(DB를 직접 고치지 않는다). 읽기 전용이 아닌 명령은 --operator와 --reason이 필수이고
// ops_audit_logs에 한 줄을 남긴다.
export const COMMAND_SPECS: CommandSpec[] = [
  {
    name: 'halt',
    summary: '돈을 보관 중인 협업을 멈춘다(등록된 작업을 취소한다).',
    flags: [{ name: 'collaboration', kind: 'uuid', help: '협업 id' }],
  },
  {
    name: 'resume',
    summary:
      '멈춘 협업을 멈추기 전 단계로 되돌린다(신고로 멈춘 협업 포함). 정산 중이었다면 정산을 지금 실행하게 올린다.',
    flags: [{ name: 'collaboration', kind: 'uuid', help: '협업 id' }],
  },
  {
    name: 'resume-settlement',
    summary: '조회수를 읽지 못해 멈춘 협업을 주어진 조회수로 정산한다.',
    flags: [
      { name: 'collaboration', kind: 'uuid', help: '협업 id' },
      { name: 'views', kind: 'int', help: '확인한 조회수' },
    ],
  },
  {
    name: 'force-refund',
    summary: '보관 중인 전액과 수수료를 사장님에게 환급하고 REFUNDED로 끝낸다.',
    flags: [{ name: 'collaboration', kind: 'uuid', help: '협업 id' }],
  },
  {
    name: 'force-payout',
    summary:
      '보관액 안에서 amount를 지급하고 남은 금액을 환급한 뒤 SETTLED로 끝낸다.',
    flags: [
      { name: 'collaboration', kind: 'uuid', help: '협업 id' },
      { name: 'amount', kind: 'int', help: '지급액(원, 보관액 이하)' },
    ],
  },
  {
    name: 'retry-payout',
    summary: 'FAILED 지급을 같은 중복 방지 키로 다시 보낸다.',
    flags: [{ name: 'payout', kind: 'uuid', help: '지급 id' }],
  },
  {
    name: 'retry-refund',
    summary: 'PENDING·FAILED 환급을 같은 중복 방지 키로 다시 PG에 보낸다.',
    flags: [{ name: 'refund', kind: 'uuid', help: '환급 id' }],
  },
  {
    name: 'refund-payment',
    summary:
      '협업에 반영되지 못한 승인 결제(늦은 승인, 이중 결제)를 전액 환불한다.',
    flags: [{ name: 'payment', kind: 'uuid', help: '결제 id' }],
  },
  {
    name: 'show',
    summary:
      '협업의 단계, 장부 계정별 잔액, 결제·지급·환급 상태를 보여 준다(읽기 전용).',
    readOnly: true,
    flags: [{ name: 'collaboration', kind: 'uuid', help: '협업 id' }],
  },
];
