/// 카드 → 상세 공유 요소 전환(Flutter `Hero`)의 태그 규칙 `'<종류>:<id>'`.
///
/// 같은 화면에 다른 종류의 카드(크리에이터, 가게, 콘텐츠)가 함께 있어도 id가 겹쳐
/// 엉뚱한 사진이 날아가지 않도록 종류를 앞에 붙인다. 태그를 손으로 만들지 말고 여기서 만든다.
abstract final class CoraHeroTag {
  /// 예: `CoraHeroTag.of('creator', 42)` → `'creator:42'`
  static String of(String kind, Object id) {
    assert(kind.isNotEmpty && !kind.contains(':'), '종류에는 ":"를 쓰지 않는다: $kind');
    return '$kind:$id';
  }
}
