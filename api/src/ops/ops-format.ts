import { LedgerAccount } from '@prisma/client';
import type { CollaborationSnapshot } from './ops.repository';

const KST_OFFSET_MS = 9 * 60 * 60 * 1000;

// 한국 시간 "2026-11-12 10:00" 모양. 시각을 읽기만 하는 표시 도우미다(현재 시각을 읽지 않는다).
export function kst(date: Date | null): string {
  if (!date) return '-';
  return `${new Date(date.getTime() + KST_OFFSET_MS)
    .toISOString()
    .slice(0, 16)
    .replace('T', ' ')} KST`;
}

const won = (n: number): string => n.toLocaleString('en-US');

const ACCOUNT_ORDER: LedgerAccount[] = [
  'PG_IN',
  'ESCROW',
  'CREATOR_PAYABLE',
  'STORE_REFUND',
  'FEE_REVENUE',
];

// show의 출력. 계좌번호와 예금주는 읽지도 않는다. 협업 조건(terms)과 제출 주소도 싣지 않는다.
export function formatSnapshot(
  snapshot: CollaborationSnapshot,
  balances: Record<LedgerAccount, number>,
  fundingPaymentId: string | null,
): string[] {
  const { collaboration: c } = snapshot;
  const lines = [
    `협업 ${c.id}`,
    `  종류 ${c.kind} / 정산 방식 ${c.settlementMethod}`,
    `  단계 ${c.stage}`,
    `  멈추기 전 단계 ${c.stageBeforeHalt ?? '-'} / 멈춘 사유 ${c.haltedReason ?? '-'}`,
    `  보관 시작 ${kst(c.fundedAt)} / 제출 기한 ${kst(c.submitDueAt)} / 제출 ${kst(c.submittedAt)}`,
    '',
    '장부 잔액 (들어온 합 - 나간 합)',
    ...ACCOUNT_ORDER.map((a) => `  ${a.padEnd(16)} ${won(balances[a])}원`),
    '',
    `결제 ${snapshot.payments.length}건`,
    ...snapshot.payments.map(
      (p) =>
        `  ${p.id} ${p.status} 에스크로 ${won(p.amountEscrow)}원 + 수수료 ${won(p.amountFee)}원${
          p.id === fundingPaymentId ? ' [보관을 시작시킨 결제]' : ''
        }`,
    ),
    `지급 ${snapshot.payouts.length}건`,
    ...snapshot.payouts.map(
      (p) =>
        `  ${p.id} ${p.status} ${won(p.amount)}원 지급일 ${kst(p.scheduledFor)}`,
    ),
    `환급 ${snapshot.refunds.length}건`,
    ...snapshot.refunds.map((r) => `  ${r.id} ${r.status} ${won(r.amount)}원`),
    snapshot.settlement
      ? `정산 조회수 ${snapshot.settlement.finalViews ?? '-'} / 지급 ${won(snapshot.settlement.payoutAmount)}원 / 환급 ${won(snapshot.settlement.refundAmount)}원 (${kst(snapshot.settlement.settledAt)})`
      : '정산 없음',
    `운영 기록 최근 ${snapshot.audits.length}건`,
    ...snapshot.audits.map(
      (a) => `  ${kst(a.createdAt)} ${a.command} ${a.operator}: ${a.reason}`,
    ),
  ];
  return lines;
}
