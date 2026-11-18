import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/media/photo_picker.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/network/photo_uploader.dart';
import '../../../../core/text/utf16_length_limiting_formatter.dart';
import '../../../../core/theme/cora_colors.dart';
import '../../../../core/theme/cora_shapes.dart';
import '../../../../core/theme/cora_text_styles.dart';
import '../../../../core/ui/cora_primary_button.dart';
import '../../domain/featured_post.dart';
import '../featured_posts_text.dart';
import '../widgets/featured_post_close_header.dart';

/// 사진첩에서 올리기(기존 캔버스 B6 `NUpload`에서 분야 꼬리표 줄과 "좋아요를 많이 받은…" 안내를 뺀 것, 캔버스 밖).
/// 고른 사진 미리보기와 한 줄 설명(1~40자, 필수)을 받아 `대표 게시물에 추가`를 누르면 사진을 서버에 올리고(`featuredPost`) 저장 전
/// 초안으로 돌려주며 닫힌다. 저장은 대표 게시물 화면의 `저장하기`다.
class FeaturedPostComposePage extends ConsumerStatefulWidget {
  const FeaturedPostComposePage({super.key, required this.photo});

  /// 보관함에서 고른 사진(올리기 전에 긴 변 2048·품질 85로 줄인 것).
  final PickedPhoto photo;

  @visibleForTesting
  static const captionFieldKey = ValueKey<String>('featuredPost.caption');

  @override
  ConsumerState<FeaturedPostComposePage> createState() =>
      _FeaturedPostComposePageState();
}

class _FeaturedPostComposePageState
    extends ConsumerState<FeaturedPostComposePage> {
  final _caption = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _caption.dispose();
    super.dispose();
  }

  bool get _canSubmit => _caption.text.trim().isNotEmpty && !_busy;

  void _close() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.creatorFeaturedPosts);
    }
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    final photo = widget.photo;
    try {
      final path = await ref
          .read(photoUploaderProvider)
          .upload(
            purpose: PhotoPurpose.featuredPost,
            bytes: photo.bytes,
            contentType: photo.contentType,
          );
      if (!mounted) return;
      context.pop(
        FeaturedPost(
          source: FeaturedPostSource.gallery,
          kind: FeaturedPostKind.photo,
          photoUrl: null,
          caption: _caption.text.trim(),
          mediaPath: path,
          previewBytes: photo.bytes,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = switch (error) {
          PhotoTooLargeException() => FeaturedPostsText.photoTooLarge,
          PhotoUploadException(isRateLimited: true) =>
            FeaturedPostsText.rateLimited,
          _ => FeaturedPostsText.uploadFailed,
        };
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final bottom = math.max(32.0, MediaQuery.viewPaddingOf(context).bottom);
    final valueStyle = CoraTextStyles.listLabel.copyWith(color: c.text);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FeaturedPostCloseHeader(
              title: FeaturedPostsText.composeTitle,
              onClose: _close,
            ),
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Semantics(
                      image: true,
                      label: FeaturedPostsText.composePhotoLabel,
                      child: SizedBox(
                        height: 300,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(CoraRadius.xl),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              ColoredBox(
                                color: c.line,
                                child: Image.memory(
                                  widget.photo.bytes,
                                  fit: BoxFit.cover,
                                  gaplessPlayback: true,
                                  excludeFromSemantics: true,
                                  errorBuilder: (context, error, stack) =>
                                      const SizedBox.expand(),
                                ),
                              ),
                              Positioned(
                                left: 12,
                                top: 12,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: c.photoScrim,
                                    borderRadius: BorderRadius.circular(
                                      CoraRadius.pill,
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    child: Text(
                                      FeaturedPostsText.badgeGallery,
                                      style: CoraTextStyles.caption.copyWith(
                                        color: c.onPhoto,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: c.surface,
                        borderRadius: BorderRadius.circular(CoraRadius.field),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: MergeSemantics(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                FeaturedPostsText.captionLabel,
                                style: CoraTextStyles.fieldLabel.copyWith(
                                  color: c.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              TextField(
                                key: FeaturedPostComposePage.captionFieldKey,
                                controller: _caption,
                                enabled: !_busy,
                                onChanged: (_) => setState(() {}),
                                onSubmitted: (_) => _submit(),
                                textInputAction: TextInputAction.done,
                                style: valueStyle,
                                cursorColor: c.text,
                                // 서버는 한 줄을 UTF-16 단위로 센다.
                                inputFormatters: [
                                  const Utf16LengthLimitingFormatter(
                                    FeaturedPostLimits.maxCaptionLength,
                                  ),
                                  FilteringTextInputFormatter.deny(
                                    RegExp(r'[\r\n]'),
                                  ),
                                ],
                                decoration: InputDecoration(
                                  hintText:
                                      FeaturedPostsText.composeCaptionHint,
                                  hintStyle: valueStyle.copyWith(
                                    color: c.textSecondary,
                                  ),
                                  isCollapsed: true,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  disabledBorder: InputBorder.none,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, bottom),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Semantics(
                        liveRegion: true,
                        child: Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: CoraTextStyles.meta.copyWith(color: c.text),
                        ),
                      ),
                    ),
                  CoraPrimaryButton(
                    label: FeaturedPostsText.addComposeButton,
                    look: CoraPrimaryButtonLook.accent,
                    onPressed: _canSubmit ? _submit : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
