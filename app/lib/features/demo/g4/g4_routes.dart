import 'package:go_router/go_router.dart';

import '../demo_paths.dart';
import 'creator_view_page.dart';
import 'escrow_page.dart';
import 'instagram_page.dart';
import 'offer_inbox_page.dart';
import 'profile_page.dart';
import 'reels_page.dart';
import 'upload_page.dart';

/// 이 묶음의 시연 화면 경로. 묶음을 맡은 작업자만 고친다.
final List<RouteBase> g4Routes = <RouteBase>[
  GoRoute(
    path: DemoPaths.offerInbox,
    builder: (_, _) => const OfferInboxPage(),
  ),
  GoRoute(path: DemoPaths.escrow, builder: (_, _) => const EscrowPage()),
  GoRoute(path: DemoPaths.upload, builder: (_, _) => const UploadPage()),
  GoRoute(path: DemoPaths.profile, builder: (_, _) => const ProfilePage()),
  GoRoute(path: DemoPaths.instagram, builder: (_, _) => const InstagramPage()),
  GoRoute(
    path: DemoPaths.creatorView,
    builder: (_, _) => const CreatorViewPage(),
  ),
  GoRoute(path: DemoPaths.reels, builder: (_, _) => const ReelsPage()),
];
