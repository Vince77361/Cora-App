import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/cora_colors.dart';
import '../../../../core/theme/cora_shapes.dart';
import '../../../../core/theme/cora_text_styles.dart';
import '../../../../core/ui/cora_info_tile.dart';
import '../../../../core/ui/cora_primary_button.dart';
import '../../../../core/ui/cora_secondary_button.dart';
import '../../../offer_terms/presentation/offer_terms_text.dart';
import '../../domain/proposal.dart';
import '../../domain/proposal_repository.dart';

/// 수락했지만 결제 전인 오퍼를 사장님이 취소하는 시트(제안 상세가 연다). 옛 사장님 홈의 취소 시트를 그대로 옮겼다.
/// 조건 요약과 `오퍼 취소`가 있고, 누르면 같은 시트 안에서 확인 문구로 바뀐다. 캔버스에 없는 화면이라 기존 토큰과 정보 칸으로 최소로 만들었다.
///
/// [onCancel]이 [ProposalFailure]를 던지면 시트에 머물며 실패 문구를 보인다.
Future<void> showCancelOfferSheet(
  BuildContext context, {
  required ProposalDetail detail,
  required Future<void> Function() onCancel,
}) {
  final c = context.colors;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: c.background,
    barrierColor: c.scrim.withValues(alpha: 0.4),
    elevation: 0,
    showDragHandle: false,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(CoraRadius.xxl)),
    ),
    builder: (_) => CancelOfferSheet(detail: detail, onCancel: onCancel),
  );
}

class CancelOfferSheet extends StatefulWidget {
  const CancelOfferSheet({
    super.key,
    required this.detail,
    required this.onCancel,
  });

  final ProposalDetail detail;
  final Future<void> Function() onCancel;

  static const cancel = '오퍼 취소';
  static const confirmTitle = '이 오퍼를 취소할까요?';
  static const confirm = '취소하기';
  static const keep = '그대로 두기';
  static const status = '수락함, 결제를 기다려요';

  /// 캔버스에 없는 상태의 문구.
  static const conflict = '이미 처리된 오퍼예요.';
  static const failed = '취소하지 못했어요. 다시 시도해 주세요.';

  @override
  State<CancelOfferSheet> createState() => _CancelOfferSheetState();
}

class _CancelOfferSheetState extends State<CancelOfferSheet> {
  bool _confirming = false;
  bool _busy = false;
  String? _error;

  Future<void> _confirm() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.onCancel();
    } on ProposalFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = failure.conflict
            ? CancelOfferSheet.conflict
            : CancelOfferSheet.failed;
      });
      return;
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final bottom = math.max(32.0, MediaQuery.viewPaddingOf(context).bottom);
    final detail = widget.detail;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 28, 16, bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Semantics(
              header: true,
              child: Text(
                _confirming
                    ? CancelOfferSheet.confirmTitle
                    : '${detail.counterpart.name}에게 보낸 오퍼',
                style: CoraTextStyles.heading.copyWith(color: c.text),
              ),
            ),
          ),
          if (!_confirming) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 16),
              child: Text(
                CancelOfferSheet.status,
                style: CoraTextStyles.bodySmall.copyWith(
                  color: c.textSecondary,
                ),
              ),
            ),
            CoraInfoTile(
              label: '콘텐츠',
              value: contentLine(detail.latest.terms.format),
            ),
            const SizedBox(height: 8),
            CoraInfoTile(
              label: '보상',
              value: rewardSummary(detail.latest.terms),
            ),
            const SizedBox(height: 20),
            CoraSecondaryButton(
              label: CancelOfferSheet.cancel,
              tone: CoraSecondaryTone.muted,
              onPressed: () => setState(() => _confirming = true),
            ),
          ] else ...[
            const SizedBox(height: 20),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: CoraTextStyles.meta.copyWith(color: c.text),
                  ),
                ),
              ),
            CoraPrimaryButton(
              label: CancelOfferSheet.confirm,
              onPressed: _busy ? null : _confirm,
            ),
            const SizedBox(height: 8),
            CoraSecondaryButton(
              label: CancelOfferSheet.keep,
              onPressed: _busy ? null : () => Navigator.of(context).pop(),
            ),
          ],
        ],
      ),
    );
  }
}
