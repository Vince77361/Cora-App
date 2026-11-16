import { budgetLeft } from './campaign-budget';

describe('budgetLeft', () => {
  it('reports the whole budget when nothing is secured', () => {
    expect(budgetLeft(1000000, [])).toEqual({ left: 1000000, over: 0 });
  });

  it('subtracts the secured amounts from the budget', () => {
    expect(budgetLeft(1000000, [350000, 200000])).toEqual({
      left: 450000,
      over: 0,
    });
  });

  it('reports zero left and no overrun when the sum equals the budget', () => {
    expect(budgetLeft(500000, [300000, 200000])).toEqual({ left: 0, over: 0 });
  });

  it('reports zero left with the overrun when the sum is over the budget', () => {
    expect(budgetLeft(500000, [300000, 350000])).toEqual({
      left: 0,
      over: 150000,
    });
  });
});
