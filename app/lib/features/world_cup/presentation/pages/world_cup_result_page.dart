import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../core/theme/cora_colors.dart';
import '../../../../core/theme/cora_store_interests_tokens.dart';
import '../../../../core/theme/cora_text_styles.dart';
import '../../../../core/ui/cora_network_photo.dart';
import '../../../../core/ui/cora_pressable.dart';
import '../../../../core/ui/cora_primary_button.dart';
import '../../../../core/ui/cora_secondary_button.dart';
import '../../../discovery/presentation/widgets/discovery_toast.dart';
import '../../../interests/presentation/widgets/interest_icons.dart'
    show ClosePainter, InterestIcon;
import '../../domain/world_cup_candidate.dart';
import '../widgets/world_cup_card.dart';
import '../widgets/world_cup_icons.dart';
import '../world_cup_flow.dart';
import '../world_cup_text.dart';

/// 월드컵 결과(캔버스 M19G3Result). 큰 카드에 `이상형 1위`, 아래에 `4강까지 올랐던 후보`, 맨 아래 `다시 하기`와
/// `제안하기`. 서버에 아무것도 남기지 않는다(제안은 `제안하기`가 여는 화면이 보낸다).
class WorldCupResultPage extends StatefulWidget {
  const WorldCupResultPage({super.key, required this.args});

  final WorldCupResultArgs args;

  @override
  State<WorldCupResultPage> createState() => _WorldCupResultPageState();
}

class _WorldCupResultPageState extends State<WorldCupResultPage> {
  bool _proposing = false;
  int _serial = 0;
  ({int serial, WorldCupNotice notice})? _notice;

  void _close() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.splash);
    }
  }

  /// 같은 사람들 가운데서 같은 몇 강으로 새로 뽑는다. 이 결과 화면은 새 대결로 바뀐다.
  void _again() => context.pushReplacement(
    AppRoutes.worldCupMatch,
    extra: widget.args.again(),
  );

  Future<void> _propose() async {
    if (_proposing) return;
    _proposing = true;
    try {
      final notice = await widget.args.match.onPropose(
        context,
        widget.args.champion,
      );
      if (!mounted || notice == null) return;
      setState(() => _notice = (serial: ++_serial, notice: notice));
    } finally {
      _proposing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final champion = widget.args.champion;
    final notice = _notice;
    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Header(onClose: _close),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: SizedBox(
                            height: 470,
                            child: WorldCupCard(
                              candidate: champion,
                              large: true,
                              chip: WorldCupCardChip(
                                label: WorldCupText.champion,
                                leading: WorldCupIcon(
                                  CrownPainter(
                                    c.highlightAction,
                                    c.onHighlightAction,
                                  ),
                                  size: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: _Semifinalists(
                            people: widget.args.semifinalists,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    0,
                    16,
                    math.max(32, MediaQuery.viewPaddingOf(context).bottom),
                  ),
                  child: Row(
                    spacing: 8,
                    children: [
                      Expanded(
                        flex: 10,
                        child: CoraSecondaryButton(
                          label: WorldCupText.again,
                          tone: CoraSecondaryTone.subtle,
                          fitLabel: true,
                          onPressed: _again,
                        ),
                      ),
                      Expanded(
                        flex: 16,
                        child: CoraPrimaryButton(
                          label: WorldCupText.propose,
                          look: CoraPrimaryButtonLook.accent,
                          fitLabel: true,
                          onPressed: _propose,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (notice != null)
              Positioned(
                top: 76,
                left: 22,
                right: 22,
                child: DiscoveryToastBanner(
                  key: ValueKey(notice.serial),
                  message: notice.notice.message,
                  match: notice.notice.onAction != null,
                  action: notice.notice.actionLabel,
                  onAction: notice.notice.onAction,
                  onDismiss: () {
                    if (mounted && _notice?.serial == notice.serial) {
                      setState(() => _notice = null);
                    }
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 머리(캔버스 `.hdr3`): 왼쪽 `닫기`(X 22), 가운데 `이상형 월드컵`(16/500).
class _Header extends StatelessWidget {
  const _Header({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SizedBox(
      height: 64,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            SizedBox(
              width: 60,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Semantics(
                  container: true,
                  button: true,
                  label: WorldCupText.close,
                  onTap: onClose,
                  child: ExcludeSemantics(
                    child: CoraPressable(
                      onTap: onClose,
                      child: SizedBox.square(
                        dimension: 44,
                        child: Center(
                          child: InterestIcon(ClosePainter(c.text), size: 22),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  WorldCupText.title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CoraTextStyles.bodyLarge.copyWith(color: c.text),
                ),
              ),
            ),
            const SizedBox(width: 60),
          ],
        ),
      ),
    );
  }
}

/// `4강까지 올랐던 후보`와 작은 사진(44)·이름(12) 줄. 칸 너비는 80, 사이 12다.
class _Semifinalists extends StatelessWidget {
  const _Semifinalists({required this.people});

  final List<WorldCupCandidate> people;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          WorldCupText.semifinalists,
          style: CoraTextStyles.label.copyWith(color: c.text),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [for (final p in people) _Semifinalist(person: p)],
        ),
      ],
    );
  }
}

class _Semifinalist extends StatelessWidget {
  const _Semifinalist({required this.person});

  final WorldCupCandidate person;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final hasPhoto = person.photoUrl != null && person.photoUrl!.isNotEmpty;
    return SizedBox(
      width: 80,
      child: Column(
        spacing: 6,
        children: [
          ExcludeSemantics(
            child: SizedBox.square(
              dimension: 44,
              child: ClipOval(
                child: hasPhoto
                    ? CoraNetworkPhoto(
                        url: person.photoUrl,
                        alignment: const Alignment(0, -0.4),
                        background: c.photoPlaceholder,
                      )
                    : ColoredBox(
                        color: c.photoPlaceholder,
                        child: Center(
                          child: Text(
                            person.name.isEmpty
                                ? ''
                                : String.fromCharCodes(
                                    person.name.runes.take(1),
                                  ),
                            style: CoraTextStyles.bodyLarge.copyWith(
                              color: CoraStoreInterestsTokens.avatarInitial,
                            ),
                          ),
                        ),
                      ),
              ),
            ),
          ),
          Text(
            person.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: CoraTextStyles.caption.copyWith(
              fontWeight: FontWeight.w400,
              height: 1.3,
              color: c.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
