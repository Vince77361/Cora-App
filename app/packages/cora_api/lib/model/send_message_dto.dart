//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class SendMessageDto {
  /// Returns a new [SendMessageDto] instance.
  SendMessageDto({
    required this.clientId,
    required this.kind,
    this.text,
  });

  /// 앱이 만든 중복 방지 값. 같은 값으로 다시 보내면 새 메시지를 만들지 않고 첫 메시지를 돌려준다.
  String clientId;

  /// CONTENT_CARD는 크리에이터만 보낼 수 있다.
  SendableMessageKind kind;

  /// 글 메시지의 글(1~1000자). 콘텐츠 카드에는 쓰지 않는다.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? text;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SendMessageDto &&
          other.clientId == clientId &&
          other.kind == kind &&
          other.text == text;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (clientId.hashCode) +
      (kind.hashCode) +
      (text == null ? 0 : text!.hashCode);

  @override
  String toString() =>
      'SendMessageDto[clientId=$clientId, kind=$kind, text=$text]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'clientId'] = this.clientId;
    json[r'kind'] = this.kind;
    if (this.text != null) {
      json[r'text'] = this.text;
    } else {
      json[r'text'] = null;
    }
    return json;
  }

  /// Returns a new [SendMessageDto] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static SendMessageDto? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'clientId'),
            'Required key "SendMessageDto[clientId]" is missing from JSON.');
        assert(json[r'clientId'] != null,
            'Required key "SendMessageDto[clientId]" has a null value in JSON.');
        assert(json.containsKey(r'kind'),
            'Required key "SendMessageDto[kind]" is missing from JSON.');
        assert(json[r'kind'] != null,
            'Required key "SendMessageDto[kind]" has a null value in JSON.');
        return true;
      }());

      return SendMessageDto(
        clientId: mapValueOfType<String>(json, r'clientId')!,
        kind: SendableMessageKind.fromJson(json[r'kind'])!,
        text: mapValueOfType<String>(json, r'text'),
      );
    }
    return null;
  }

  static List<SendMessageDto> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <SendMessageDto>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SendMessageDto.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, SendMessageDto> mapFromJson(dynamic json) {
    final map = <String, SendMessageDto>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = SendMessageDto.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of SendMessageDto-objects as value to a dart map
  static Map<String, List<SendMessageDto>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<SendMessageDto>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = SendMessageDto.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'clientId',
    'kind',
  };
}
