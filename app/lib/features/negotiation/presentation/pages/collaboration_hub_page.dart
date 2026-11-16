import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../core/theme/cora_colors.dart';
import '../../../../core/ui/cora_bottom_nav.dart';
import '../../../../core/ui/cora_list_row.dart';
import '../../../../core/ui/cora_state_view.dart';
import '../../../collaboration/domain/collaboration.dart';
import '../../../discovery/presentation/widgets/brand_bottom_nav.dart';
import '../terms_text.dart';
import '../viewmodels/brand_collaborations_view_model.dart';
import '../widgets/canvas_text.dart';
import 'brand_progress_page.dart';

/// 브랜드의 협업 탭(`/brand/collaborations`): 진행 중인 브랜드 협업의 목록. 협업이 하나면 목록 없이 곧바로
/// 07을 보여 주고(설계 2장 07), 여럿이면 줄마다 누르면 07이 열린다. 목록 화면은 캔버스에 없다.
class CollaborationHubPage extends ConsumerWidget {
  const CollaborationHubPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(brandCollaborationsViewModelProvider);
    final rows = async.value;
    if (rows != null && rows.length == 1) {
      return BrandProgressPage(
        key: ValueKey(rows.single.id),
        collaborationId: rows.single.id,
      );
    }
    final Widget body = switch (async) {
      AsyncData(:final value) when value.isEmpty => const Padding(
        padding: EdgeInsets.only(top: 12),
        child: CoraStateView.empty(title: TermsTexts.hubEmpty),
      ),
      AsyncData(:final value) => _List(rows: value),
      AsyncError() => CoraStateView.loadFailed(
        title: TermsTexts.hubLoadFailed,
        onRetry: () => ref.invalidate(brandCollaborationsViewModelProvider),
      ),
      _ => const CoraStateView.loading(),
    };
    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const ProgressHeader(isBrand: true),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 8),
                  child: Semantics(
                    header: true,
                    child: Text(
                      TermsTexts.hubTitle,
                      style: canvasText(
                        22,
                        FontWeight.w900,
                        context.colors.text,
                        spacingEm: -0.03,
                      ),
                    ),
                  ),
                ),
                Expanded(child: body),
              ],
            ),
          ),
          const Align(
            alignment: Alignment.bottomCenter,
            child: BrandBottomNav(currentIndex: CoraCreatorNavItems.collab),
          ),
        ],
      ),
    );
  }
}

class _List extends ConsumerWidget {
  const _List({required this.rows});

  final List<Collaboration> rows;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 112),
      children: [
        for (final c in rows)
          CoraListRow(
            photoUrl: c.counterpartPhotoUrl,
            title: c.counterpartName,
            subtitle: brandRowSubtitle(c),
            onTap: () async {
              await context.push(AppRoutes.collaborationProgress(c.id));
              // 06에서 수락하고 돌아오면 줄이 낡을 수 있다.
              ref.invalidate(brandCollaborationsViewModelProvider);
            },
          ),
      ],
    );
  }
}
