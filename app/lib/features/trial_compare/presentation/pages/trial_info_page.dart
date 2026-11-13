import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../core/theme/cora_colors.dart';
import '../../../../core/theme/cora_text_styles.dart';
import '../../../../core/ui/cora_field_box.dart';
import '../../../../core/ui/cora_page_header.dart';
import '../../../../core/ui/cora_primary_button.dart';
import '../../../../core/ui/cora_secondary_button.dart';
import '../../../store_onboarding/presentation/viewmodels/my_store_view_model.dart';
import '../../domain/trial_info.dart';
import '../viewmodels/trial_compare_view_model.dart';

/// 체험단 계약 정보 입력(캔버스에 없다). 월 계약 금액, 계약 종료일, 석 달 동안 받은 글 수를 넣고 `저장`한다.
/// 저장한 정보가 있으면 `지우기`도 보인다. 숫자의 범위는 서버가 검사하고, 앱은 모양(숫자, 달력에 있는 날짜)만 본다.
class TrialInfoPage extends ConsumerStatefulWidget {
  const TrialInfoPage({super.key});

  static const title = '체험단 계약 정보';
  static const description = '석 달을 같은 기준으로 비교하려고 물어요. 사장님이 입력한 값 그대로 보여요.';
  static const monthlyFee = '월 계약 금액';
  static const endsOn = '계약 종료일';
  static const endsOnExample = '예: 2026-12-10';
  static const postCount = '석 달 동안 받은 글 수';
  static const save = '저장';
  static const clear = '지우기';
  static const failed = '저장하지 못했어요. 다시 시도해 주세요.';

  @override
  ConsumerState<TrialInfoPage> createState() => _TrialInfoPageState();
}

class _TrialInfoPageState extends ConsumerState<TrialInfoPage> {
  final _fee = TextEditingController();
  final _endsOn = TextEditingController();
  final _posts = TextEditingController();
  bool _filled = false;

  @override
  void initState() {
    super.initState();
    _fill();
  }

  /// 저장된 정보가 있으면 칸을 채운다. 내 가게를 아직 읽는 중이면 읽힌 뒤 한 번만 채운다.
  void _fill() {
    if (_filled) return;
    final store = ref.read(myStoreViewModelProvider);
    if (!store.hasValue) return;
    _filled = true;
    final info = store.value?.trialInfo;
    if (info == null) return;
    _fee.text = '${info.monthlyFee}';
    _endsOn.text = formatTrialDate(info.endsOn);
    _posts.text = '${info.postCount}';
  }

  @override
  void dispose() {
    _fee.dispose();
    _endsOn.dispose();
    _posts.dispose();
    super.dispose();
  }

  void _leave() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.storeMe);
    }
  }

  /// 입력한 세 칸이 모두 올바른 모양이면 [TrialInfo], 아니면 null.
  TrialInfo? _parse() {
    final fee = int.tryParse(_fee.text.trim());
    final posts = int.tryParse(_posts.text.trim());
    final date = parseTrialDate(_endsOn.text);
    if (fee == null ||
        fee <= 0 ||
        posts == null ||
        posts <= 0 ||
        date == null) {
      return null;
    }
    return TrialInfo(monthlyFee: fee, endsOn: date, postCount: posts);
  }

  Future<void> _save() async {
    final info = _parse();
    if (info == null) return;
    final ok = await ref.read(trialInfoViewModelProvider.notifier).save(info);
    if (mounted && ok) _leave();
  }

  Future<void> _clear() async {
    final ok = await ref.read(trialInfoViewModelProvider.notifier).clear();
    if (mounted && ok) _leave();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(myStoreViewModelProvider, (_, _) => _fill());
    final c = context.colors;
    final form = ref.watch(trialInfoViewModelProvider);
    final saved = ref.watch(
      myStoreViewModelProvider.select((s) => s.value?.trialInfo != null),
    );
    final bottom = math.max(32.0, MediaQuery.viewPaddingOf(context).bottom);
    final canSave = _parse() != null && !form.busy;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CoraPageHeader(title: TrialInfoPage.title, onBack: _leave),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 8,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                      child: Text(
                        TrialInfoPage.description,
                        style: CoraTextStyles.meta.copyWith(
                          color: c.textSecondary,
                        ),
                      ),
                    ),
                    CoraFieldBox(
                      label: TrialInfoPage.monthlyFee,
                      controller: _fee,
                      enabled: !form.busy,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (_) => setState(() {}),
                    ),
                    CoraFieldBox(
                      label: TrialInfoPage.endsOn,
                      controller: _endsOn,
                      enabled: !form.busy,
                      keyboardType: TextInputType.number,
                      inputFormatters: [_DateFormatter()],
                      onChanged: (_) => setState(() {}),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        TrialInfoPage.endsOnExample,
                        style: CoraTextStyles.legal.copyWith(
                          color: c.textSecondary,
                        ),
                      ),
                    ),
                    CoraFieldBox(
                      label: TrialInfoPage.postCount,
                      controller: _posts,
                      enabled: !form.busy,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (_) => setState(() {}),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, bottom),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 8,
                children: [
                  if (form.failed)
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        TrialInfoPage.failed,
                        textAlign: TextAlign.center,
                        style: CoraTextStyles.meta.copyWith(color: c.text),
                      ),
                    ),
                  CoraPrimaryButton(
                    label: TrialInfoPage.save,
                    onPressed: canSave ? _save : null,
                    look: CoraPrimaryButtonLook.accent,
                  ),
                  if (saved)
                    CoraSecondaryButton(
                      label: TrialInfoPage.clear,
                      onPressed: form.busy ? null : _clear,
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

/// 숫자만 받아 `2026-12-10` 모양으로 하이픈을 넣는다(최대 8자리).
class _DateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final capped = digits.length > 8 ? digits.substring(0, 8) : digits;
    final out = StringBuffer();
    for (var i = 0; i < capped.length; i++) {
      if (i == 4 || i == 6) out.write('-');
      out.write(capped[i]);
    }
    final text = out.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
