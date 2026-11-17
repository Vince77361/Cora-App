//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class BrandConsentDto {
  /// Returns a new [BrandConsentDto] instance.
  BrandConsentDto({
    this.accepted = const [],
    required this.method,
    required this.termsVersion,
  });

  /// 사용자가 확인한 세 줄. 서버가 만든 문구(myConsentTexts)와 정확히 같아야 한다.
  List<String> accepted;

  PaymentMethod method;

  /// 동의하려는 판본 번호. 최신이 아니면 409 STALE_VERSION(latestVersion).
  int termsVersion;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BrandConsentDto &&
          _deepEquality.equals(other.accepted, accepted) &&
          other.method == method &&
          other.termsVersion == termsVersion;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (accepted.hashCode) + (method.hashCode) + (termsVersion.hashCode);

  @override
  String toString() =>
      'BrandConsentDto[accepted=$accepted, method=$method, termsVersion=$termsVersion]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'accepted'] = this.accepted;
    json[r'method'] = this.method;
    json[r'termsVersion'] = this.termsVersion;
    return json;
  }

  /// Returns a new [BrandConsentDto] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static BrandConsentDto? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'accepted'),
            'Required key "BrandConsentDto[accepted]" is missing from JSON.');
        assert(json[r'accepted'] != null,
            'Required key "BrandConsentDto[accepted]" has a null value in JSON.');
        assert(json.containsKey(r'method'),
            'Required key "BrandConsentDto[method]" is missing from JSON.');
        assert(json[r'method'] != null,
            'Required key "BrandConsentDto[method]" has a null value in JSON.');
        assert(json.containsKey(r'termsVersion'),
            'Required key "BrandConsentDto[termsVersion]" is missing from JSON.');
        assert(json[r'termsVersion'] != null,
            'Required key "BrandConsentDto[termsVersion]" has a null value in JSON.');
        return true;
      }());

      return BrandConsentDto(
        accepted: json[r'accepted'] is Iterable
            ? (json[r'accepted'] as Iterable)
                .cast<String>()
                .toList(growable: false)
            : const [],
        method: PaymentMethod.fromJson(json[r'method'])!,
        termsVersion: mapValueOfType<int>(json, r'termsVersion')!,
      );
    }
    return null;
  }

  static List<BrandConsentDto> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <BrandConsentDto>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = BrandConsentDto.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, BrandConsentDto> mapFromJson(dynamic json) {
    final map = <String, BrandConsentDto>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = BrandConsentDto.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of BrandConsentDto-objects as value to a dart map
  static Map<String, List<BrandConsentDto>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<BrandConsentDto>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = BrandConsentDto.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'accepted',
    'method',
    'termsVersion',
  };
}
