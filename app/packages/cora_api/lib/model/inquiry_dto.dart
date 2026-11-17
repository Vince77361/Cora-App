//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class InquiryDto {
  /// Returns a new [InquiryDto] instance.
  InquiryDto({
    this.contentLine,
    required this.message,
  });

  /// 내가 만들고 싶은 콘텐츠 한 줄(40자). 나중에 서로 관심이 닿으면 조건 버전 1의 제목이 된다.
  String? contentLine;

  /// 브랜드에게 보내는 첫 메시지(1~1000자). 요청에는 이 한 개만 담긴다.
  String message;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InquiryDto &&
          other.contentLine == contentLine &&
          other.message == message;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (contentLine == null ? 0 : contentLine!.hashCode) + (message.hashCode);

  @override
  String toString() => 'InquiryDto[contentLine=$contentLine, message=$message]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.contentLine != null) {
      json[r'contentLine'] = this.contentLine;
    } else {
      json[r'contentLine'] = null;
    }
    json[r'message'] = this.message;
    return json;
  }

  /// Returns a new [InquiryDto] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static InquiryDto? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'message'),
            'Required key "InquiryDto[message]" is missing from JSON.');
        assert(json[r'message'] != null,
            'Required key "InquiryDto[message]" has a null value in JSON.');
        return true;
      }());

      return InquiryDto(
        contentLine: mapValueOfType<String>(json, r'contentLine'),
        message: mapValueOfType<String>(json, r'message')!,
      );
    }
    return null;
  }

  static List<InquiryDto> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <InquiryDto>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = InquiryDto.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, InquiryDto> mapFromJson(dynamic json) {
    final map = <String, InquiryDto>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = InquiryDto.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of InquiryDto-objects as value to a dart map
  static Map<String, List<InquiryDto>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<InquiryDto>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = InquiryDto.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'message',
  };
}
