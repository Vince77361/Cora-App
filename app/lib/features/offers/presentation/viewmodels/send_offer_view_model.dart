import 'package:flutter_riverpod/flutter_riverpod.dart';

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
