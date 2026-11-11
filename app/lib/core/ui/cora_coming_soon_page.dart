import 'package:flutter/material.dart';

import '../theme/cora_colors.dart';
import '../theme/cora_text_styles.dart';
import 'cora_step_header.dart';

/// 아직 만들지 않은 화면 자리(캔버스에는 없는 화면). 제목과 `준비 중이에요.`만 보여 준다.
/// 돌아갈 화면이 쌓여 있으면 뒤로 가기 버튼이 나타난다.
class CoraComingSoonPage extends StatelessWidget {
  const CoraComingSoonPage({super.key, required this.title});

  final String title;

  static const body = '준비 중이에요.';

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: CoraStepHeader.rowHeight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Navigator.canPop(context)
                      ? CoraBackButton(
                          onPressed: () => Navigator.maybePop(context),
                        )
                      : null,
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: CoraTextStyles.headline.copyWith(color: c.text),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      body,
                      style: CoraTextStyles.body.copyWith(
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
    );
  }
}
