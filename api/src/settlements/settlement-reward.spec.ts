import { rewardOf } from './settlement-reward';

const store = {
  id: 's1',
  kind: 'STORE_OFFER' as const,
  terms: {
    format: 'REELS',
    voucherName: null,
    voucherValue: null,
    voucherPeople: null,
    fixedCash: 30000,
    viewRatePerThousand: 2000,
    perViewCap: 60000,
  },
};
const brand = { id: 'b1', kind: 'BRAND_CONTRACT' as const, terms: {} };
const snapshot = (over: Record<string, unknown> = {}) => ({
  version: 2,
  fee: 350000,
  maxCash: 410000,
  pieces: 1,
  format: 'REELS',
  usageRights: 'NONE',
  payoutDays: 14,
  performance: { ratePer1000: 2000, cap: 60000 },
  ...over,
});
const repoWith = (json: unknown) => ({
  findConcludedContractSnapshot: jest.fn().mockResolvedValue(json),
});

describe('rewardOf', () => {
  it('reads a store offer from the terms copy on the collaboration', async () => {
    const repo = repoWith(null);
    await expect(rewardOf(store, repo)).resolves.toEqual({
      fixedCash: 30000,
      viewRatePerThousand: 2000,
      perViewCap: 60000,
    });
    expect(repo.findConcludedContractSnapshot).not.toHaveBeenCalled();
  });

  it('reads a brand contract from the concluded contract snapshot', async () => {
    const repo = repoWith(snapshot());
    await expect(rewardOf(brand, repo)).resolves.toEqual({
      fixedCash: 350000,
      viewRatePerThousand: 2000,
      perViewCap: 60000,
    });
    expect(repo.findConcludedContractSnapshot).toHaveBeenCalledWith(
      'b1',
      undefined,
    );
  });

  it('has no per view reward for a brand contract without a performance bonus', async () => {
    await expect(
      rewardOf(
        brand,
        repoWith(snapshot({ performance: null, maxCash: 350000 })),
      ),
    ).resolves.toEqual({
      fixedCash: 350000,
      viewRatePerThousand: null,
      perViewCap: null,
    });
  });

  it('throws when the brand contract has no readable snapshot', async () => {
    await expect(rewardOf(brand, repoWith(null))).rejects.toThrow();
    await expect(
      rewardOf(brand, repoWith(snapshot({ maxCash: 1 }))),
    ).rejects.toThrow();
  });
});
