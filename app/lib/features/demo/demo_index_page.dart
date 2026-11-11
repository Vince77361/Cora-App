import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/cora_colors.dart';
import 'demo_app.dart';
import 'demo_paths.dart';

/// 시연 목록. 모든 화면으로 들어가는 입구와 라이트·다크 전환.
class DemoIndexPage extends StatelessWidget {
  const DemoIndexPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final groups = <String, List<DemoScreenInfo>>{};
    for (final s in demoScreens) {
      groups.putIfAbsent(s.group, () => []).add(s);
    }
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Cora 시연',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: c.text,
                    ),
                  ),
                ),
                ValueListenableBuilder<ThemeMode>(
                  valueListenable: demoThemeMode,
                  builder: (context, mode, _) => TextButton(
                    onPressed: () =>
                        demoThemeMode.value = mode == ThemeMode.dark
                        ? ThemeMode.light
                        : ThemeMode.dark,
                    child: Text(
                      mode == ThemeMode.dark ? '다크 → 라이트' : '라이트 → 다크',
                      style: TextStyle(color: c.text),
                    ),
                  ),
                ),
              ],
            ),
            for (final e in groups.entries) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 20, 4, 6),
                child: Text(
                  e.key,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: c.textSecondary,
                  ),
                ),
              ),
              Material(
                color: c.surface,
                borderRadius: BorderRadius.circular(22),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    for (final s in e.value)
                      ListTile(
                        title: Text(
                          s.title,
                          style: TextStyle(fontSize: 15, color: c.text),
                        ),
                        trailing: Icon(
                          Icons.chevron_right,
                          color: c.textSecondary,
                        ),
                        onTap: () => context.push(s.path),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
