//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class CompareSideModel {
  /// Returns a new [CompareSideModel] instance.
  CompareSideModel({
    required this.collaborationId,
    required this.creatorId,
    required this.faceOk,
    required this.fee,
    required this.feeBand,
    required this.format,
    required this.name,
    required this.perfCap,
    required this.perfRate,
    required this.photoUrl,
    required this.pieces,
    required this.productProvided,
    required this.shortName,
    required this.startDate,
    required this.state,
    required this.usageRights,
  });

  String? collaborationId;

  String creatorId;

  /// 크리에이터의 원칙 3번: 얼굴 출연이 괜찮은가.
  bool faceOk;

  /// 서로 관심이면 최신 판본의 제작비, 아니면 내 제안의 금액, 없으면 null.
  int? fee;

  /// fee가 null일 때 앱이 \"30만 원대\"로 보여 주는 희망 제작비 구간.
  FeeBand feeBand;

  ContentFormat format;

  String name;

  int? perfCap;

  /// 성과 추가의 단가(1,000회당 원). perfCap과 같은 출처(최신 판본, 내 제안, 없으면 null).
  int? perfRate;

  String? photoUrl;

  int pieces;

  bool productProvided;

  /// \"{X}의 …\" 꼴이면 X, 아니면 이름 전체.
  String shortName;

  DateTime? startDate;

  InterestState state;

  BrandUsageRights usageRights;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CompareSideModel &&
          other.collaborationId == collaborationId &&
          other.creatorId == creatorId &&
          other.faceOk == faceOk &&
          other.fee == fee &&
          other.feeBand == feeBand &&
          other.format == format &&
          other.name == name &&
          other.perfCap == perfCap &&
          other.perfRate == perfRate &&
          other.photoUrl == photoUrl &&
          other.pieces == pieces &&
          other.productProvided == productProvided &&
          other.shortName == shortName &&
          other.startDate == startDate &&
          other.state == state &&
          other.usageRights == usageRights;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (collaborationId == null ? 0 : collaborationId!.hashCode) +
      (creatorId.hashCode) +
      (faceOk.hashCode) +
      (fee == null ? 0 : fee!.hashCode) +
      (feeBand.hashCode) +
      (format.hashCode) +
      (name.hashCode) +
      (perfCap == null ? 0 : perfCap!.hashCode) +
      (perfRate == null ? 0 : perfRate!.hashCode) +
      (photoUrl == null ? 0 : photoUrl!.hashCode) +
      (pieces.hashCode) +
      (productProvided.hashCode) +
      (shortName.hashCode) +
      (startDate == null ? 0 : startDate!.hashCode) +
      (state.hashCode) +
      (usageRights.hashCode);

  @override
  String toString() =>
      'CompareSideModel[collaborationId=$collaborationId, creatorId=$creatorId, faceOk=$faceOk, fee=$fee, feeBand=$feeBand, format=$format, name=$name, perfCap=$perfCap, perfRate=$perfRate, photoUrl=$photoUrl, pieces=$pieces, productProvided=$productProvided, shortName=$shortName, startDate=$startDate, state=$state, usageRights=$usageRights]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.collaborationId != null) {
      json[r'collaborationId'] = this.collaborationId;
    } else {
      json[r'collaborationId'] = null;
    }
    json[r'creatorId'] = this.creatorId;
    json[r'faceOk'] = this.faceOk;
    if (this.fee != null) {
      json[r'fee'] = this.fee;
    } else {
      json[r'fee'] = null;
    }
    json[r'feeBand'] = this.feeBand;
    json[r'format'] = this.format;
    json[r'name'] = this.name;
    if (this.perfCap != null) {
      json[r'perfCap'] = this.perfCap;
    } else {
      json[r'perfCap'] = null;
    }
    if (this.perfRate != null) {
      json[r'perfRate'] = this.perfRate;
    } else {
      json[r'perfRate'] = null;
    }
    if (this.photoUrl != null) {
      json[r'photoUrl'] = this.photoUrl;
    } else {
      json[r'photoUrl'] = null;
    }
    json[r'pieces'] = this.pieces;
    json[r'productProvided'] = this.productProvided;
    json[r'shortName'] = this.shortName;
    if (this.startDate != null) {
      json[r'startDate'] = _dateFormatter.format(this.startDate!);
    } else {
      json[r'startDate'] = null;
    }
    json[r'state'] = this.state;
    json[r'usageRights'] = this.usageRights;
    return json;
  }

  /// Returns a new [CompareSideModel] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static CompareSideModel? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'collaborationId'),
            'Required key "CompareSideModel[collaborationId]" is missing from JSON.');
        assert(json.containsKey(r'creatorId'),
            'Required key "CompareSideModel[creatorId]" is missing from JSON.');
        assert(json[r'creatorId'] != null,
            'Required key "CompareSideModel[creatorId]" has a null value in JSON.');
        assert(json.containsKey(r'faceOk'),
            'Required key "CompareSideModel[faceOk]" is missing from JSON.');
        assert(json[r'faceOk'] != null,
            'Required key "CompareSideModel[faceOk]" has a null value in JSON.');
        assert(json.containsKey(r'fee'),
            'Required key "CompareSideModel[fee]" is missing from JSON.');
        assert(json.containsKey(r'feeBand'),
            'Required key "CompareSideModel[feeBand]" is missing from JSON.');
        assert(json[r'feeBand'] != null,
            'Required key "CompareSideModel[feeBand]" has a null value in JSON.');
        assert(json.containsKey(r'format'),
            'Required key "CompareSideModel[format]" is missing from JSON.');
        assert(json[r'format'] != null,
            'Required key "CompareSideModel[format]" has a null value in JSON.');
        assert(json.containsKey(r'name'),
            'Required key "CompareSideModel[name]" is missing from JSON.');
        assert(json[r'name'] != null,
            'Required key "CompareSideModel[name]" has a null value in JSON.');
        assert(json.containsKey(r'perfCap'),
            'Required key "CompareSideModel[perfCap]" is missing from JSON.');
        assert(json.containsKey(r'perfRate'),
            'Required key "CompareSideModel[perfRate]" is missing from JSON.');
        assert(json.containsKey(r'photoUrl'),
            'Required key "CompareSideModel[photoUrl]" is missing from JSON.');
        assert(json.containsKey(r'pieces'),
            'Required key "CompareSideModel[pieces]" is missing from JSON.');
        assert(json[r'pieces'] != null,
            'Required key "CompareSideModel[pieces]" has a null value in JSON.');
        assert(json.containsKey(r'productProvided'),
            'Required key "CompareSideModel[productProvided]" is missing from JSON.');
        assert(json[r'productProvided'] != null,
            'Required key "CompareSideModel[productProvided]" has a null value in JSON.');
        assert(json.containsKey(r'shortName'),
            'Required key "CompareSideModel[shortName]" is missing from JSON.');
        assert(json[r'shortName'] != null,
            'Required key "CompareSideModel[shortName]" has a null value in JSON.');
        assert(json.containsKey(r'startDate'),
            'Required key "CompareSideModel[startDate]" is missing from JSON.');
        assert(json.containsKey(r'state'),
            'Required key "CompareSideModel[state]" is missing from JSON.');
        assert(json[r'state'] != null,
            'Required key "CompareSideModel[state]" has a null value in JSON.');
        assert(json.containsKey(r'usageRights'),
            'Required key "CompareSideModel[usageRights]" is missing from JSON.');
        assert(json[r'usageRights'] != null,
            'Required key "CompareSideModel[usageRights]" has a null value in JSON.');
        return true;
      }());

      return CompareSideModel(
        collaborationId: mapValueOfType<String>(json, r'collaborationId'),
        creatorId: mapValueOfType<String>(json, r'creatorId')!,
        faceOk: mapValueOfType<bool>(json, r'faceOk')!,
        fee: mapValueOfType<int>(json, r'fee'),
        feeBand: FeeBand.fromJson(json[r'feeBand'])!,
        format: ContentFormat.fromJson(json[r'format'])!,
        name: mapValueOfType<String>(json, r'name')!,
        perfCap: mapValueOfType<int>(json, r'perfCap'),
        perfRate: mapValueOfType<int>(json, r'perfRate'),
        photoUrl: mapValueOfType<String>(json, r'photoUrl'),
        pieces: mapValueOfType<int>(json, r'pieces')!,
        productProvided: mapValueOfType<bool>(json, r'productProvided')!,
        shortName: mapValueOfType<String>(json, r'shortName')!,
        startDate: mapDateTime(json, r'startDate', r''),
        state: InterestState.fromJson(json[r'state'])!,
        usageRights: BrandUsageRights.fromJson(json[r'usageRights'])!,
      );
    }
    return null;
  }

  static List<CompareSideModel> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <CompareSideModel>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = CompareSideModel.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, CompareSideModel> mapFromJson(dynamic json) {
    final map = <String, CompareSideModel>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = CompareSideModel.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of CompareSideModel-objects as value to a dart map
  static Map<String, List<CompareSideModel>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<CompareSideModel>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = CompareSideModel.listFromJson(
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
    'creatorId',
    'faceOk',
    'fee',
    'feeBand',
    'format',
    'name',
    'perfCap',
    'perfRate',
    'photoUrl',
    'pieces',
    'productProvided',
    'shortName',
    'startDate',
    'state',
    'usageRights',
  };
}
