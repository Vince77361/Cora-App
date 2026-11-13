//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class EndedOfferModel {
  /// Returns a new [EndedOfferModel] instance.
  EndedOfferModel({
    required this.endReason,
    required this.endedBy,
    required this.id,
    required this.status,
  });

  OfferEndReason endReason;

  /// 끝낸 쪽.
  OfferParty endedBy;

  String id;

  OfferEndStatus status;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EndedOfferModel &&
          other.endReason == endReason &&
          other.endedBy == endedBy &&
          other.id == id &&
          other.status == status;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (endReason.hashCode) +
      (endedBy.hashCode) +
      (id.hashCode) +
      (status.hashCode);

  @override
  String toString() =>
      'EndedOfferModel[endReason=$endReason, endedBy=$endedBy, id=$id, status=$status]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'endReason'] = this.endReason;
    json[r'endedBy'] = this.endedBy;
    json[r'id'] = this.id;
    json[r'status'] = this.status;
    return json;
  }

  /// Returns a new [EndedOfferModel] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static EndedOfferModel? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'endReason'),
            'Required key "EndedOfferModel[endReason]" is missing from JSON.');
        assert(json[r'endReason'] != null,
            'Required key "EndedOfferModel[endReason]" has a null value in JSON.');
        assert(json.containsKey(r'endedBy'),
            'Required key "EndedOfferModel[endedBy]" is missing from JSON.');
        assert(json[r'endedBy'] != null,
            'Required key "EndedOfferModel[endedBy]" has a null value in JSON.');
        assert(json.containsKey(r'id'),
            'Required key "EndedOfferModel[id]" is missing from JSON.');
        assert(json[r'id'] != null,
            'Required key "EndedOfferModel[id]" has a null value in JSON.');
        assert(json.containsKey(r'status'),
            'Required key "EndedOfferModel[status]" is missing from JSON.');
        assert(json[r'status'] != null,
            'Required key "EndedOfferModel[status]" has a null value in JSON.');
        return true;
      }());

      return EndedOfferModel(
        endReason: OfferEndReason.fromJson(json[r'endReason'])!,
        endedBy: OfferParty.fromJson(json[r'endedBy'])!,
        id: mapValueOfType<String>(json, r'id')!,
        status: OfferEndStatus.fromJson(json[r'status'])!,
      );
    }
    return null;
  }

  static List<EndedOfferModel> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <EndedOfferModel>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = EndedOfferModel.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, EndedOfferModel> mapFromJson(dynamic json) {
    final map = <String, EndedOfferModel>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = EndedOfferModel.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of EndedOfferModel-objects as value to a dart map
  static Map<String, List<EndedOfferModel>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<EndedOfferModel>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = EndedOfferModel.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'endReason',
    'endedBy',
    'id',
    'status',
  };
}
