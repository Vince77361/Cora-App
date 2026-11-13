import 'package:flutter/material.dart';

import '../../../../core/navigation/cora_transitions.dart';
import '../../../../core/theme/cora_colors.dart';
import '../../../../core/theme/cora_shapes.dart';
import '../../../../core/theme/cora_text_styles.dart';
import '../../../../core/ui/cora_field_box.dart';
import '../../../../core/ui/cora_pressable.dart';
import '../../../../core/ui/cora_primary_button.dart';
import '../../../../core/ui/cora_secondary_button.dart';
import '../../../offer_terms/presentation/widgets/offer_sheet_frame.dart';
import '../../domain/creator_series.dart';
import '../counter_proposal_text.dart';

/// F6 `표현 원칙`을 눌렀을 때(캔버스 밖): 꼬리표를 최대 3개(각 10자)까지 달고 뺀다. 저장하면 꼬리표 목록을,
/// 그냥 닫으면 null을 돌려준다.
Future<List<String>?> showPrinciplesSheet(
  BuildContext context, {
  required List<String> initial,
}) {
  FocusManager.instance.primaryFocus?.unfocus();
  return Navigator.of(context, rootNavigator: true).push<List<String>>(
    CoraTransitions.sheet<List<String>>(
      PrinciplesSheet(initial: initial),
    ).createRoute(context),
  );
}

class PrinciplesSheet extends StatefulWidget {
  const PrinciplesSheet({super.key, required this.initial});

  final List<String> initial;

  static const title = '표현 원칙';
  static const inputLabel = '꼬리표 (최대 3개, 각 10자)';
  static const addLabel = '추가';
  static const saveLabel = '저장';
  static const full = '꼬리표는 3개까지 달 수 있어요.';
  static const inputKey = ValueKey<String>('principles.input');

  @override
  State<PrinciplesSheet> createState() => _PrinciplesSheetState();
}

class _PrinciplesSheetState extends State<PrinciplesSheet> {
  late final List<String> _tags = [...widget.initial];
  final _input = TextEditingController();

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  bool get _full => _tags.length >= CounterProposal.principlesMax;

  void _add() {
    final tag = normalizePrinciple(_input.text);
    if (tag == null || _full || _tags.contains(tag)) return;
    setState(() {
      _tags.add(tag);
      _input.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return OfferSheetFrame(
      title: PrinciplesSheet.title,
      fields: [
        if (_tags.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final tag in _tags)
                Semantics(
                  button: true,
                  label: '${principleTag(tag)} 빼기',
                  child: ExcludeSemantics(
                    child: CoraPressable(
                      onTap: () => setState(() => _tags.remove(tag)),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: c.notifyTabSelected,
                          borderRadius: BorderRadius.circular(CoraRadius.pill),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          child: Text(
                            '${principleTag(tag)}  ×',
                            style: CoraTextStyles.label.copyWith(color: c.text),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        if (_full)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              PrinciplesSheet.full,
              style: CoraTextStyles.meta.copyWith(color: c.textSecondary),
            ),
          )
        else
          CoraFieldBox(
            fieldKey: PrinciplesSheet.inputKey,
            label: PrinciplesSheet.inputLabel,
            controller: _input,
            maxLength: CounterProposal.principleMaxLength,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _add(),
          ),
      ],
      actions: [
        if (!_full)
          CoraSecondaryButton(
            label: PrinciplesSheet.addLabel,
            onPressed: normalizePrinciple(_input.text) == null ? null : _add,
            tone: CoraSecondaryTone.subtle,
          ),
        CoraPrimaryButton(
          label: PrinciplesSheet.saveLabel,
          onPressed: () {
            FocusManager.instance.primaryFocus?.unfocus();
            Navigator.of(context).pop<List<String>>(List.of(_tags));
          },
          look: CoraPrimaryButtonLook.accent,
        ),
      ],
    );
  }
}
