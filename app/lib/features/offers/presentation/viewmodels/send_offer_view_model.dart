import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../offer_terms/domain/offer_terms.dart';
import '../../../store_home/domain/applicant.dart';
import '../../../store_home/presentation/viewmodels/store_home_view_model.dart';

/// 오퍼를 보낼 크리에이터. 사장님 홈이 읽어 둔 지원자 가운데서 찾는다(사진과 활동 이름이 거기 있다).
/// 홈을 아직 읽는 중이거나 지원자가 아니면 null이다.
final sendOfferApplicantProvider = Provider.autoDispose
    .family<Applicant?, String>((ref, creatorId) {
      final applicants = ref.watch(
        storeHomeViewModelProvider.select((s) => s.value?.applicants),
      );
      if (applicants == null) return null;
      for (final applicant in applicants) {
        if (applicant.creator.userId == creatorId) return applicant;
      }
      return null;
    });

/// 가게에 저장된 기본 조건에서 시작한 처음 값. 기본 조건이 없으면 null이라 3단계가 릴스,
/// 식사권 + 조회수로 시작한다.
OfferTermsInput? initialTermsOf(OfferTerms? defaults) => defaults == null
    ? null
    : OfferTermsInput(
        format: defaults.format,
        rewardType: defaults.rewardType,
        voucherName: defaults.voucherName,
        voucherValue: defaults.voucherValue,
      );
