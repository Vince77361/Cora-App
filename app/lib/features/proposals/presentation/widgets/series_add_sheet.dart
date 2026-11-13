import 'package:flutter/material.dart';

import '../../../../core/navigation/cora_transitions.dart';
import '../../../../core/theme/cora_colors.dart';
import '../../../../core/theme/cora_shapes.dart';
import '../../../../core/theme/cora_text_styles.dart';
import '../../../../core/ui/cora_field_box.dart';
import '../../../../core/ui/cora_pressable.dart';
import '../../../../core/ui/cora_primary_button.dart';
import '../../../offer_terms/domain/offer_terms.dart';
import '../../../offer_terms/presentation/offer_terms_text.dart';
import '../../../offer_terms/presentation/widgets/offer_sheet_frame.dart';
import '../../domain/counter_proposal_repository.dart';
import '../../domain/creator_series.dart';

/// F6 `시리즈 추가`(캔버스 밖): 이름(20자), 형식, 설명(20자)을 적는다. [onAdd]가 서버에 만들고, 실패하면
/// 시트가 열린 채로 이유를 보인다. 만들어지면 닫힌다.
Future<void> showSeriesAddSheet(
  BuildContext context, {
  required ContentFormat initialFormat,
  required Future<void> Function(
    String name,
    ContentFormat format,
    String? note,
  )
  onAdd,
}) {
  FocusManager.instance.primaryFocus?.unfocus();
  return Navigator.of(context, rootNavigator: true).push<void>(
    CoraTransitions.sheet<void>(
      SeriesAddSheet(initialFormat: initialFormat, onAdd: onAdd),
    ).createRoute(context),
  );
}

class SeriesAddSheet extends StatefulWidget {
  const SeriesAddSheet({
    super.key,
    required this.initialFormat,
    required this.onAdd,
  });

  final ContentFormat initialFormat;
  final Future<void> Function(String name, ContentFormat format, String? note)
  onAdd;

  static const title = '시리즈 추가';
  static const nameLabel = '이름';
  static const noteLabel = '설명 (선택)';
  static const formatLabel = '형식';
  static const addLabel = '추가';
  static const failed = '시리즈를 추가하지 못했어요. 다시 시도해 주세요.';
  static const nameKey = ValueKey<String>('seriesAdd.name');
  static const noteKey = ValueKey<String>('seriesAdd.note');

  @override
  State<SeriesAddSheet> createState() => _SeriesAddSheetState();
}

class _SeriesAddSheetState extends State<SeriesAddSheet> {
  final _name = TextEditingController();
  final _note = TextEditingController();
  late ContentFormat _format = widget.initialFormat;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _note.dispose();
    super.dispose();
  }

  bool get _canAdd => _name.text.trim().isNotEmpty && !_busy;

  Future<void> _add() async {
    if (!_canAdd) return;
    final note = _note.text.trim();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.onAdd(
        _name.text.trim(),
        _format,
        note.isEmpty ? null : note,
      );
      if (!mounted) return;
      FocusManager.instance.primaryFocus?.unfocus();
      Navigator.of(context).pop();
    } on CounterProposalFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = failure.message ?? SeriesAddSheet.failed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return OfferSheetFrame(
      title: SeriesAddSheet.title,
      error: _error,
      fields: [
        CoraFieldBox(
          fieldKey: SeriesAddSheet.nameKey,
          label: SeriesAddSheet.nameLabel,
          controller: _name,
          maxLength: CreatorSeries.nameMaxLength,
          onChanged: (_) => setState(() => _error = null),
        ),
        FormatPicker(
          label: SeriesAddSheet.formatLabel,
          selected: _format,
          onPick: (format) => setState(() => _format = format),
        ),
        CoraFieldBox(
          fieldKey: SeriesAddSheet.noteKey,
          label: SeriesAddSheet.noteLabel,
          controller: _note,
          maxLength: CreatorSeries.noteMaxLength,
          onChanged: (_) => setState(() => _error = null),
          onSubmitted: (_) => _add(),
        ),
      ],
      actions: [
        CoraPrimaryButton(
          label: SeriesAddSheet.addLabel,
          onPressed: _canAdd ? _add : null,
          look: CoraPrimaryButtonLook.accent,
        ),
      ],
    );
  }
}

/// 콘텐츠 형식을 고르는 알약 줄. 시리즈가 없는 F6과 `시리즈 추가` 시트가 함께 쓴다(캔버스 밖).
class FormatPicker extends StatelessWidget {
  const FormatPicker({
    super.key,
    this.label,
    required this.selected,
    required this.onPick,
  });

  final String? label;
  final ContentFormat selected;
  final ValueChanged<ContentFormat> onPick;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final pills = Row(
      spacing: 6,
      children: [
        for (final format in ContentFormat.values)
          Expanded(
            child: _FormatPill(
              label: formatLabel(format),
              selected: format == selected,
              onTap: () => onPick(format),
            ),
          ),
      ],
    );
    if (label == null) return pills;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(CoraRadius.field),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label!,
              style: CoraTextStyles.fieldLabel.copyWith(color: c.textSecondary),
            ),
            const SizedBox(height: 8),
            pills,
          ],
        ),
      ),
    );
  }
}

class _FormatPill extends StatelessWidget {
  const _FormatPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      container: true,
      button: true,
      selected: selected,
      label: label,
      onTap: onTap,
      child: ExcludeSemantics(
        child: CoraPressable(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: selected ? c.notifyTabSelected : c.background,
                borderRadius: BorderRadius.circular(CoraRadius.pill),
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      maxLines: 1,
                      style: CoraTextStyles.label.copyWith(color: c.text),
                    ),
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
