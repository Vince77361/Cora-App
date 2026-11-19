import 'package:flutter/material.dart';

import '../../../../core/theme/cora_colors.dart';
import '../../../../core/theme/cora_shapes.dart';
import '../../../../core/theme/cora_text_styles.dart';
import '../../../../core/ui/cora_pressable.dart';
import '../../../../core/ui/cora_state_view.dart';

/// 홈의 `크리에이터 모집` 상자(캔버스 M19G4 `<section>`): 안쪽 16, 모서리 20, `surface` 바탕. 위에는 모집 조건
/// 한 줄과 `고치기`, 구분선 아래에는 `{n} 새 지원`과 `지원자 보기`(지원 있음) 또는 `아직 지원이 없어요`(없음).
/// [headline]이 null이면 모집 조건을 아직 정하지 않은 가게의 모양이다(캔버스 밖).
class RecruitBox extends StatelessWidget {
  const RecruitBox({
    super.key,
    required this.headline,
    this.detail,
    required this.hasApplicants,
    required this.newApplications,
    required this.onFix,
    required this.onOpenApplicants,
    required this.onSetTerms,
  });

  /// `식사권 2인 + 조회수 수당`. 모집 조건이 없으면 null.
  final String? headline;

  /// `1,000회당 2,000원, 최대 60,000원`. 없으면 null.
  final String? detail;
  final bool hasApplicants;
  final int newApplications;
  final VoidCallback onFix;
  final VoidCallback onOpenApplicants;
  final VoidCallback onSetTerms;

  static const label = '크리에이터 모집';
  static const fix = '고치기';
  static const newApplicationsLabel = '새 지원';
  static const openApplicants = '지원자 보기';
  static const noApplicants = '아직 지원이 없어요';
  static const noApplicantsHint = '새 지원이 오면 알려드려요';

  /// 캔버스 밖: 모집 조건을 정하지 않은 가게의 문구.
  static const unsetHint = '모집 조건을 정하고 공개해요';
  static const setTerms = '모집 조건 정하기';

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final headline = this.headline;
    final detail = this.detail;
    return Semantics(
      container: true,
      label: label,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(CoraRadius.field),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 12,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: CoraTextStyles.fieldLabel.copyWith(
                            color: c.textSecondary,
                          ),
                        ),
                        if (headline != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            headline,
                            style: CoraTextStyles.bodyLarge.copyWith(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.34,
                              color: c.text,
                            ),
                          ),
                        ],
                        if (detail != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            detail,
                            style: CoraTextStyles.fieldLabel.copyWith(
                              color: c.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (headline != null) _FixButton(onTap: onFix),
                ],
              ),
              const SizedBox(height: 12),
              DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: c.line)),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: headline == null
                      ? _row(
                          context,
                          left: Text(
                            unsetHint,
                            style: CoraTextStyles.buttonMedium.copyWith(
                              color: c.text,
                            ),
                          ),
                          action: setTerms,
                          onAction: onSetTerms,
                        )
                      : hasApplicants
                      ? _row(
                          context,
                          left: Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            spacing: 6,
                            children: [
                              Text(
                                '$newApplications',
                                style: CoraTextStyles.headline.copyWith(
                                  height: 1,
                                  letterSpacing: 0,
                                  color: c.text,
                                ),
                              ),
                              Flexible(
                                child: Text(
                                  newApplicationsLabel,
                                  style: CoraTextStyles.buttonMedium.copyWith(
                                    color: c.text,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          action: openApplicants,
                          onAction: onOpenApplicants,
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              noApplicants,
                              style: CoraTextStyles.bodySmall.copyWith(
                                fontWeight: FontWeight.w500,
                                color: c.text,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              noApplicantsHint,
                              style: CoraTextStyles.fieldLabel.copyWith(
                                color: c.textSecondary,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(
    BuildContext context, {
    required Widget left,
    required String action,
    required VoidCallback onAction,
  }) {
    final c = context.colors;
    return Row(
      spacing: 12,
      children: [
        Expanded(
          child: Align(alignment: Alignment.centerLeft, child: left),
        ),
        Semantics(
          container: true,
          button: true,
          label: action,
          onTap: onAction,
          child: ExcludeSemantics(
            child: CoraPressable(
              onTap: onAction,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: c.highlightAction,
                  borderRadius: BorderRadius.circular(CoraRadius.pill),
                ),
                child: SizedBox(
                  height: 38,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Center(
                      widthFactor: 1,
                      child: Text(
                        action,
                        maxLines: 1,
                        style: CoraTextStyles.label.copyWith(
                          color: c.onHighlightAction,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// `고치기`: 높이 34, 좌우 12, 알약, 12/500.
class _FixButton extends StatelessWidget {
  const _FixButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      container: true,
      button: true,
      label: RecruitBox.fix,
      onTap: onTap,
      child: ExcludeSemantics(
        child: CoraPressable(
          onTap: onTap,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: c.notifyTabSelected,
              borderRadius: BorderRadius.circular(CoraRadius.pill),
            ),
            child: SizedBox(
              height: 34,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Center(
                  widthFactor: 1,
                  child: Text(
                    RecruitBox.fix,
                    maxLines: 1,
                    style: CoraTextStyles.caption.copyWith(color: c.text),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 내 가게를 아직 읽지 못한 동안의 `크리에이터 모집` 자리(캔버스 밖). 모집 조건이 있는지 모르는 채로
/// `모집 조건을 정하고 공개해요`를 보이면 이미 공개한 가게에 틀린 안내가 되어서, 읽는 중에는 상자 틀만 두고
/// 실패하면 다시 시도만 둔다.
class RecruitBoxPending extends StatelessWidget {
  const RecruitBoxPending({super.key, this.onRetry});

  /// 읽기에 실패했으면 다시 시도하는 동작. null이면 읽는 중이다.
  final VoidCallback? onRetry;

  static const loading = '불러오는 중';
  static const failed = '모집 조건을 불러오지 못했어요';

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final onRetry = this.onRetry;
    return Semantics(
      container: true,
      liveRegion: true,
      label: RecruitBox.label,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(CoraRadius.field),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 8,
            children: [
              Text(
                RecruitBox.label,
                style: CoraTextStyles.fieldLabel.copyWith(
                  color: c.textSecondary,
                ),
              ),
              if (onRetry == null)
                Text(
                  loading,
                  style: CoraTextStyles.buttonMedium.copyWith(
                    color: c.textSecondary,
                  ),
                )
              else ...[
                Text(
                  failed,
                  style: CoraTextStyles.buttonMedium.copyWith(color: c.text),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: CoraPressable(
                    onTap: onRetry,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: c.notifyTabSelected,
                        borderRadius: BorderRadius.circular(CoraRadius.pill),
                      ),
                      child: SizedBox(
                        height: 34,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Center(
                            widthFactor: 1,
                            child: Text(
                              CoraStateView.retryLabel,
                              maxLines: 1,
                              style: CoraTextStyles.caption.copyWith(
                                color: c.text,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
