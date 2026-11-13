//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class ProposalRowModel {
  /// Returns a new [ProposalRowModel] instance.
  ProposalRowModel({
    required this.collaborationId,
    required this.counter,
    required this.counterpart,
    required this.daysLeft,
    required this.endKind,
    required this.endReason,
    required this.format,
    required this.group,
    required this.offerId,
    required this.pieces,
    required this.version,
  });

  /// 합의해 만들어진 협업의 id. 합의 전이면 null.
  String? collaborationId;

  /// 상대가 쓴 최신 판본이 번호 2 이상이면 true(역제안).
  bool counter;

  ProposalCounterpartModel counterpart;

  /// 상대 대기(WAITING)일 때 남은 응답 기한(올림). 하루가 안 남았으면 0. 그 밖에는 null.
  int? daysLeft;

  /// 끝난 제안(ENDED)의 갈래. AGREED: 합의 완료, ENDED: 사유를 골라 끝냄, EXPIRED: 기한이 지나 끝남. 그 밖에는 null.
  ProposalEndKind? endKind;

  /// 끝낸 쪽이 고른 사유. 사유 없이 끝났으면 null.
  OfferEndReason? endReason;

  ContentFormat format;

  /// MY_TURN: 내가 응답할 차례. WAITING: 상대 대기. ENDED: 끝난 제안.
  ProposalGroup group;

  String offerId;

  int pieces;

  /// 최신 판본의 번호.
  int version;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProposalRowModel &&
          other.collaborationId == collaborationId &&
          other.counter == counter &&
          other.counterpart == counterpart &&
          other.daysLeft == daysLeft &&
          other.endKind == endKind &&
          other.endReason == endReason &&
          other.format == format &&
          other.group == group &&
          other.offerId == offerId &&
          other.pieces == pieces &&
          other.version == version;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (collaborationId == null ? 0 : collaborationId!.hashCode) +
      (counter.hashCode) +
      (counterpart.hashCode) +
      (daysLeft == null ? 0 : daysLeft!.hashCode) +
      (endKind == null ? 0 : endKind!.hashCode) +
      (endReason == null ? 0 : endReason!.hashCode) +
      (format.hashCode) +
      (group.hashCode) +
      (offerId.hashCode) +
      (pieces.hashCode) +
      (version.hashCode);

  @override
  String toString() =>
      'ProposalRowModel[collaborationId=$collaborationId, counter=$counter, counterpart=$counterpart, daysLeft=$daysLeft, endKind=$endKind, endReason=$endReason, format=$format, group=$group, offerId=$offerId, pieces=$pieces, version=$version]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.collaborationId != null) {
      json[r'collaborationId'] = this.collaborationId;
    } else {
      json[r'collaborationId'] = null;
    }
    json[r'counter'] = this.counter;
    json[r'counterpart'] = this.counterpart;
    if (this.daysLeft != null) {
      json[r'daysLeft'] = this.daysLeft;
    } else {
      json[r'daysLeft'] = null;
    }
    if (this.endKind != null) {
      json[r'endKind'] = this.endKind;
    } else {
      json[r'endKind'] = null;
    }
    if (this.endReason != null) {
      json[r'endReason'] = this.endReason;
    } else {
      json[r'endReason'] = null;
    }
    json[r'format'] = this.format;
    json[r'group'] = this.group;
    json[r'offerId'] = this.offerId;
    json[r'pieces'] = this.pieces;
    json[r'version'] = this.version;
    return json;
  }

  /// Returns a new [ProposalRowModel] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ProposalRowModel? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'collaborationId'),
            'Required key "ProposalRowModel[collaborationId]" is missing from JSON.');
        assert(json.containsKey(r'counter'),
            'Required key "ProposalRowModel[counter]" is missing from JSON.');
        assert(json[r'counter'] != null,
            'Required key "ProposalRowModel[counter]" has a null value in JSON.');
        assert(json.containsKey(r'counterpart'),
            'Required key "ProposalRowModel[counterpart]" is missing from JSON.');
        assert(json[r'counterpart'] != null,
            'Required key "ProposalRowModel[counterpart]" has a null value in JSON.');
        assert(json.containsKey(r'daysLeft'),
            'Required key "ProposalRowModel[daysLeft]" is missing from JSON.');
        assert(json.containsKey(r'endKind'),
            'Required key "ProposalRowModel[endKind]" is missing from JSON.');
        assert(json.containsKey(r'endReason'),
            'Required key "ProposalRowModel[endReason]" is missing from JSON.');
        assert(json.containsKey(r'format'),
            'Required key "ProposalRowModel[format]" is missing from JSON.');
        assert(json[r'format'] != null,
            'Required key "ProposalRowModel[format]" has a null value in JSON.');
        assert(json.containsKey(r'group'),
            'Required key "ProposalRowModel[group]" is missing from JSON.');
        assert(json[r'group'] != null,
            'Required key "ProposalRowModel[group]" has a null value in JSON.');
        assert(json.containsKey(r'offerId'),
            'Required key "ProposalRowModel[offerId]" is missing from JSON.');
        assert(json[r'offerId'] != null,
            'Required key "ProposalRowModel[offerId]" has a null value in JSON.');
        assert(json.containsKey(r'pieces'),
            'Required key "ProposalRowModel[pieces]" is missing from JSON.');
        assert(json[r'pieces'] != null,
            'Required key "ProposalRowModel[pieces]" has a null value in JSON.');
        assert(json.containsKey(r'version'),
            'Required key "ProposalRowModel[version]" is missing from JSON.');
        assert(json[r'version'] != null,
            'Required key "ProposalRowModel[version]" has a null value in JSON.');
        return true;
      }());

      return ProposalRowModel(
        collaborationId: mapValueOfType<String>(json, r'collaborationId'),
        counter: mapValueOfType<bool>(json, r'counter')!,
        counterpart: ProposalCounterpartModel.fromJson(json[r'counterpart'])!,
        daysLeft: mapValueOfType<int>(json, r'daysLeft'),
        endKind: ProposalEndKind.fromJson(json[r'endKind']),
        endReason: OfferEndReason.fromJson(json[r'endReason']),
        format: ContentFormat.fromJson(json[r'format'])!,
        group: ProposalGroup.fromJson(json[r'group'])!,
        offerId: mapValueOfType<String>(json, r'offerId')!,
        pieces: mapValueOfType<int>(json, r'pieces')!,
        version: mapValueOfType<int>(json, r'version')!,
      );
    }
    return null;
  }

  static List<ProposalRowModel> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <ProposalRowModel>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ProposalRowModel.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ProposalRowModel> mapFromJson(dynamic json) {
    final map = <String, ProposalRowModel>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ProposalRowModel.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ProposalRowModel-objects as value to a dart map
  static Map<String, List<ProposalRowModel>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<ProposalRowModel>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ProposalRowModel.listFromJson(
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
    'daysLeft',
    'endKind',
    'endReason',
    'format',
    'group',
    'offerId',
    'pieces',
    'version',
  };
}
