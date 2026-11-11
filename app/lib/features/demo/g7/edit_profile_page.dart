import 'package:flutter/material.dart';

import '../shared/demo_ui.dart';
import 'g7_ui.dart';

/// E6 프로필 수정 (`NEditProfile.dc.html`)
class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  static const _cameraSvg =
      '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linejoin="round" aria-hidden="true"><path d="M4 8h3l2-3h6l2 3h3v11H4z"></path><circle cx="12" cy="13" r="3.5"></circle></svg>';

  final _name = TextEditingController(text: '민의 옷장 기록');
  final _bio = TextEditingController(
    text: '같은 옷을 여러 방식으로 입어봐요. 출근룩과 주말룩을 주로 올려요.',
  );
  final _fee = TextEditingController(text: '30만 원부터');
  final _date = TextEditingController(text: '11월 16일 이후');

  @override
  void dispose() {
    _name.dispose();
    _bio.dispose();
    _fee.dispose();
    _date.dispose();
    super.dispose();
  }

  Widget _field(
    G7Colors c,
    String label,
    TextEditingController ctrl, {
    double size = 16,
    int lines = 1,
    double? height,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: c.sub)),
          const SizedBox(height: 4),
          TextField(
            controller: ctrl,
            minLines: lines,
            maxLines: lines,
            cursorColor: c.text,
            style: TextStyle(fontSize: size, height: height, color: c.text),
            decoration: const InputDecoration(
              isDense: true,
              isCollapsed: true,
              contentPadding: EdgeInsets.zero,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = G7Colors.of(context);
    final camBg = c.dark ? const Color(0xFF2A2D33) : const Color(0xFFFFFFFF);
    final camShadow = c.dark
        ? const Color(0x66000000)
        : const Color(0x2917181C);
    return DemoFrame(
      background: c.bg,
      children: [
        Positioned.fill(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 130),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const G7Header(title: '프로필 수정'),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Center(
                    child: SizedBox(
                      width: 104,
                      height: 104,
                      child: Stack(
                        children: [
                          Container(
                            width: 104,
                            height: 104,
                            clipBehavior: Clip.antiAlias,
                            decoration: const BoxDecoration(
                              color: Color(0xFFD9DCE6),
                              shape: BoxShape.circle,
                            ),
                            child: DemoPhoto(
                              DemoImages.forBlob(
                                'b69c53f92919508dbffde40eedb1953c',
                              ),
                              x: 50,
                              y: 20,
                            ),
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 36,
                              height: 36,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: camBg,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: camShadow,
                                    offset: const Offset(0, 2),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: DemoSvg(
                                _cameraSvg,
                                color: c.text,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _field(c, '활동명', _name),
                      const SizedBox(height: 10),
                      _field(c, '소개', _bio, size: 15, lines: 3, height: 1.55),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: c.surface,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '잘 만드는 콘텐츠',
                              style: TextStyle(fontSize: 12, color: c.sub),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 12,
                              runSpacing: 4,
                              children: [
                                for (final t in const [
                                  '#데일리룩',
                                  '#액세서리',
                                  '#얼굴출연없음',
                                ])
                                  Text(
                                    t,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      color: c.text,
                                    ),
                                  ),
                                Text(
                                  '+ 추가',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: c.sub,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _field(c, '희망 제작비', _fee)),
                          const SizedBox(width: 10),
                          Expanded(child: _field(c, '가능한 시작일', _date)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            child: GestureDetector(
              onTap: () => demoGo(context, 'NSettings.dc.html'),
              child: Container(
                height: 58,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: G7Colors.lime,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  '저장하기',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: G7Colors.onLime,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
