/// 연동된 인스타그램 계정. 조회수를 읽고 내 게시물만 제출하게 하는 기준이다.
class InstagramConnection {
  const InstagramConnection({required this.handle, this.followers});

  /// @ 없는 아이디.
  final String handle;
  final int? followers;
}
