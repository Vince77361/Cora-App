import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/navigation/cora_transitions.dart';
import '../../../../core/theme/cora_colors.dart';
import '../../../../core/theme/cora_text_styles.dart';
import '../../../../core/ui/cora_primary_button.dart';
import '../../domain/my_store.dart';
import '../../domain/store_page_copy.dart';
import '../../domain/store_repository.dart';
import '../viewmodels/my_store_view_model.dart';
import 'store_sheet_header.dart';
import 'store_text_box.dart';

/// A3의 소개 상자를 눌렀을 때 올라오는 시트. 꼬리표, 손님들이 자주 한 말, 모집 한 줄(40자)을 한
/// 번에 고친다. 저장하면 닫히고, 실패하면 값을 그대로 둔 채 안내한다.
Future<void> showTagsEditSheet(BuildContext context) {
  FocusManager.instance.primaryFocus?.unfocus();
  return Navigator.of(context, rootNavigator: true).push<void>(
    CoraTransitions.sheet<void>(const TagsEditSheet()).createRoute(context),
  );
}

class TagsEditSheet extends ConsumerStatefulWidget {
  const TagsEditSheet({super.key});

  static const title = '이런 가게가 맞나요?';
  static const tagsLabel = '꼬리표 · 띄어쓰기로 나눠요';
  static const phrasesLabel = '손님들이 자주 한 말 · 한 줄에 하나';
  static const recruitLineLabel = '모집 한 줄';
  static const tagsInvalid = '꼬리표는 5개까지, 하나에 10자까지 쓸 수 있어요.';
  static const phrasesInvalid = '자주 한 말은 3개까지, 하나에 20자까지 쓸 수 있어요.';
  static const saveLabel = '저장';
  static const saveFailed = '저장하지 못했어요. 다시 시도해 주세요.';

  @override
  ConsumerState<TagsEditSheet> createState() => _TagsEditSheetState();
}

class _TagsEditSheetState extends ConsumerState<TagsEditSheet> {
  late final TextEditingController _tags;
  late final TextEditingController _phrases;
  late final TextEditingController _recruitLine;
  bool _saving = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    final store = ref.read(myStoreViewModelProvider).value;
    _tags = TextEditingController(
      text: StorePageCopy.formatTags(store?.tags ?? const []),
    );
    _phrases = TextEditingController(
      text: StorePageCopy.formatPhrases(store?.customerPhrases ?? const []),
    );
    _recruitLine = TextEditingController(text: store?.recruitLine ?? '');
  }

  @override
  void dispose() {
    _tags.dispose();
    _phrases.dispose();
    _recruitLine.dispose();
    super.dispose();
  }

  List<String> get _parsedTags => StorePageCopy.parseTags(_tags.text);
  List<String> get _parsedPhrases => StorePageCopy.parsePhrases(_phrases.text);
  bool get _tagsOk => StorePageCopy.tagsValid(_parsedTags);
  bool get _phrasesOk => StorePageCopy.phrasesValid(_parsedPhrases);

  Future<void> _save() async {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _saving = true;
      _failed = false;
    });
    try {
      await ref
          .read(myStoreViewModelProvider.notifier)
          .saveEdit(
            StoreEdit(
              tags: _parsedTags,
              customerPhrases: _parsedPhrases,
              recruitLine: _recruitLine.text.trim(),
            ),
          );
    } on StoreFailure {
      if (mounted) {
        setState(() {
          _saving = false;
          _failed = true;
        });
      }
      return;
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final bottom = math.max(32.0, MediaQuery.viewPaddingOf(context).bottom);
    final message = _failed
        ? TagsEditSheet.saveFailed
        : !_tagsOk
        ? TagsEditSheet.tagsInvalid
        : !_phrasesOk
        ? TagsEditSheet.phrasesInvalid
        : null;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: Column(
            children: [
              const StoreSheetHeader(title: TagsEditSheet.title),
              Expanded(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 10,
                    children: [
                      StoreTextBox(
                        fieldKey: const ValueKey('tagsSheet.tags'),
                        label: TagsEditSheet.tagsLabel,
                        controller: _tags,
                        maxLength:
                            StorePageCopy.tagsMax *
                            (StorePageCopy.tagLength + 2),
                        onChanged: (_) => setState(() => _failed = false),
                      ),
                      StoreTextBox(
                        fieldKey: const ValueKey('tagsSheet.phrases'),
                        label: TagsEditSheet.phrasesLabel,
                        controller: _phrases,
                        multiline: true,
                        maxLength:
                            StorePageCopy.phrasesMax *
                            (StorePageCopy.phraseLength + 1),
                        onChanged: (_) => setState(() => _failed = false),
                      ),
                      StoreTextBox(
                        fieldKey: const ValueKey('tagsSheet.recruitLine'),
                        label: TagsEditSheet.recruitLineLabel,
                        controller: _recruitLine,
                        maxLength: StorePageCopy.recruitLineMax,
                        onChanged: (_) => setState(() => _failed = false),
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
                    if (message != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Semantics(
                          liveRegion: true,
                          child: Text(
                            message,
                            textAlign: TextAlign.center,
                            style: CoraTextStyles.meta.copyWith(color: c.text),
                          ),
                        ),
                      ),
                    CoraPrimaryButton(
                      label: TagsEditSheet.saveLabel,
                      look: CoraPrimaryButtonLook.accent,
                      onPressed: _saving || !_tagsOk || !_phrasesOk
                          ? null
                          : _save,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
