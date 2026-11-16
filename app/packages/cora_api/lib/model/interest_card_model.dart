//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class InterestCardModel {
  /// Returns a new [InterestCardModel] instance.
  InterestCardModel({
    required this.collaborationId,
    required this.feeBand,
    required this.feeLabel,
    required this.hasProposal,
    required this.headline,
    required this.name,
    required this.photoUrl,
    required this.shortName,
    required this.startFrom,
    required this.state,
    required this.targetId,
    required this.targetKind,
  });

  /// 서로 관심이면 그 협업의 id.
  String? collaborationId;

  /// 브랜드가 볼 때 그 크리에이터의 희망 제작비 구간. 크리에이터가 볼 때는 null.
  FeeBand? feeBand;

  /// 카드 아래 글의 금액. 서로 관심이면 최신 판본의 제작비, 아니면 브랜드는 내가 만든 제안의 금액(없으면 null이고 앱이 feeBand를 보여 준다), 크리에이터는 캠페인의 제작비.
  int? feeLabel;

  /// 내가 보낸 관심에 제안(제작비, 혜택, 성과 추가)이 붙어 있다. 브랜드만 true일 수 있다.
  bool hasProposal;

  /// 크리에이터 카드의 한 줄 또는 캠페인 한 줄.
  String? headline;

  /// 크리에이터의 활동 이름 또는 브랜드 이름.
  String name;

  String? photoUrl;

  /// \"{X}의 …\" 꼴이면 X, 아니면 이름 전체. 04의 버튼에 쓴다.
  String shortName;

  /// 서로 관심일 때만 최신 판본의 제작 시작. 아니면 null(일정 협의).
  DateTime? startFrom;

  InterestState state;

  String targetId;

  /// 브랜드는 CREATOR, 크리에이터는 CAMPAIGN.
  SwipeTargetKind targetKind;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InterestCardModel &&
          other.collaborationId == collaborationId &&
          other.feeBand == feeBand &&
          other.feeLabel == feeLabel &&
          other.hasProposal == hasProposal &&
          other.headline == headline &&
          other.name == name &&
          other.photoUrl == photoUrl &&
          other.shortName == shortName &&
          other.startFrom == startFrom &&
          other.state == state &&
          other.targetId == targetId &&
          other.targetKind == targetKind;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (collaborationId == null ? 0 : collaborationId!.hashCode) +
      (feeBand == null ? 0 : feeBand!.hashCode) +
      (feeLabel == null ? 0 : feeLabel!.hashCode) +
      (hasProposal.hashCode) +
      (headline == null ? 0 : headline!.hashCode) +
      (name.hashCode) +
      (photoUrl == null ? 0 : photoUrl!.hashCode) +
      (shortName.hashCode) +
      (startFrom == null ? 0 : startFrom!.hashCode) +
      (state.hashCode) +
      (targetId.hashCode) +
      (targetKind.hashCode);

  @override
  String toString() =>
      'InterestCardModel[collaborationId=$collaborationId, feeBand=$feeBand, feeLabel=$feeLabel, hasProposal=$hasProposal, headline=$headline, name=$name, photoUrl=$photoUrl, shortName=$shortName, startFrom=$startFrom, state=$state, targetId=$targetId, targetKind=$targetKind]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.collaborationId != null) {
      json[r'collaborationId'] = this.collaborationId;
    } else {
      json[r'collaborationId'] = null;
    }
    if (this.feeBand != null) {
      json[r'feeBand'] = this.feeBand;
    } else {
      json[r'feeBand'] = null;
    }
    if (this.feeLabel != null) {
      json[r'feeLabel'] = this.feeLabel;
    } else {
      json[r'feeLabel'] = null;
    }
    json[r'hasProposal'] = this.hasProposal;
    if (this.headline != null) {
      json[r'headline'] = this.headline;
    } else {
      json[r'headline'] = null;
    }
    json[r'name'] = this.name;
    if (this.photoUrl != null) {
      json[r'photoUrl'] = this.photoUrl;
    } else {
      json[r'photoUrl'] = null;
    }
    json[r'shortName'] = this.shortName;
    if (this.startFrom != null) {
      json[r'startFrom'] = _dateFormatter.format(this.startFrom!);
    } else {
      json[r'startFrom'] = null;
    }
    json[r'state'] = this.state;
    json[r'targetId'] = this.targetId;
    json[r'targetKind'] = this.targetKind;
    return json;
  }

  /// Returns a new [InterestCardModel] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static InterestCardModel? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'collaborationId'),
            'Required key "InterestCardModel[collaborationId]" is missing from JSON.');
        assert(json.containsKey(r'feeBand'),
            'Required key "InterestCardModel[feeBand]" is missing from JSON.');
        assert(json.containsKey(r'feeLabel'),
            'Required key "InterestCardModel[feeLabel]" is missing from JSON.');
        assert(json.containsKey(r'hasProposal'),
            'Required key "InterestCardModel[hasProposal]" is missing from JSON.');
        assert(json[r'hasProposal'] != null,
            'Required key "InterestCardModel[hasProposal]" has a null value in JSON.');
        assert(json.containsKey(r'headline'),
            'Required key "InterestCardModel[headline]" is missing from JSON.');
        assert(json.containsKey(r'name'),
            'Required key "InterestCardModel[name]" is missing from JSON.');
        assert(json[r'name'] != null,
            'Required key "InterestCardModel[name]" has a null value in JSON.');
        assert(json.containsKey(r'photoUrl'),
            'Required key "InterestCardModel[photoUrl]" is missing from JSON.');
        assert(json.containsKey(r'shortName'),
            'Required key "InterestCardModel[shortName]" is missing from JSON.');
        assert(json[r'shortName'] != null,
            'Required key "InterestCardModel[shortName]" has a null value in JSON.');
        assert(json.containsKey(r'startFrom'),
            'Required key "InterestCardModel[startFrom]" is missing from JSON.');
        assert(json.containsKey(r'state'),
            'Required key "InterestCardModel[state]" is missing from JSON.');
        assert(json[r'state'] != null,
            'Required key "InterestCardModel[state]" has a null value in JSON.');
        assert(json.containsKey(r'targetId'),
            'Required key "InterestCardModel[targetId]" is missing from JSON.');
        assert(json[r'targetId'] != null,
            'Required key "InterestCardModel[targetId]" has a null value in JSON.');
        assert(json.containsKey(r'targetKind'),
            'Required key "InterestCardModel[targetKind]" is missing from JSON.');
        assert(json[r'targetKind'] != null,
            'Required key "InterestCardModel[targetKind]" has a null value in JSON.');
        return true;
      }());

      return InterestCardModel(
        collaborationId: mapValueOfType<String>(json, r'collaborationId'),
        feeBand: FeeBand.fromJson(json[r'feeBand']),
        feeLabel: mapValueOfType<int>(json, r'feeLabel'),
        hasProposal: mapValueOfType<bool>(json, r'hasProposal')!,
        headline: mapValueOfType<String>(json, r'headline'),
        name: mapValueOfType<String>(json, r'name')!,
        photoUrl: mapValueOfType<String>(json, r'photoUrl'),
        shortName: mapValueOfType<String>(json, r'shortName')!,
        startFrom: mapDateTime(json, r'startFrom', r''),
        state: InterestState.fromJson(json[r'state'])!,
        targetId: mapValueOfType<String>(json, r'targetId')!,
        targetKind: SwipeTargetKind.fromJson(json[r'targetKind'])!,
      );
    }
    return null;
  }

  static List<InterestCardModel> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <InterestCardModel>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = InterestCardModel.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, InterestCardModel> mapFromJson(dynamic json) {
    final map = <String, InterestCardModel>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = InterestCardModel.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of InterestCardModel-objects as value to a dart map
  static Map<String, List<InterestCardModel>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<InterestCardModel>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = InterestCardModel.listFromJson(
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
    'feeBand',
    'feeLabel',
    'hasProposal',
    'headline',
    'name',
    'photoUrl',
    'shortName',
    'startFrom',
    'state',
    'targetId',
    'targetKind',
  };
}
