import 'package:flutter/material.dart';

import '../../../../core/navigation/cora_transitions.dart';
import '../../../../core/theme/cora_colors.dart';
import '../../../../core/theme/cora_text_styles.dart';
import '../../../../core/ui/cora_pressable.dart';
import 'store_icons.dart';

/// 목록에서 하나를 고르는 시트(업종 분류, 시·도). 누르면 그 값으로 닫고, 그냥 닫으면 null이다.
Future<T?> showStoreOptionSheet<T>(
  BuildContext context, {
  required String title,
  required List<T> options,
  required String Function(T) labelOf,
  required T? selected,
  Key? listKey,
}) {
  FocusManager.instance.primaryFocus?.unfocus();
  return Navigator.of(context, rootNavigator: true).push<T>(
    CoraTransitions.sheet<T>(
      _OptionSheet<T>(
        title: title,
        options: options,
        labelOf: labelOf,
        selected: selected,
        listKey: listKey,
      ),
    ).createRoute(context),
  );
}

class _OptionSheet<T> extends StatelessWidget {
  const _OptionSheet({
    required this.title,
    required this.options,
    required this.labelOf,
    required this.selected,
    required this.listKey,
  });

  final String title;
  final List<T> options;
  final String Function(T) labelOf;
  final T? selected;
  final Key? listKey;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final bottom = MediaQuery.viewPaddingOf(context).bottom;
    return Material(
      color: Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 8),
            child: Text(
              title,
              style: CoraTextStyles.heading.copyWith(color: c.text),
            ),
          ),
          Expanded(
            child: ListView(
              key: listKey,
              padding: EdgeInsets.fromLTRB(8, 0, 8, bottom + 16),
              children: [
                for (final option in options)
                  _Row(
                    label: labelOf(option),
                    selected: option == selected,
                    onTap: () => Navigator.of(context).pop(option),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
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
      onTap: onTap,
      child: CoraPressable(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: CoraTextStyles.bodyLarge.copyWith(color: c.text),
                  ),
                ),
                if (selected)
                  StoreIcon(StoreIconPainter.selected(c.text), size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
