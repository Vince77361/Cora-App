import { ContentFormat } from '@prisma/client';

export interface TrialComparisonInput {
  trial: { monthlyFee: number; postCount: number };
  collaborations: {
    payout: number;
    fee: number;
    format: ContentFormat;
    // 7일 결과(G1)의 배수(31 = 3.1배). 평소 조회수를 읽지 못했거나 조회수를 세지 않은 협업은 null이다.
    multiplierTenths: number | null;
  }[];
}

export interface TrialComparison {
  trialSpent: number;
  coraSpent: number;
  coraCount: number;
  contentByFormat: { format: ContentFormat; count: number }[];
  averageMultiplierTenths: number | null;
}

// 체험단 계약은 석 달 치다("월 금액 × 3").
const TRIAL_MONTHS = 3;

// 형식 목록의 순서가 곧 화면의 줄 순서다.
const FORMAT_ORDER: readonly ContentFormat[] = Object.values(ContentFormat);

// 체험단과 Cora의 석 달을 같은 잣대로 센다. DB와 시각을 모르는 순수 함수다.
// Cora에 든 돈은 크리에이터 지급액과 수수료의 합이고, 평균 배수는 값이 있는 협업만의 평균을 내림한다.
export function compareTrial(input: TrialComparisonInput): TrialComparison {
  const { trial, collaborations } = input;
  const counts = new Map<ContentFormat, number>();
  let coraSpent = 0;
  const multipliers: number[] = [];
  for (const c of collaborations) {
    coraSpent += c.payout + c.fee;
    counts.set(c.format, (counts.get(c.format) ?? 0) + 1);
    if (c.multiplierTenths !== null) multipliers.push(c.multiplierTenths);
  }
  return {
    trialSpent: trial.monthlyFee * TRIAL_MONTHS,
    coraSpent,
    coraCount: collaborations.length,
    contentByFormat: FORMAT_ORDER.filter((f) => counts.has(f)).map(
      (format) => ({
        format,
        count: counts.get(format) ?? 0,
      }),
    ),
    averageMultiplierTenths:
      multipliers.length === 0
        ? null
        : Math.floor(
            multipliers.reduce((a, b) => a + b, 0) / multipliers.length,
          ),
  };
}
