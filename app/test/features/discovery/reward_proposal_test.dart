import 'package:cora/features/discovery/domain/reward_proposal.dart';
import 'package:cora/features/offer_terms/domain/offer_terms.dart';
import 'package:cora/features/offer_terms/domain/proposal_draft.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('terms become a proposal with the fixed cash as the fee', () {
    final proposal = RewardProposal.fromTerms(
      const OfferTerms(
        format: ContentFormat.reels,
        reward: Reward(
          voucher: BrandProposalTarget.productVoucher,
          fixedCash: 300000,
          viewPay: ViewPay(ratePerThousand: 2000, cap: 60000),
        ),
      ),
    );

    expect(
      proposal,
      const RewardProposal(
        fee: 300000,
        productProvided: true,
        performance: (ratePer1000: 2000, cap: 60000),
      ),
    );
  });

  test('no voucher and no view pay mean no product and no performance', () {
    final proposal = RewardProposal.fromTerms(
      const OfferTerms(
        format: ContentFormat.blog,
        reward: Reward(fixedCash: 100000),
      ),
    );

    expect(proposal, const RewardProposal(fee: 100000, productProvided: false));
  });
}
