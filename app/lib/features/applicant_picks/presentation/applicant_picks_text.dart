import '../../offer_terms/presentation/offer_terms_text.dart';
import '../domain/applicant_pick.dart';

// G2(지원자 추천)의 문구를 만드는 순수 함수들. 문구는 캔버스 NApplicants 그대로다.

/// 머리: `새 지원 5`.
String picksTitle(int totalNew) => '새 지원 $totalNew';

/// 안내. 지원이 3명 이하면 `3명` 자리에 추천된 수가 들어간다.
String picksIntro({required int totalNew, required int picked}) =>
    '지원한 $totalNew명 중 가게와 잘 맞는 $picked명이에요. 팔로워 수는 점수에 넣지 않아요.';

/// 사진 위 알약: `대표 릴스 · 추천 1 / 3`.
String picksChip({required int index, required int total}) =>
    '대표 릴스 · 추천 ${index + 1} / $total';

/// 큰 글자. 한 줄이 있으면 따옴표로 감싸고, 없으면 주로 만드는 콘텐츠를 그대로 보인다. 둘 다 없으면 null.
String? pickPitch(ApplicantPick pick) {
  final pitch = (pick.pitch ?? '').trim();
  if (pitch.isNotEmpty) return '“$pitch”';
  final focus = (pick.creator.contentFocus ?? '').trim();
  return focus.isEmpty ? null : focus;
}

/// 이유: ` · `로 잇는다. 이유가 없으면 null.
String? pickReasons(ApplicantPick pick) {
  final reasons = [
    for (final r in pick.reasons)
      if (r.trim().isNotEmpty) r.trim(),
  ];
  return reasons.isEmpty ? null : reasons.join(' · ');
}

/// 아래 줄: `하루 한 컵 · 성동구 · 팔로워 640`. 팔로워는 연동한 사람만, 구·군이 없으면 시·도를 보인다.
String pickMeta(ApplicantPick pick) {
  final c = pick.creator;
  final sigungu = (c.regionSigungu ?? '').trim();
  final sido = (c.regionSido ?? '').trim();
  final followers = c.followers;
  return [
    c.displayName,
    if (sigungu.isNotEmpty) sigungu else if (sido.isNotEmpty) sido,
    if (followers != null) '팔로워 ${wonExact(followers).replaceAll('원', '')}',
  ].join(' · ');
}
