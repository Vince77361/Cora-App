//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class TermsVersionModel {
  /// Returns a new [TermsVersionModel] instance.
  TermsVersionModel({
    required this.brandConfirmed,
    required this.creatorConfirmed,
    required this.fee,
    required this.format,
    required this.maxCash,
    required this.payoutDays,
    required this.performance,
    required this.pieces,
    required this.productProvided,
    required this.proposedBy,
    required this.revisionScope,
    required this.startDate,
    required this.title,
    required this.usageRights,
    required this.version,
  });

  /// 브랜드가 이 판본을 확인했다.
  bool brandConfirmed;

  /// 크리에이터가 이 판본을 확인했다.
  bool creatorConfirmed;

  /// 제작비(원, 현금 고정비).
  int fee;

  ContentFormat format;

  /// 최대 현금 부담 = 제작비 + 성과 추가 상한(없으면 0).
  int maxCash;

  /// 게시 뒤 지급까지 걸리는 날(7 또는 14).
  int payoutDays;

  /// 성과 추가(조회수 수당). 없으면 null.
  TermsPerformanceModel? performance;

  /// 편 수(1~3).
  int pieces;

  /// 제품 제공 여부.
  bool productProvided;

  /// SYSTEM은 서로 관심이 닿을 때 서버가 만든 버전 1이다.
  TermsProposer proposedBy;

  RevisionScope revisionScope;

  /// 제작 시작.
  DateTime startDate;

  /// 콘텐츠 제목(40자까지).
  String title;

  BrandUsageRights usageRights;

  /// 판본 번호(1부터).
  int version;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TermsVersionModel &&
          other.brandConfirmed == brandConfirmed &&
          other.creatorConfirmed == creatorConfirmed &&
          other.fee == fee &&
          other.format == format &&
          other.maxCash == maxCash &&
          other.payoutDays == payoutDays &&
          other.performance == performance &&
          other.pieces == pieces &&
          other.productProvided == productProvided &&
          other.proposedBy == proposedBy &&
          other.revisionScope == revisionScope &&
          other.startDate == startDate &&
          other.title == title &&
          other.usageRights == usageRights &&
          other.version == version;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (brandConfirmed.hashCode) +
      (creatorConfirmed.hashCode) +
      (fee.hashCode) +
      (format.hashCode) +
      (maxCash.hashCode) +
      (payoutDays.hashCode) +
      (performance == null ? 0 : performance!.hashCode) +
      (pieces.hashCode) +
      (productProvided.hashCode) +
      (proposedBy.hashCode) +
      (revisionScope.hashCode) +
      (startDate.hashCode) +
      (title.hashCode) +
      (usageRights.hashCode) +
      (version.hashCode);

  @override
  String toString() =>
      'TermsVersionModel[brandConfirmed=$brandConfirmed, creatorConfirmed=$creatorConfirmed, fee=$fee, format=$format, maxCash=$maxCash, payoutDays=$payoutDays, performance=$performance, pieces=$pieces, productProvided=$productProvided, proposedBy=$proposedBy, revisionScope=$revisionScope, startDate=$startDate, title=$title, usageRights=$usageRights, version=$version]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'brandConfirmed'] = this.brandConfirmed;
    json[r'creatorConfirmed'] = this.creatorConfirmed;
    json[r'fee'] = this.fee;
    json[r'format'] = this.format;
    json[r'maxCash'] = this.maxCash;
    json[r'payoutDays'] = this.payoutDays;
    if (this.performance != null) {
      json[r'performance'] = this.performance;
    } else {
      json[r'performance'] = null;
    }
    json[r'pieces'] = this.pieces;
    json[r'productProvided'] = this.productProvided;
    json[r'proposedBy'] = this.proposedBy;
    json[r'revisionScope'] = this.revisionScope;
    json[r'startDate'] = _dateFormatter.format(this.startDate);
    json[r'title'] = this.title;
    json[r'usageRights'] = this.usageRights;
    json[r'version'] = this.version;
    return json;
  }

  /// Returns a new [TermsVersionModel] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static TermsVersionModel? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'brandConfirmed'),
            'Required key "TermsVersionModel[brandConfirmed]" is missing from JSON.');
        assert(json[r'brandConfirmed'] != null,
            'Required key "TermsVersionModel[brandConfirmed]" has a null value in JSON.');
        assert(json.containsKey(r'creatorConfirmed'),
            'Required key "TermsVersionModel[creatorConfirmed]" is missing from JSON.');
        assert(json[r'creatorConfirmed'] != null,
            'Required key "TermsVersionModel[creatorConfirmed]" has a null value in JSON.');
        assert(json.containsKey(r'fee'),
            'Required key "TermsVersionModel[fee]" is missing from JSON.');
        assert(json[r'fee'] != null,
            'Required key "TermsVersionModel[fee]" has a null value in JSON.');
        assert(json.containsKey(r'format'),
            'Required key "TermsVersionModel[format]" is missing from JSON.');
        assert(json[r'format'] != null,
            'Required key "TermsVersionModel[format]" has a null value in JSON.');
        assert(json.containsKey(r'maxCash'),
            'Required key "TermsVersionModel[maxCash]" is missing from JSON.');
        assert(json[r'maxCash'] != null,
            'Required key "TermsVersionModel[maxCash]" has a null value in JSON.');
        assert(json.containsKey(r'payoutDays'),
            'Required key "TermsVersionModel[payoutDays]" is missing from JSON.');
        assert(json[r'payoutDays'] != null,
            'Required key "TermsVersionModel[payoutDays]" has a null value in JSON.');
        assert(json.containsKey(r'performance'),
            'Required key "TermsVersionModel[performance]" is missing from JSON.');
        assert(json.containsKey(r'pieces'),
            'Required key "TermsVersionModel[pieces]" is missing from JSON.');
        assert(json[r'pieces'] != null,
            'Required key "TermsVersionModel[pieces]" has a null value in JSON.');
        assert(json.containsKey(r'productProvided'),
            'Required key "TermsVersionModel[productProvided]" is missing from JSON.');
        assert(json[r'productProvided'] != null,
            'Required key "TermsVersionModel[productProvided]" has a null value in JSON.');
        assert(json.containsKey(r'proposedBy'),
            'Required key "TermsVersionModel[proposedBy]" is missing from JSON.');
        assert(json[r'proposedBy'] != null,
            'Required key "TermsVersionModel[proposedBy]" has a null value in JSON.');
        assert(json.containsKey(r'revisionScope'),
            'Required key "TermsVersionModel[revisionScope]" is missing from JSON.');
        assert(json[r'revisionScope'] != null,
            'Required key "TermsVersionModel[revisionScope]" has a null value in JSON.');
        assert(json.containsKey(r'startDate'),
            'Required key "TermsVersionModel[startDate]" is missing from JSON.');
        assert(json[r'startDate'] != null,
            'Required key "TermsVersionModel[startDate]" has a null value in JSON.');
        assert(json.containsKey(r'title'),
            'Required key "TermsVersionModel[title]" is missing from JSON.');
        assert(json[r'title'] != null,
            'Required key "TermsVersionModel[title]" has a null value in JSON.');
        assert(json.containsKey(r'usageRights'),
            'Required key "TermsVersionModel[usageRights]" is missing from JSON.');
        assert(json[r'usageRights'] != null,
            'Required key "TermsVersionModel[usageRights]" has a null value in JSON.');
        assert(json.containsKey(r'version'),
            'Required key "TermsVersionModel[version]" is missing from JSON.');
        assert(json[r'version'] != null,
            'Required key "TermsVersionModel[version]" has a null value in JSON.');
        return true;
      }());

      return TermsVersionModel(
        brandConfirmed: mapValueOfType<bool>(json, r'brandConfirmed')!,
        creatorConfirmed: mapValueOfType<bool>(json, r'creatorConfirmed')!,
        fee: mapValueOfType<int>(json, r'fee')!,
        format: ContentFormat.fromJson(json[r'format'])!,
        maxCash: mapValueOfType<int>(json, r'maxCash')!,
        payoutDays: mapValueOfType<int>(json, r'payoutDays')!,
        performance: TermsPerformanceModel.fromJson(json[r'performance']),
        pieces: mapValueOfType<int>(json, r'pieces')!,
        productProvided: mapValueOfType<bool>(json, r'productProvided')!,
        proposedBy: TermsProposer.fromJson(json[r'proposedBy'])!,
        revisionScope: RevisionScope.fromJson(json[r'revisionScope'])!,
        startDate: mapDateTime(json, r'startDate', r'')!,
        title: mapValueOfType<String>(json, r'title')!,
        usageRights: BrandUsageRights.fromJson(json[r'usageRights'])!,
        version: mapValueOfType<int>(json, r'version')!,
      );
    }
    return null;
  }

  static List<TermsVersionModel> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <TermsVersionModel>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = TermsVersionModel.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, TermsVersionModel> mapFromJson(dynamic json) {
    final map = <String, TermsVersionModel>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = TermsVersionModel.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of TermsVersionModel-objects as value to a dart map
  static Map<String, List<TermsVersionModel>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<TermsVersionModel>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = TermsVersionModel.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'brandConfirmed',
    'creatorConfirmed',
    'fee',
    'format',
    'maxCash',
    'payoutDays',
    'performance',
    'pieces',
    'productProvided',
    'proposedBy',
    'revisionScope',
    'startDate',
    'title',
    'usageRights',
    'version',
  };
}
