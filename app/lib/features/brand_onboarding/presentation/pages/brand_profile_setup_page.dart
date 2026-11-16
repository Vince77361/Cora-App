import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../core/theme/cora_colors.dart';
import '../../../../core/theme/cora_text_styles.dart';
import '../../../../core/ui/cora_field_box.dart';
import '../../../../core/ui/cora_primary_button.dart';
import '../../../../core/ui/cora_step_header.dart';
import '../../../store_onboarding/domain/my_store.dart' show IndustryCategory;
import '../../../store_onboarding/presentation/widgets/option_sheet.dart';
import '../brand_onboarding_text.dart';
import '../viewmodels/brand_profile_setup_view_model.dart';
import '../widgets/brand_form_widgets.dart';

/// 브랜드 프로필 만들기. 이 화면은 기획 캔버스에 없다(설계 "브랜드 시작과 캠페인 만들기"). 모양은 같은
/// 계열의 크리에이터 프로필 만들기(제목, 입력 칸, 아래 버튼)를 따른다.
///
/// 브랜드 이름과 업종이 있어야 `다음`이 켜진다. 저장되면 캠페인 만들기로 이어진다.
class BrandProfileSetupPage extends ConsumerStatefulWidget {
  const BrandProfileSetupPage({super.key});

  @visibleForTesting
  static const nameFieldKey = ValueKey<String>('brandProfile.name');
  @visibleForTesting
  static const taglineFieldKey = ValueKey<String>('brandProfile.tagline');
  @visibleForTesting
  static const industryListKey = ValueKey<String>('brandProfile.industryList');

  @override
  ConsumerState<BrandProfileSetupPage> createState() =>
      _BrandProfileSetupPageState();
}

class _BrandProfileSetupPageState extends ConsumerState<BrandProfileSetupPage> {
  final _name = TextEditingController();
  final _tagline = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _tagline.dispose();
    super.dispose();
  }

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      // 첫 화면으로 들어왔으면 쌓인 화면이 없다. 역할을 다시 고를 수 있게 A1로 간다.
      context.go(AppRoutes.role);
    }
  }

  Future<void> _chooseIndustry(IndustryCategory? current) async {
    final picked = await showStoreOptionSheet<IndustryCategory>(
      context,
      title: BrandOnboardingTexts.industryTitle,
      options: IndustryCategory.values,
      labelOf: (c) => c.label,
      selected: current,
      listKey: BrandProfileSetupPage.industryListKey,
    );
    if (picked == null || !mounted) return;
    ref.read(brandProfileSetupViewModelProvider.notifier).setIndustry(picked);
  }

  Future<void> _submit() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final saved = await ref
        .read(brandProfileSetupViewModelProvider.notifier)
        .submit();
    // 프로필 다음에 캠페인 만들기가 이어진다(캠페인이 있어야 발견이 열린다).
    if (saved && mounted) context.go(AppRoutes.brandCampaignNew);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final vm = ref.read(brandProfileSetupViewModelProvider.notifier);
    final state =
        ref.watch(brandProfileSetupViewModelProvider).value ??
        const BrandProfileSetupState();
    final bottom = math.max(32.0, MediaQuery.viewPaddingOf(context).bottom);
    final message = switch (state.error) {
      BrandProfileSetupError.photoTooLarge =>
        BrandOnboardingTexts.photoTooLarge,
      BrandProfileSetupError.saveFailed => BrandOnboardingTexts.saveFailed,
      BrandProfileSetupError.rateLimited => BrandOnboardingTexts.rateLimited,
      null => null,
    };

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            SizedBox(
              height: CoraStepHeader.rowHeight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: CoraBackButton(onPressed: _back),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.only(top: 24, bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        BrandOnboardingTexts.profileTitle,
                        style: CoraTextStyles.headline.copyWith(color: c.text),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        spacing: 10,
                        children: [
                          CoraFieldBox(
                            fieldKey: BrandProfileSetupPage.nameFieldKey,
                            label: BrandOnboardingTexts.brandName,
                            controller: _name,
                            onChanged: vm.setName,
                            maxLength: 30,
                            textInputAction: TextInputAction.next,
                          ),
                          CoraFieldBox(
                            fieldKey: BrandProfileSetupPage.taglineFieldKey,
                            label: BrandOnboardingTexts.tagline,
                            hint: BrandOnboardingTexts.taglineHint,
                            controller: _tagline,
                            onChanged: vm.setTagline,
                            maxLength: 40,
                            textInputAction: TextInputAction.next,
                          ),
                          BrandFormTile(
                            label: BrandOnboardingTexts.industry,
                            value: state.industry?.label,
                            onTap: () => _chooseIndustry(state.industry),
                          ),
                          BrandPhotoTile(
                            label: BrandOnboardingTexts.photo,
                            photo: state.photo?.bytes,
                            onTap: vm.pickPhoto,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, bottom),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (message != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Semantics(
                        liveRegion: true,
                        child: Text(
                          message,
                          textAlign: TextAlign.center,
                          style: CoraTextStyles.meta.copyWith(
                            color: c.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  CoraPrimaryButton(
                    label: BrandOnboardingTexts.next,
                    look: CoraPrimaryButtonLook.accent,
                    onPressed: state.canSubmit ? _submit : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
