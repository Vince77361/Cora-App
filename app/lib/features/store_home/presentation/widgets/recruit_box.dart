import 'package:flutter/material.dart';

import '../../../../core/theme/cora_colors.dart';
import '../../../../core/theme/cora_shapes.dart';
import '../../../../core/theme/cora_text_styles.dart';
import '../../../../core/ui/cora_pressable.dart';

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
