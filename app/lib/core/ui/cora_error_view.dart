import 'package:flutter/material.dart';

import '../theme/cora_colors.dart';
import '../theme/cora_shapes.dart';
import '../theme/cora_text_styles.dart';
import 'cora_pressable.dart';

/// 불러오기에 실패했을 때 빈 화면 대신 보여 준다. 문구와 "다시 시도" 버튼.
///
/// 버튼은 캔버스 Principles의 보조 버튼(`다시 고르기`: 알약, `surfaceMuted` 바탕,
/// 15px 500) 모양이다. 오류 화면에서 가장 센 색(기본 버튼)을 쓰지 않으려는 것이다.
class CoraErrorView extends StatelessWidget {
  const CoraErrorView({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  static const retryLabel = '다시 시도';

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 화면이 바뀌지 않아도 스크린 리더가 오류를 바로 읽게 한다.
            Semantics(
              liveRegion: true,
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: CoraTextStyles.bodyLarge.copyWith(color: c.text),
              ),
            ),
            const SizedBox(height: 20),
            Semantics(
              container: true,
              button: true,
              enabled: true,
              onTap: onRetry,
              child: CoraPressable(
                onTap: onRetry,
                child: Container(
                  height: 58,
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  decoration: BoxDecoration(
                    color: c.surfaceMuted,
                    borderRadius: BorderRadius.circular(CoraRadius.pill),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    retryLabel,
                    style: CoraTextStyles.bodyLarge.copyWith(
                      fontSize: 15,
                      color: c.onSurfaceMuted,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
