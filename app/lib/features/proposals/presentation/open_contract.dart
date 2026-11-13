import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/navigation/app_routes.dart';
import '../../collaboration/domain/collaboration.dart';
import '../../collaboration/domain/collaboration_repository.dart';

/// 합의한 제안의 계약 화면을 연다(사장님 쪽). 결제 전이면 결제(A8), 결제했으면 사장님 진행 화면이다.
/// 단계를 못 읽으면 결제 화면을 연다(결제 화면이 서버 견적으로 알맞게 보여 준다). 닫고 돌아오면 끝난다.
Future<void> openStoreContract(
  BuildContext context,
  WidgetRef ref,
  String collaborationId,
) async {
  var paid = false;
  try {
    final collaboration = await ref
        .read(collaborationRepositoryProvider)
        .fetch(collaborationId);
    paid = collaboration.stage != CollaborationStage.awaitingPayment;
  } on Object {
    // 위의 설명대로 결제 화면으로 간다.
  }
  if (!context.mounted) return;
  await context.push(
    paid
        ? AppRoutes.storeCollaboration(collaborationId)
        : AppRoutes.storePay(collaborationId),
  );
}
