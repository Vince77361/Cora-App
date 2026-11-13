import '../../../core/navigation/app_routes.dart';
import '../../onboarding/domain/user_role.dart';

/// 알림함 경로(E3)와 거기서 여는 알림 설정(E5)·정산(E7).
///
/// 설정과 정산 화면은 같은 3번 계획의 Task 13D가 만든다. 그 전에는 라우트가 없으므로 여는 쪽이
/// 라우터에 있는지 먼저 확인한다.
abstract final class NotificationRoutes {
  static const notifications = '/notifications';
  static const settings = '/settings/notifications';
  static const wallet = '/creator/wallet';

  /// 사장님 홈을 열면서 고를 탭. 홈이 쿼리(`?tab=`)로 읽는다.
  static const tabParam = 'tab';
  static const applicantsTab = 'applicants';
  static const sentOffersTab = 'sent-offers';
}

/// 알림이 가리키는 곳([targetKind], [targetId])을 앱 경로로 바꾼다. 서버는 앱 주소를 모르고 종류와
/// ID만 내려 준다(설계 5장). 모르는 종류, 필요한 ID가 없는 경우, 이 역할에 화면이 없는 경우는 null이고,
/// 그때 알림을 누르면 읽음으로만 바뀐다.
String? locationFor(String targetKind, String? targetId, UserRole role) {
  final id = (targetId == null || targetId.isEmpty) ? null : targetId;
  // 서버는 역할을 가리지 않고 종류만 내려 주므로, 그 화면이 있는 역할에게만 경로를 준다.
  switch (targetKind) {
    case 'STORE_APPLICANTS':
      return role == UserRole.store
          ? '${AppRoutes.store}?${NotificationRoutes.tabParam}=${NotificationRoutes.applicantsTab}'
          : null;
    case 'STORE_SENT_OFFERS':
      return role == UserRole.store
          ? '${AppRoutes.store}?${NotificationRoutes.tabParam}=${NotificationRoutes.sentOffersTab}'
          : null;
    case 'OFFER_INBOX':
      return role == UserRole.creator ? AppRoutes.creatorOffers : null;
    case 'PAYMENT':
      return id == null || role != UserRole.store
          ? null
          : AppRoutes.storePay(id);
    case 'COLLABORATION':
      if (id == null) return null;
      return switch (role) {
        UserRole.store => AppRoutes.storeCollaboration(id),
        UserRole.creator => AppRoutes.creatorCollaboration(id),
        UserRole.brand => null,
      };
    case 'STORE_RESULT':
      // 정산이 끝난 협업의 7일 결과(G1). 서버는 협업 id를 준다.
      return id == null || role != UserRole.store
          ? null
          : AppRoutes.storeResult(id);
    case 'PROPOSAL':
      if (id == null) return null;
      return switch (role) {
        UserRole.store => AppRoutes.storeProposal(id),
        UserRole.creator => AppRoutes.creatorProposal(id),
        UserRole.brand => null,
      };
    case 'WALLET':
      return role == UserRole.creator ? NotificationRoutes.wallet : null;
  }
  return null;
}
