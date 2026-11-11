import 'package:cora/core/theme/cora_colors.dart';
import 'package:cora/core/theme/cora_theme.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final (name, theme, c) in [
    ('light', coraLightTheme, CoraColors.light),
    ('dark', coraDarkTheme, CoraColors.dark),
  ]) {
    test('$name color scheme comes from the tokens, not the lime seed', () {
      final s = theme.colorScheme;
      expect(s.primary, c.primaryAction);
      expect(s.onPrimary, c.onPrimaryAction);
      expect(s.surface, c.background);
      expect(s.onSurface, c.text);
      expect(s.onSurfaceVariant, c.textSecondary);
      expect(s.surfaceContainer, c.surface);
      expect(s.surfaceContainerHighest, c.line);
      expect(s.outline, c.textSecondary);
      expect(s.outlineVariant, c.line);
      expect(s.error, c.text);
      expect(s.inverseSurface, c.text);
      expect(s.onInverseSurface, c.background);
      expect(s.scrim, c.scrim);
      expect(s.brightness, theme.brightness);
    });
  }
}
