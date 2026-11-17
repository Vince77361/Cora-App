import '../../../core/time/kst.dart';
import '../domain/message.dart';

/// 대화방 목록에 놓이는 줄 하나. 날짜 구분선과 메시지(확정·보내는 중·실패)를 오래된 것부터 늘어놓는다.
sealed class ThreadRow {
  const ThreadRow();
}

/// 한국 시간으로 날짜가 바뀌는 곳의 구분선(`11월 10일`).
class DayRow extends ThreadRow {
  const DayRow(this.at);

  final DateTime at;
}

class MessageRow extends ThreadRow {
  const MessageRow(this.message);

  final ChatMessage message;
}

/// 확정된 메시지(번호 순) 뒤에 보내는 중·실패한 내 메시지(보낸 순서)를 붙이고, 첫 메시지 앞과 한국 시간으로
/// 날짜가 바뀌는 곳마다 날짜 구분선을 끼운다. 오래된 것이 앞이다.
List<ThreadRow> threadRows(
  List<ChatMessage> messages,
  List<ChatMessage> pending,
) {
  final rows = <ThreadRow>[];
  DateTime? day;
  for (final m in [...messages, ...pending]) {
    final kst = toKst(m.at);
    final thisDay = DateTime.utc(kst.year, kst.month, kst.day);
    if (day != thisDay) {
      rows.add(DayRow(m.at));
      day = thisDay;
    }
    rows.add(MessageRow(m));
  }
  return rows;
}
