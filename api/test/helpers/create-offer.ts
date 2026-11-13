import type {
  ContentFormat,
  OfferParty,
  Prisma,
  PrismaClient,
  UsageRights,
} from '@prisma/client';

// 오퍼의 조건은 판본(offer_versions)에 있다. 테스트가 오퍼를 DB에 바로 만들 때는 옛 모양(조건 열을 오퍼에 같이 적은
// 입력)이 읽기 쉬워서, 조건은 판본 1로 나누어 한 번에 만든다. 조건을 안 주면 식사권 릴스 한 편이다.
export interface TestOfferTerms {
  format?: ContentFormat;
  pieces?: number;
  voucherName?: string | null;
  voucherValue?: number | null;
  voucherPeople?: number | null;
  fixedCash?: number;
  viewRatePerThousand?: number | null;
  perViewCap?: number | null;
  usageRights?: UsageRights;
  idea?: string | null;
  principles?: string[];
}

export type TestOfferInput = Omit<
  Prisma.OfferUncheckedCreateInput,
  'latestVersion' | 'turn' | 'initiatedBy' | 'versions'
> &
  TestOfferTerms & {
    turn?: OfferParty;
    initiatedBy?: OfferParty;
  };

type Client = PrismaClient | Prisma.TransactionClient;

export function termsOfInput(input: TestOfferTerms) {
  return {
    format: input.format ?? 'REELS',
    pieces: input.pieces ?? 1,
    voucherName: input.voucherName ?? null,
    voucherValue: input.voucherValue ?? null,
    voucherPeople: input.voucherPeople ?? null,
    fixedCash: input.fixedCash ?? 0,
    viewRatePerThousand: input.viewRatePerThousand ?? null,
    perViewCap: input.perViewCap ?? null,
    usageRights: input.usageRights ?? 'NONE',
    idea: input.idea ?? null,
    principles: input.principles ?? [],
  };
}

// 오퍼와 판본 1을 함께 만든다. 돌려주는 값은 오퍼 행에 판본 1의 조건을 합친 것이다.
export async function createOffer(prisma: Client, input: TestOfferInput) {
  const {
    format,
    pieces,
    voucherName,
    voucherValue,
    voucherPeople,
    fixedCash,
    viewRatePerThousand,
    perViewCap,
    usageRights,
    idea,
    principles,
    turn,
    initiatedBy,
    ...offer
  } = input;
  const terms = termsOfInput({
    format,
    pieces,
    voucherName,
    voucherValue,
    voucherPeople,
    fixedCash,
    viewRatePerThousand,
    perViewCap,
    usageRights,
    idea,
    principles,
  });
  const row = await prisma.offer.create({
    data: {
      ...offer,
      latestVersion: 1,
      turn: turn ?? 'CREATOR',
      initiatedBy: initiatedBy ?? 'STORE',
      versions: {
        create: {
          number: 1,
          authorParty: initiatedBy ?? 'STORE',
          ...terms,
          ...(offer.createdAt ? { createdAt: offer.createdAt } : {}),
        },
      },
    },
  });
  return { ...row, ...terms };
}

// 다음 판본을 DB에 바로 더한다(서버의 판본 내기는 Task 6). 오퍼의 최신 번호와 차례도 함께 맞춘다.
export async function addVersion(
  prisma: Client,
  offerId: string,
  author: OfferParty,
  over: TestOfferTerms = {},
) {
  const offer = await prisma.offer.findUniqueOrThrow({
    where: { id: offerId },
    include: { versions: { orderBy: { number: 'desc' }, take: 1 } },
  });
  const prev = offer.versions[0];
  const number = offer.latestVersion + 1;
  const terms = termsOfInput({
    format: prev.format,
    pieces: prev.pieces,
    voucherName: prev.voucherName,
    voucherValue: prev.voucherValue,
    voucherPeople: prev.voucherPeople,
    fixedCash: prev.fixedCash,
    viewRatePerThousand: prev.viewRatePerThousand,
    perViewCap: prev.perViewCap,
    usageRights: prev.usageRights,
    idea: prev.idea,
    principles: prev.principles,
    ...over,
  });
  await prisma.offerVersion.create({
    data: { offerId, number, authorParty: author, ...terms },
  });
  await prisma.offer.update({
    where: { id: offerId },
    data: {
      latestVersion: number,
      turn: author === 'STORE' ? 'CREATOR' : 'STORE',
    },
  });
  return number;
}
