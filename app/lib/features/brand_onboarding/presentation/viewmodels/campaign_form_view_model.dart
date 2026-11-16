import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/time/clock.dart';
import '../../../../core/time/kst.dart';
import '../../../offer_terms/domain/offer_terms.dart' show ContentFormat;
import '../../../principles/domain/principles.dart' show ProductTrialDays;
import '../../domain/campaign.dart';
import '../../domain/campaign_repository.dart';
import '../brand_onboarding_text.dart';

/// 캠페인 만들기(`false`)와 고치기(`true`)가 한 화면을 같이 쓴다. 화면을 떠나면 입력도 버린다.
final campaignFormViewModelProvider = AsyncNotifierProvider.autoDispose
    .family<CampaignFormViewModel, CampaignFormState, bool>(
      CampaignFormViewModel.new,
    );

/// 캠페인 입력 화면의 상태. 금액은 사용자가 친 글자 그대로 들고, 검사할 때 숫자로 읽는다.
class CampaignFormState {
  const CampaignFormState({
    this.campaignId,
    this.headline = '',
    this.feeText = '',
    this.budgetText = '',
    this.productProvided = false,
    this.format,
    this.startFrom,
    this.initialStartFrom,
    this.today,
    this.trialDays = ProductTrialDays.any,
    this.mustInclude = const ['', '', ''],
    this.notRequired = const {},
    this.saving = false,
    this.error,
  });

  /// 고치는 중인 캠페인. 만드는 중이면 null.
  final String? campaignId;
  final String headline;
  final String feeText;
  final String budgetText;
  final bool productProvided;
  final ContentFormat? format;
  final DateTime? startFrom;

  /// 고치기를 열었을 때의 시작 가능한 날. 이 값을 그대로 두면 오늘보다 앞서도 괜찮다(서버 규칙).
  final DateTime? initialStartFrom;

  /// 한국 시간의 오늘(날짜만). 시작 가능한 날 검사의 기준이다.
  final DateTime? today;
  final ProductTrialDays trialDays;

  /// 꼭 담을 것 세 줄(빈 줄은 보낼 때 뺀다).
  final List<String> mustInclude;
  final Set<NotRequired> notRequired;
  final bool saving;

  /// 서버가 준 사용자 문구 또는 일반 실패 문구.
  final String? error;

  bool get editing => campaignId != null;

  int? get fee => _won(feeText);
  int? get budget => _won(budgetText);

  static int? _won(String text) =>
      text.isEmpty ? null : int.tryParse(text.replaceAll(',', ''));

  bool get feeOk {
    final v = fee;
    return v != null &&
        v >= CampaignRules.feeMin &&
        v <= CampaignRules.feeMax &&
        v % CampaignRules.moneyStep == 0;
  }

  bool get budgetFormatOk {
    final v = budget;
    return v != null &&
        v >= CampaignRules.feeMin &&
        v <= CampaignRules.budgetMax &&
        v % CampaignRules.moneyStep == 0;
  }

  bool get budgetCoversFee => !feeOk || !budgetFormatOk || budget! >= fee!;

  bool get budgetOk => budgetFormatOk && budgetCoversFee;

  /// 시작 가능한 날이 오늘 이후인지. 고치기에서 그대로 둔 날은 따지지 않는다.
  bool get startFromOk {
    final v = startFrom;
    if (v == null) return false;
    if (v == initialStartFrom) return true;
    final t = today;
    return t == null || !v.isBefore(t);
  }

  /// 입력 칸 아래에 보일 검사 문구. 아직 아무것도 치지 않았으면 없다.
  String? get feeError =>
      feeText.isEmpty || feeOk ? null : BrandOnboardingTexts.feeInvalid;

  String? get budgetError {
    if (budgetText.isEmpty) return null;
    if (!budgetFormatOk) return BrandOnboardingTexts.budgetInvalid;
    if (!budgetCoversFee) return BrandOnboardingTexts.budgetBelowFee;
    return null;
  }

  String? get startFromError => startFrom == null || startFromOk
      ? null
      : BrandOnboardingTexts.startFromPast;

  bool get mustIncludeOk => mustInclude.every(
    (line) => line.trim().length <= CampaignRules.mustIncludeLength,
  );

  /// 캠페인 한 줄, 제작비, 캠페인 예산, 형식, 시작 가능한 날이 있어야 한다. 저장 중에는 다시 누르지 못한다.
  bool get canSubmit =>
      headline.trim().isNotEmpty &&
      headline.trim().length <= CampaignRules.headlineMax &&
      feeOk &&
      budgetOk &&
      format != null &&
      startFromOk &&
      mustIncludeOk &&
      !saving;

  CampaignFormState copyWith({
    String? headline,
    String? feeText,
    String? budgetText,
    bool? productProvided,
    ContentFormat? format,
    DateTime? startFrom,
    ProductTrialDays? trialDays,
    List<String>? mustInclude,
    Set<NotRequired>? notRequired,
    bool? saving,
    String? error,
    bool clearError = false,
  }) => CampaignFormState(
    campaignId: campaignId,
    headline: headline ?? this.headline,
    feeText: feeText ?? this.feeText,
    budgetText: budgetText ?? this.budgetText,
    productProvided: productProvided ?? this.productProvided,
    format: format ?? this.format,
    startFrom: startFrom ?? this.startFrom,
    initialStartFrom: initialStartFrom,
    today: today,
    trialDays: trialDays ?? this.trialDays,
    mustInclude: mustInclude ?? this.mustInclude,
    notRequired: notRequired ?? this.notRequired,
    saving: saving ?? this.saving,
    error: clearError ? null : (error ?? this.error),
  );

  CampaignInput toInput() => CampaignInput(
    headline: headline.trim(),
    fee: fee!,
    budget: budget!,
    productProvided: productProvided,
    format: format!,
    startFrom: startFrom!,
    trialDays: trialDays,
    mustInclude: [
      for (final line in mustInclude)
        if (line.trim().isNotEmpty) line.trim(),
    ],
    notRequired: [
      // 화면에 보이는 순서로 보낸다.
      for (final n in NotRequired.values)
        if (notRequired.contains(n)) n,
    ],
  );
}

class CampaignFormViewModel extends AsyncNotifier<CampaignFormState> {
  CampaignFormViewModel(this.editing);

  final bool editing;

  /// 만들기는 빈 입력으로 열고, 고치기는 진행 중인 캠페인의 값으로 연다. 고치기에서 캠페인을 읽지
  /// 못하거나 없으면 오류 상태다.
  @override
  Future<CampaignFormState> build() async {
    final now = ref.read(clockProvider).now();
    final kst = toKst(now);
    final today = DateTime(kst.year, kst.month, kst.day);
    if (!editing) return CampaignFormState(today: today);
    final campaign = await ref.read(campaignRepositoryProvider).fetchMyActive();
    if (campaign == null) throw const CampaignFailure();
    return CampaignFormState(
      campaignId: campaign.id,
      headline: campaign.headline,
      feeText: '${campaign.fee}',
      budgetText: '${campaign.budget}',
      productProvided: campaign.productProvided,
      format: campaign.format,
      startFrom: campaign.startFrom,
      initialStartFrom: campaign.startFrom,
      today: today,
      trialDays: campaign.trialDays,
      mustInclude: [
        for (var i = 0; i < CampaignRules.mustIncludeMax; i++)
          i < campaign.mustInclude.length ? campaign.mustInclude[i] : '',
      ],
      notRequired: campaign.notRequired.toSet(),
    );
  }

  // 입력을 고치면 지난 오류 안내는 지운다.
  void _edit(CampaignFormState Function(CampaignFormState) f) {
    final current = state.value;
    if (current == null || current.saving) return;
    state = AsyncData(f(current).copyWith(clearError: true));
  }

  void setHeadline(String v) => _edit((s) => s.copyWith(headline: v));
  void setFee(String v) => _edit((s) => s.copyWith(feeText: v));
  void setBudget(String v) => _edit((s) => s.copyWith(budgetText: v));
  void setProductProvided(bool v) =>
      _edit((s) => s.copyWith(productProvided: v));
  void setFormat(ContentFormat v) => _edit((s) => s.copyWith(format: v));
  void setStartFrom(DateTime v) =>
      _edit((s) => s.copyWith(startFrom: DateTime(v.year, v.month, v.day)));
  void setTrialDays(ProductTrialDays v) =>
      _edit((s) => s.copyWith(trialDays: v));

  void setMustInclude(int index, String v) => _edit((s) {
    final lines = [...s.mustInclude];
    lines[index] = v;
    return s.copyWith(mustInclude: lines);
  });

  void toggleNotRequired(NotRequired v) => _edit((s) {
    final next = {...s.notRequired};
    next.contains(v) ? next.remove(v) : next.add(v);
    return s.copyWith(notRequired: next);
  });

  /// 캠페인을 만들거나(만들기) 저장한다(고치기). 되면 true. 실패하면 입력을 그대로 두고 false이고,
  /// 서버가 문구를 줬으면 [CampaignFormState.error]에 그대로 담는다.
  Future<bool> submit() async {
    final current = state.value;
    if (current == null || !current.canSubmit) return false;
    state = AsyncData(current.copyWith(saving: true, clearError: true));
    try {
      final repo = ref.read(campaignRepositoryProvider);
      final id = current.campaignId;
      if (id == null) {
        await repo.create(current.toInput());
      } else {
        await repo.update(id, current.toInput());
      }
      if (!ref.mounted) return true;
      state = AsyncData(current.copyWith(saving: false, clearError: true));
      return true;
    } catch (error) {
      if (!ref.mounted) return false;
      state = AsyncData(
        current.copyWith(saving: false, error: _messageFor(error)),
      );
      return false;
    }
  }

  /// 진행 중인 캠페인을 마감한다(고치기에서만). 되면 true.
  Future<bool> close() async {
    final current = state.value;
    final id = current?.campaignId;
    if (current == null || id == null || current.saving) return false;
    state = AsyncData(current.copyWith(saving: true, clearError: true));
    try {
      await ref.read(campaignRepositoryProvider).close(id);
      if (!ref.mounted) return true;
      state = AsyncData(current.copyWith(saving: false, clearError: true));
      return true;
    } catch (error) {
      if (!ref.mounted) return false;
      state = AsyncData(
        current.copyWith(saving: false, error: _messageFor(error)),
      );
      return false;
    }
  }

  static String _messageFor(Object error) {
    final message = error is CampaignFailure ? error.message : null;
    return message == null || message.isEmpty
        ? BrandOnboardingTexts.saveFailed
        : message;
  }
}
