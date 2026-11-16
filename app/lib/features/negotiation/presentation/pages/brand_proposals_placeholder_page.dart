import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../core/ui/cora_page_header.dart';
import '../../../../core/ui/cora_state_view.dart';
import '../terms_text.dart';

/// 07의 `남은 캠페인 예산`이 여는 브랜드의 제안함 자리. F3에 브랜드의 줄(캠페인 협업의 조건 판본)을 채우는 것은 5번
/// 계획이라, 그 전까지 F3의 빈 목록(F8)과 같은 모양과 글만 보인다.
class BrandProposalsPlaceholderPage extends StatelessWidget {
  const BrandProposalsPlaceholderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CoraPageHeader(
              title: TermsTexts.proposalsTitle,
              extent: 64,
              onBack: () => context.canPop()
                  ? context.pop()
                  : context.go(AppRoutes.brandCollaborations),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: CoraStateView.empty(title: TermsTexts.proposalsEmpty),
            ),
          ],
        ),
      ),
    );
  }
}
