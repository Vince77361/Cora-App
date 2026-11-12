import 'package:flutter/material.dart';

import '../shared/demo_ui.dart';
import 'g8_common.dart';

const String _infoSvg =
    '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" aria-hidden="true"><circle cx="12" cy="12" r="9"></circle><path d="M12 7v6M12 16.5v.5"></path></svg>';

const String _plusSvg =
    '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" aria-hidden="true"><path d="M12 5v14M5 12h14"></path></svg>';

const List<(String, String)> _branches = [('성수점', '성수동2가'), ('합정점', '합정동')];

/// F7 매장 직접 입력 · 지점 선택 (`NStoreManual.dc.html`)
class StoreManualPage extends StatefulWidget {
  const StoreManualPage({super.key});

  @override
  State<StoreManualPage> createState() => _StoreManualPageState();
}

class _StoreManualPageState extends State<StoreManualPage> {
  final _nameFocus = FocusNode();
  final _menuFocus = FocusNode();
  final _name = TextEditingController(text: '한그릇 라멘');
  final _menu = TextEditingController(text: '돈코츠 라멘 11,000원');
  int _branch = 0;

  @override
  void dispose() {
    _nameFocus.dispose();
    _menuFocus.dispose();
    _name.dispose();
    _menu.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pal = G8Palette.of(context);
    return DemoFrame(
      background: pal.bg,
      children: [
        Positioned.fill(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                G8Header(
                  pal: pal,
                  onBack: () => demoBack(context),
                  center: const G8Pill('가게 등록'),
                  right: '1 / 3',
                ),
                G8Progress(pal: pal, fraction: 0.33),
                _notice(pal),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _field(pal, '가게 이름', _name, _nameFocus),
                      const SizedBox(height: 8),
                      _branchCard(pal),
                      const SizedBox(height: 8),
                      _field(pal, '대표 메뉴와 가격', _menu, _menuFocus),
                      const SizedBox(height: 8),
                      _photoButton(pal),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        G8BottomBar(
          child: G8BigButton(
            label: '가게 페이지 만들기',
            onTap: () => demoGo(context, 'NStorePage.dc.html'),
            background: G8Palette.lime,
            foreground: G8Palette.limeInk,
          ),
        ),
      ],
    );
  }

  Widget _notice(G8Palette pal) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: pal.card,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: DemoSvg(_infoSvg, color: pal.text, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '링크에서 정보를 가져오지 못했어요. 아래만 채우면 계속할 수 있어요.',
              style: g8Text(13, pal.text, height: 1.55),
            ),
          ),
        ],
      ),
    );
  }

  /// 글자 칸. 카드 어디를 눌러도 입력이 열린다(`<label for>`).
  Widget _field(
    G8Palette pal,
    String label,
    TextEditingController controller,
    FocusNode focus,
  ) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: focus.requestFocus,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: pal.card,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(label, style: g8Text(12, pal.sub)),
            const SizedBox(height: 4),
            TextField(
              controller: controller,
              focusNode: focus,
              cursorColor: pal.text,
              style: g8Text(16, pal.text),
              decoration: const InputDecoration(
                isDense: true,
                isCollapsed: true,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                filled: false,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _branchCard(G8Palette pal) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: pal.card,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('지점 · 같은 이름의 가게가 2곳 있어요', style: g8Text(12, pal.sub)),
          const SizedBox(height: 8),
          for (var i = 0; i < _branches.length; i++) ...[
            if (i > 0) const SizedBox(height: 6),
            _branchOption(pal, i),
          ],
        ],
      ),
    );
  }

  Widget _branchOption(G8Palette pal, int i) {
    final on = i == _branch;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _branch = i),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: on ? pal.raised : const Color(0x00000000),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_branches[i].$1, style: g8Text(14, pal.text)),
            Text(_branches[i].$2, style: g8Text(12, pal.sub)),
          ],
        ),
      ),
    );
  }

  /// 캔버스에 링크가 없는 버튼: 눌러도 아무 일도 없다.
  Widget _photoButton(G8Palette pal) {
    return Container(
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: pal.card,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          DemoSvg(_plusSvg, color: pal.text, size: 18),
          const SizedBox(width: 8),
          Text(
            '가게 사진 올리기 (사용 권한이 있는 사진만)',
            style: g8Text(14, pal.text, weight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
