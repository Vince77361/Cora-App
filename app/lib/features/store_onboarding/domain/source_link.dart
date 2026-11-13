/// 가게 정보를 가져올 링크의 종류. 서버의 `SourceLinkKind`와 같다.
///
/// 선언 순서가 A2 입력란의 순서다(캔버스: 네이버 지도, 캐치테이블, 체험단 후기 글, 인스타그램).
enum SourceLinkKind {
  naverMap('네이버 지도', '네이버 지도', ['naver.me', 'map.naver.com']),
  catchtable('캐치테이블', '캐치테이블', ['app.catchtable.co.kr']),
  reviewPost('체험단 후기 글 · 선택 · 인스타 게시물로 바꿔 드려요', '체험단 후기 글', [
    'blog.naver.com',
    'm.blog.naver.com',
  ]),
  instagram('인스타그램 · 선택', '인스타그램', ['instagram.com', 'www.instagram.com']);

  const SourceLinkKind(this.fieldLabel, this.serviceName, this._hosts);

  /// 입력란 이름(A2).
  final String fieldLabel;

  /// 형식 오류 문구에 들어가는 서비스 이름.
  final String serviceName;
  final List<String> _hosts;

  /// 형식이 틀렸을 때 입력란 아래에 보이는 문구. 서버(`SOURCE_LINK_MESSAGES`)와 같다.
  String get invalidHint => '$serviceName 링크가 맞는지 확인해 주세요.';

  /// 비어 있는 입력란에 보이는 예시.
  String get example => switch (this) {
    naverMap => 'naver.me/[가게 링크]',
    catchtable => 'app.catchtable.co.kr/[가게 링크]',
    reviewPost => 'blog.naver.com/[후기 글]',
    instagram => 'instagram.com/가게계정',
  };

  /// [text]가 이 서비스의 주소인지. 서버(`isValidSourceLinkUrl`)와 같은 규칙으로 먼저 걸러 서버에
  /// 틀린 주소를 보내지 않는다. 주소 앞의 `https://`는 사용자가 빼고 붙여 넣기도 하므로 [normalize]한
  /// 뒤에 본다.
  bool accepts(String text) {
    final Uri url;
    try {
      url = Uri.parse(normalize(text));
    } on FormatException {
      return false;
    }
    return url.scheme == 'https' &&
        url.userInfo.isEmpty &&
        !url.hasPort &&
        (_hosts.contains(url.host) || _isSubdomainHost(url.host));
  }

  /// 티스토리는 블로그마다 주소(`이름.tistory.com`)가 달라 호스트 목록으로 못 센다. 서버
  /// (`SUBDOMAIN_OF`)와 같은 규칙으로, 마침표까지 맞춰 `evil-tistory.com`을 막는다.
  bool _isSubdomainHost(String host) =>
      this == reviewPost && _tistoryHost.hasMatch(host);

  static final _tistoryHost = RegExp(
    r'^([a-z0-9]([a-z0-9-]*[a-z0-9])?\.)+tistory\.com$',
  );

  /// 앞뒤 공백을 지우고, 주소 형식 표시가 없으면 `https://`를 붙인다.
  static String normalize(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return trimmed;
    return trimmed.contains('://') ? trimmed : 'https://$trimmed';
  }

  /// 화면에 보여 줄 때 `https://`를 뗀다(캔버스: `naver.me/[가게 링크]`).
  static String display(String url) =>
      url.startsWith('https://') ? url.substring('https://'.length) : url;
}

/// 사장님이 넣은 링크 하나, 그리고 서버가 분석해 요약한 문구.
class SourceLink {
  const SourceLink({required this.kind, required this.url, this.summary});

  final SourceLinkKind kind;
  final String url;

  /// 분석 뒤 서버가 준 요약(예: `사진 12장, 메뉴 8개 찾음`). 분석 전이거나 못 읽었으면 null.
  final String? summary;

  @override
  bool operator ==(Object other) =>
      other is SourceLink &&
      other.kind == kind &&
      other.url == url &&
      other.summary == summary;

  @override
  int get hashCode => Object.hash(kind, url, summary);
}
