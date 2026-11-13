import { Collaboration, Payout, Settlement } from '@prisma/client';
import { isMoneyHeld } from '../collaborations/collaboration-stage';
import { readTerms } from '../stores/reward-terms';
import { WalletEntryModel } from './dto/wallet.model';

// 정산 내역의 줄을 만드는 순수 함수. DB와 시각을 모른다(규칙의 원본은 계정·알림·설정 설계 4장).

// 받은 돈이 없는 채로 끝난 협업은 내역에 나오지 않는다.
const LEFT_OUT_STAGES: Collaboration['stage'][] = [
  'CANCELLED',
  'REFUNDED',
  'DROPPED',
];

export interface ReadTerms {
  format: WalletEntryModel['format'];
  // 식사권이 있으면 그 이름(보상에 식사권이 없으면 null).
  voucherName: string | null;
}

export interface WalletInput {
  collaborations: Collaboration[];
  settlements: Map<string, Settlement>;
  payouts: Payout[];
  // 돈이 보관 중인 협업의 ESCROW 잔액(없으면 0).
  escrow: Map<string, number>;
  names: Map<string, string>;
}

// 수락 때 사본으로 남긴 조건에서 형식과 식사권만 읽는다. 읽을 수 없으면 null(그 협업은 내역에서 뺀다).
// 조건을 읽는 규칙은 reward-terms의 readTerms 하나다.
export function readWalletTerms(terms: unknown): ReadTerms | null {
  try {
    const t = readTerms(terms);
    return {
      format: t.format,
      // 식사권 이름이 비어 있어도 보상에 식사권이 있으면(금액이 있으면) 줄은 만든다.
      voucherName: t.voucherName ?? (t.voucherValue !== null ? '식사권' : null),
    };
  } catch {
    return null;
  }
}

interface Group {
  at: Date;
  collaborationId: string;
  rows: WalletEntryModel[];
}

export function buildWalletEntries(input: WalletInput): WalletEntryModel[] {
  const payoutsBy = new Map<string, Payout[]>();
  for (const payout of input.payouts) {
    const list = payoutsBy.get(payout.collaborationId) ?? [];
    list.push(payout);
    payoutsBy.set(payout.collaborationId, list);
  }

  const groups: Group[] = [];
  for (const collaboration of input.collaborations) {
    if (LEFT_OUT_STAGES.includes(collaboration.stage)) continue;
    // 결제 전(오퍼를 수락만 한 상태)에는 보여 줄 돈도 식사권도 없다.
    if (collaboration.stage === 'AWAITING_PAYMENT') continue;
    const terms = readWalletTerms(collaboration.terms);
    if (!terms) continue;

    // 확인 전의 계산(UNCONFIRMED·DISPUTED)은 아직 정산이 아니다: 돈은 협업이 끝날 때까지 "보관 중"으로만 보인다.
    const settlementRow = input.settlements.get(collaboration.id) ?? null;
    const settlement =
      settlementRow?.status === 'CONFIRMED' ? settlementRow : null;
    const base = {
      collaborationId: collaboration.id,
      counterpartName:
        input.names.get(collaboration.id) ??
        (collaboration.kind === 'BRAND_CONTRACT' ? '브랜드' : '가게'),
      format: terms.format,
      pieces: 1,
      stage: collaboration.stage,
    };
    const money: WalletEntryModel[] = [];

    for (const payout of payoutsBy.get(collaboration.id) ?? []) {
      const at =
        payout.status === 'DONE'
          ? // 송금이 끝난 시각. 지급 행은 DONE으로 바뀔 때 말고는 고쳐지지 않는다.
            payout.updatedAt
          : (settlement?.settledAt ?? payout.createdAt);
      money.push({
        ...base,
        kind:
          payout.status === 'DONE'
            ? 'PAYOUT_DONE'
            : payout.status === 'FAILED'
              ? 'PAYOUT_FAILED'
              : 'PAYOUT_SCHEDULED',
        amount: payout.amount,
        views: settlement?.finalViews ?? null,
        voucherName: null,
        voucherUsed: null,
        at: at.toISOString(),
      });
    }

    if (isMoneyHeld(collaboration.kind, collaboration.stage)) {
      const held = input.escrow.get(collaboration.id) ?? 0;
      if (held > 0) {
        money.push({
          ...base,
          kind: 'HELD',
          amount: held,
          views: null,
          voucherName: null,
          voucherUsed: null,
          at: (collaboration.fundedAt ?? collaboration.createdAt).toISOString(),
        });
      }
    }
    money.sort(byAtDesc);

    // 식사권 줄은 돈 줄 바로 아래다. 돈 줄이 없으면(식사권만 있는 협업, 0원 정산) 이 줄만 남는다.
    const groupAt =
      money[0]?.at ??
      (
        settlement?.settledAt ??
        collaboration.fundedAt ??
        collaboration.createdAt
      ).toISOString();
    const rows = [...money];
    if (terms.voucherName !== null) {
      rows.push({
        ...base,
        kind: 'VOUCHER',
        amount: null,
        views: null,
        voucherName: terms.voucherName,
        // 링크 제출(방문했다는 뜻)로 판단한다. 새 확인 절차는 없다.
        voucherUsed: collaboration.submittedAt !== null,
        at: groupAt,
      });
    }
    if (rows.length > 0) {
      groups.push({
        at: new Date(groupAt),
        collaborationId: collaboration.id,
        rows,
      });
    }
  }

  groups.sort(
    (a, b) =>
      b.at.getTime() - a.at.getTime() ||
      b.collaborationId.localeCompare(a.collaborationId),
  );
  return groups.flatMap((g) => g.rows);
}

function byAtDesc(a: WalletEntryModel, b: WalletEntryModel): number {
  return Date.parse(b.at) - Date.parse(a.at);
}
