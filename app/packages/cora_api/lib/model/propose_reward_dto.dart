//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class ProposeRewardDto {
  /// Returns a new [ProposeRewardDto] instance.
  ProposeRewardDto({
    required this.baseVersion,
    this.fee,
    this.format,
    this.payoutDays,
    this.performance,
    this.pieces,
    this.productProvided,
    this.revisionScope,
    this.startDate,
    this.title,
    this.usageRights,
  });

  /// 내가 보고 있던 판본 번호. 최신이 아니면 409 STALE_VERSION이다.
  ///
  /// Minimum value: 1
  int baseVersion;

  /// 제작비(원). 1만 원 단위, 10000~10000000. 빠지면 그대로.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? fee;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  ContentFormat? format;

  /// 게시 뒤 지급까지 걸리는 날(7 또는 14).
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? payoutDays;

  /// 성과 추가. 빠지면 그대로, null이면 끈다. 블로그 글에는 붙일 수 없다.
  RewardPerformanceDto? performance;

  /// Minimum value: 1
  /// Maximum value: 3
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? pieces;

  /// 제품 제공 여부. 빠지면 그대로.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? productProvided;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  RevisionScope? revisionScope;

  /// 제작 시작(YYYY-MM-DD). 바꾸는 값은 한국 시간 오늘 이후.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? startDate;

  /// 콘텐츠 제목(1~40자). 빠지면 그대로.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? title;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  BrandUsageRights? usageRights;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProposeRewardDto &&
          other.baseVersion == baseVersion &&
          other.fee == fee &&
          other.format == format &&
          other.payoutDays == payoutDays &&
          other.performance == performance &&
          other.pieces == pieces &&
          other.productProvided == productProvided &&
          other.revisionScope == revisionScope &&
          other.startDate == startDate &&
          other.title == title &&
          other.usageRights == usageRights;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (baseVersion.hashCode) +
      (fee == null ? 0 : fee!.hashCode) +
      (format == null ? 0 : format!.hashCode) +
      (payoutDays == null ? 0 : payoutDays!.hashCode) +
      (performance == null ? 0 : performance!.hashCode) +
      (pieces == null ? 0 : pieces!.hashCode) +
      (productProvided == null ? 0 : productProvided!.hashCode) +
      (revisionScope == null ? 0 : revisionScope!.hashCode) +
      (startDate == null ? 0 : startDate!.hashCode) +
      (title == null ? 0 : title!.hashCode) +
      (usageRights == null ? 0 : usageRights!.hashCode);

  @override
  String toString() =>
      'ProposeRewardDto[baseVersion=$baseVersion, fee=$fee, format=$format, payoutDays=$payoutDays, performance=$performance, pieces=$pieces, productProvided=$productProvided, revisionScope=$revisionScope, startDate=$startDate, title=$title, usageRights=$usageRights]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'baseVersion'] = this.baseVersion;
    if (this.fee != null) {
      json[r'fee'] = this.fee;
    } else {
      json[r'fee'] = null;
    }
    if (this.format != null) {
      json[r'format'] = this.format;
    } else {
      json[r'format'] = null;
    }
    if (this.payoutDays != null) {
      json[r'payoutDays'] = this.payoutDays;
    } else {
      json[r'payoutDays'] = null;
    }
    if (this.performance != null) {
      json[r'performance'] = this.performance;
    } else {
      json[r'performance'] = null;
    }
    if (this.pieces != null) {
      json[r'pieces'] = this.pieces;
    } else {
      json[r'pieces'] = null;
    }
    if (this.productProvided != null) {
      json[r'productProvided'] = this.productProvided;
    } else {
      json[r'productProvided'] = null;
    }
    if (this.revisionScope != null) {
      json[r'revisionScope'] = this.revisionScope;
    } else {
      json[r'revisionScope'] = null;
    }
    if (this.startDate != null) {
      json[r'startDate'] = _dateFormatter.format(this.startDate!);
    } else {
      json[r'startDate'] = null;
    }
    if (this.title != null) {
      json[r'title'] = this.title;
    } else {
      json[r'title'] = null;
    }
    if (this.usageRights != null) {
      json[r'usageRights'] = this.usageRights;
    } else {
      json[r'usageRights'] = null;
    }
    return json;
  }

  /// Returns a new [ProposeRewardDto] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ProposeRewardDto? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'baseVersion'),
            'Required key "ProposeRewardDto[baseVersion]" is missing from JSON.');
        assert(json[r'baseVersion'] != null,
            'Required key "ProposeRewardDto[baseVersion]" has a null value in JSON.');
        return true;
      }());

      return ProposeRewardDto(
        baseVersion: mapValueOfType<int>(json, r'baseVersion')!,
        fee: mapValueOfType<int>(json, r'fee'),
        format: ContentFormat.fromJson(json[r'format']),
        payoutDays: mapValueOfType<int>(json, r'payoutDays'),
        performance: RewardPerformanceDto.fromJson(json[r'performance']),
        pieces: mapValueOfType<int>(json, r'pieces'),
        productProvided: mapValueOfType<bool>(json, r'productProvided'),
        revisionScope: RevisionScope.fromJson(json[r'revisionScope']),
        startDate: mapDateTime(json, r'startDate', r''),
        title: mapValueOfType<String>(json, r'title'),
        usageRights: BrandUsageRights.fromJson(json[r'usageRights']),
      );
    }
    return null;
  }

  static List<ProposeRewardDto> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <ProposeRewardDto>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ProposeRewardDto.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ProposeRewardDto> mapFromJson(dynamic json) {
    final map = <String, ProposeRewardDto>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ProposeRewardDto.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ProposeRewardDto-objects as value to a dart map
  static Map<String, List<ProposeRewardDto>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<ProposeRewardDto>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ProposeRewardDto.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'baseVersion',
  };
}
