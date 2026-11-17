/// 메시지의 종류. 서버의 `MessageKind`와 같다. [system]은 서버가 끼워 넣는 안내 줄이다.
enum MessageKind { text, contentCard, system }

/// 내 메시지의 전달 상태. 서버에서 받은 메시지는 모두 [sent]다.
enum SendState { sent, sending, failed }

/// 콘텐츠 카드 메시지의 카드. 보낸 시점의 사진과 제목 사본이다.
class ContentCard {
  const ContentCard({required this.title, this.photoUrl});

  final String title;
  final String? photoUrl;
}

/// 대화방의 메시지 하나. 서버가 정한 [id]와 [seq]는 아직 서버에 닿지 않은 내 메시지에는 없다.
class ChatMessage {
  const ChatMessage({
    this.id,
    this.seq,
    required this.clientId,
    required this.kind,
    required this.mine,
    this.text,
    this.card,
    required this.at,
    this.state = SendState.sent,
  });

  final String? id;

  /// 방 안의 번호(1부터 빠짐없이 늘어난다). 서버에 닿기 전에는 null.
  final int? seq;

  /// 앱이 보낼 때 만든 중복 방지 값. 서버가 정한 값이 없는 메시지(상대 메시지, 안내 줄)는 [id]를 쓴다.
  final String clientId;
  final MessageKind kind;
  final bool mine;

  /// 글 메시지의 글. 안내 줄은 읽는 사람에 맞춰 서버가 만든 문구, 콘텐츠 카드는 null.
  final String? text;
  final ContentCard? card;
  final DateTime at;
  final SendState state;
}
