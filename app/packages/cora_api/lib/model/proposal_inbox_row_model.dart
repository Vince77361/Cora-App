//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class ProposalInboxRowModel {
  /// Returns a new [ProposalInboxRowModel] instance.
  ProposalInboxRowModel({
    required this.collaborationId,
    required this.counter,
    required this.counterpart,
    required this.endKind,
    required this.format,
    required this.group,
    required this.kind,
    required this.myDropReason,
    required this.pieces,
    required this.updatedAt,
    required this.version,
  });

  String collaborationId;

  /// 상대가 쓴 최신 판본이 번호 2 이상이면 true(역제안).
  bool counter;

  ProposalCounterpartModel counterpart;

  /// 끝난 제안(ENDED)의 갈래. AGREED: 합의 완료, ENDED: 사유를 골라 끝냄, EXPIRED: 기한이 지나 끝남. 그 밖에는 null.
  ProposalEndKind? endKind;

  ContentFormat format;

  /// MY_TURN: 내가 응답할 차례. WAITING: 상대 대기. ENDED: 끝난 제안.
  ProposalGroup group;

  ProposalInboxRowModelKindEnum kind;

  /// 그만두는 이유. 서버에만 남고 상대에게는 알리지 않는다(상대는 \"이번에는 함께하기 어렵대요.\"만 본다).
  DropReasonChoice? myDropReason;

  int pieces;

  /// 최신 판본의 확인이나 협업 상태가 마지막으로 바뀐 시각.
  DateTime updatedAt;

  /// 최신 판본의 번호.
  int version;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProposalInboxRowModel &&
          other.collaborationId == collaborationId &&
          other.counter == counter &&
          other.counterpart == counterpart &&
          other.endKind == endKind &&
          other.format == format &&
          other.group == group &&
          other.kind == kind &&
          other.myDropReason == myDropReason &&
          other.pieces == pieces &&
          other.updatedAt == updatedAt &&
          other.version == version;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (collaborationId.hashCode) +
      (counter.hashCode) +
      (counterpart.hashCode) +
      (endKind == null ? 0 : endKind!.hashCode) +
      (format.hashCode) +
      (group.hashCode) +
      (kind.hashCode) +
      (myDropReason == null ? 0 : myDropReason!.hashCode) +
      (pieces.hashCode) +
      (updatedAt.hashCode) +
      (version.hashCode);

  @override
  String toString() =>
      'ProposalInboxRowModel[collaborationId=$collaborationId, counter=$counter, counterpart=$counterpart, endKind=$endKind, format=$format, group=$group, kind=$kind, myDropReason=$myDropReason, pieces=$pieces, updatedAt=$updatedAt, version=$version]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'collaborationId'] = this.collaborationId;
    json[r'counter'] = this.counter;
    json[r'counterpart'] = this.counterpart;
    if (this.endKind != null) {
      json[r'endKind'] = this.endKind;
    } else {
      json[r'endKind'] = null;
    }
    json[r'format'] = this.format;
    json[r'group'] = this.group;
    json[r'kind'] = this.kind;
    if (this.myDropReason != null) {
      json[r'myDropReason'] = this.myDropReason;
    } else {
      json[r'myDropReason'] = null;
    }
    json[r'pieces'] = this.pieces;
    json[r'updatedAt'] = this.updatedAt.toUtc().toIso8601String();
    json[r'version'] = this.version;
    return json;
  }

  /// Returns a new [ProposalInboxRowModel] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ProposalInboxRowModel? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'collaborationId'),
            'Required key "ProposalInboxRowModel[collaborationId]" is missing from JSON.');
        assert(json[r'collaborationId'] != null,
            'Required key "ProposalInboxRowModel[collaborationId]" has a null value in JSON.');
        assert(json.containsKey(r'counter'),
            'Required key "ProposalInboxRowModel[counter]" is missing from JSON.');
        assert(json[r'counter'] != null,
            'Required key "ProposalInboxRowModel[counter]" has a null value in JSON.');
        assert(json.containsKey(r'counterpart'),
            'Required key "ProposalInboxRowModel[counterpart]" is missing from JSON.');
        assert(json[r'counterpart'] != null,
            'Required key "ProposalInboxRowModel[counterpart]" has a null value in JSON.');
        assert(json.containsKey(r'endKind'),
            'Required key "ProposalInboxRowModel[endKind]" is missing from JSON.');
        assert(json.containsKey(r'format'),
            'Required key "ProposalInboxRowModel[format]" is missing from JSON.');
        assert(json[r'format'] != null,
            'Required key "ProposalInboxRowModel[format]" has a null value in JSON.');
        assert(json.containsKey(r'group'),
            'Required key "ProposalInboxRowModel[group]" is missing from JSON.');
        assert(json[r'group'] != null,
            'Required key "ProposalInboxRowModel[group]" has a null value in JSON.');
        assert(json.containsKey(r'kind'),
            'Required key "ProposalInboxRowModel[kind]" is missing from JSON.');
        assert(json[r'kind'] != null,
            'Required key "ProposalInboxRowModel[kind]" has a null value in JSON.');
        assert(json.containsKey(r'myDropReason'),
            'Required key "ProposalInboxRowModel[myDropReason]" is missing from JSON.');
        assert(json.containsKey(r'pieces'),
            'Required key "ProposalInboxRowModel[pieces]" is missing from JSON.');
        assert(json[r'pieces'] != null,
            'Required key "ProposalInboxRowModel[pieces]" has a null value in JSON.');
        assert(json.containsKey(r'updatedAt'),
            'Required key "ProposalInboxRowModel[updatedAt]" is missing from JSON.');
        assert(json[r'updatedAt'] != null,
            'Required key "ProposalInboxRowModel[updatedAt]" has a null value in JSON.');
        assert(json.containsKey(r'version'),
            'Required key "ProposalInboxRowModel[version]" is missing from JSON.');
        assert(json[r'version'] != null,
            'Required key "ProposalInboxRowModel[version]" has a null value in JSON.');
        return true;
      }());

      return ProposalInboxRowModel(
        collaborationId: mapValueOfType<String>(json, r'collaborationId')!,
        counter: mapValueOfType<bool>(json, r'counter')!,
        counterpart: ProposalCounterpartModel.fromJson(json[r'counterpart'])!,
        endKind: ProposalEndKind.fromJson(json[r'endKind']),
        format: ContentFormat.fromJson(json[r'format'])!,
        group: ProposalGroup.fromJson(json[r'group'])!,
        kind: ProposalInboxRowModelKindEnum.fromJson(json[r'kind'])!,
        myDropReason: DropReasonChoice.fromJson(json[r'myDropReason']),
        pieces: mapValueOfType<int>(json, r'pieces')!,
        updatedAt: mapDateTime(json, r'updatedAt', r'')!,
        version: mapValueOfType<int>(json, r'version')!,
      );
    }
    return null;
  }

  static List<ProposalInboxRowModel> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <ProposalInboxRowModel>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ProposalInboxRowModel.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ProposalInboxRowModel> mapFromJson(dynamic json) {
    final map = <String, ProposalInboxRowModel>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ProposalInboxRowModel.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ProposalInboxRowModel-objects as value to a dart map
  static Map<String, List<ProposalInboxRowModel>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<ProposalInboxRowModel>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ProposalInboxRowModel.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'collaborationId',
    'counter',
    'counterpart',
    'endKind',
    'format',
    'group',
    'kind',
    'myDropReason',
    'pieces',
    'updatedAt',
    'version',
  };
}

enum ProposalInboxRowModelKindEnum {
  BRAND_CONTRACT._(r'BRAND_CONTRACT'),
  ;

  /// Instantiate a new enum with the provided value.
  const ProposalInboxRowModelKindEnum._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [ProposalInboxRowModelKindEnum] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static ProposalInboxRowModelKindEnum? fromJson(dynamic value) =>
      ProposalInboxRowModelKindEnumTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [ProposalInboxRowModelKindEnum]
  /// that were successfully decoded from the passed [JSON][json].
  static List<ProposalInboxRowModelKindEnum> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <ProposalInboxRowModelKindEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ProposalInboxRowModelKindEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [ProposalInboxRowModelKindEnum] to String,
/// and [decode] dynamic data back to [ProposalInboxRowModelKindEnum].
class ProposalInboxRowModelKindEnumTypeTransformer {
  factory ProposalInboxRowModelKindEnumTypeTransformer() =>
      _instance ??= const ProposalInboxRowModelKindEnumTypeTransformer._();

  const ProposalInboxRowModelKindEnumTypeTransformer._();

  String encode(ProposalInboxRowModelKindEnum data) => data._value;

  /// Returns the instance of [ProposalInboxRowModelKindEnum] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  ProposalInboxRowModelKindEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data is ProposalInboxRowModelKindEnum) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'BRAND_CONTRACT':
          return ProposalInboxRowModelKindEnum.BRAND_CONTRACT;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static ProposalInboxRowModelKindEnumTypeTransformer? _instance;
}
