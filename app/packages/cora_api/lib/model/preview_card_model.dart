//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class PreviewCardModel {
  /// Returns a new [PreviewCardModel] instance.
  PreviewCardModel({
    required this.creatorId,
    required this.displayName,
    required this.feeBand,
    required this.headline,
    required this.photoUrl,
    this.tags = const [],
  });

  String creatorId;

  String displayName;

  FeeBand feeBand;

  String? headline;

  String? photoUrl;

  List<String> tags;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PreviewCardModel &&
          other.creatorId == creatorId &&
          other.displayName == displayName &&
          other.feeBand == feeBand &&
          other.headline == headline &&
          other.photoUrl == photoUrl &&
          _deepEquality.equals(other.tags, tags);

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (creatorId.hashCode) +
      (displayName.hashCode) +
      (feeBand.hashCode) +
      (headline == null ? 0 : headline!.hashCode) +
      (photoUrl == null ? 0 : photoUrl!.hashCode) +
      (tags.hashCode);

  @override
  String toString() =>
      'PreviewCardModel[creatorId=$creatorId, displayName=$displayName, feeBand=$feeBand, headline=$headline, photoUrl=$photoUrl, tags=$tags]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'creatorId'] = this.creatorId;
    json[r'displayName'] = this.displayName;
    json[r'feeBand'] = this.feeBand;
    if (this.headline != null) {
      json[r'headline'] = this.headline;
    } else {
      json[r'headline'] = null;
    }
    if (this.photoUrl != null) {
      json[r'photoUrl'] = this.photoUrl;
    } else {
      json[r'photoUrl'] = null;
    }
    json[r'tags'] = this.tags;
    return json;
  }

  /// Returns a new [PreviewCardModel] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static PreviewCardModel? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'creatorId'),
            'Required key "PreviewCardModel[creatorId]" is missing from JSON.');
        assert(json[r'creatorId'] != null,
            'Required key "PreviewCardModel[creatorId]" has a null value in JSON.');
        assert(json.containsKey(r'displayName'),
            'Required key "PreviewCardModel[displayName]" is missing from JSON.');
        assert(json[r'displayName'] != null,
            'Required key "PreviewCardModel[displayName]" has a null value in JSON.');
        assert(json.containsKey(r'feeBand'),
            'Required key "PreviewCardModel[feeBand]" is missing from JSON.');
        assert(json[r'feeBand'] != null,
            'Required key "PreviewCardModel[feeBand]" has a null value in JSON.');
        assert(json.containsKey(r'headline'),
            'Required key "PreviewCardModel[headline]" is missing from JSON.');
        assert(json.containsKey(r'photoUrl'),
            'Required key "PreviewCardModel[photoUrl]" is missing from JSON.');
        assert(json.containsKey(r'tags'),
            'Required key "PreviewCardModel[tags]" is missing from JSON.');
        assert(json[r'tags'] != null,
            'Required key "PreviewCardModel[tags]" has a null value in JSON.');
        return true;
      }());

      return PreviewCardModel(
        creatorId: mapValueOfType<String>(json, r'creatorId')!,
        displayName: mapValueOfType<String>(json, r'displayName')!,
        feeBand: FeeBand.fromJson(json[r'feeBand'])!,
        headline: mapValueOfType<String>(json, r'headline'),
        photoUrl: mapValueOfType<String>(json, r'photoUrl'),
        tags: json[r'tags'] is Iterable
            ? (json[r'tags'] as Iterable).cast<String>().toList(growable: false)
            : const [],
      );
    }
    return null;
  }

  static List<PreviewCardModel> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <PreviewCardModel>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PreviewCardModel.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, PreviewCardModel> mapFromJson(dynamic json) {
    final map = <String, PreviewCardModel>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = PreviewCardModel.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of PreviewCardModel-objects as value to a dart map
  static Map<String, List<PreviewCardModel>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<PreviewCardModel>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = PreviewCardModel.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'creatorId',
    'displayName',
    'feeBand',
    'headline',
    'photoUrl',
    'tags',
  };
}
