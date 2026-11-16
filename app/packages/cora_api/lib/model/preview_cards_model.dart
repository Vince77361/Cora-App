//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class PreviewCardsModel {
  /// Returns a new [PreviewCardsModel] instance.
  PreviewCardsModel({
    this.cards = const [],
    required this.total,
  });

  List<PreviewCardModel> cards;

  int total;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PreviewCardsModel &&
          _deepEquality.equals(other.cards, cards) &&
          other.total == total;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (cards.hashCode) + (total.hashCode);

  @override
  String toString() => 'PreviewCardsModel[cards=$cards, total=$total]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'cards'] = this.cards;
    json[r'total'] = this.total;
    return json;
  }

  /// Returns a new [PreviewCardsModel] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static PreviewCardsModel? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'cards'),
            'Required key "PreviewCardsModel[cards]" is missing from JSON.');
        assert(json[r'cards'] != null,
            'Required key "PreviewCardsModel[cards]" has a null value in JSON.');
        assert(json.containsKey(r'total'),
            'Required key "PreviewCardsModel[total]" is missing from JSON.');
        assert(json[r'total'] != null,
            'Required key "PreviewCardsModel[total]" has a null value in JSON.');
        return true;
      }());

      return PreviewCardsModel(
        cards: PreviewCardModel.listFromJson(json[r'cards']),
        total: mapValueOfType<int>(json, r'total')!,
      );
    }
    return null;
  }

  static List<PreviewCardsModel> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <PreviewCardsModel>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PreviewCardsModel.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, PreviewCardsModel> mapFromJson(dynamic json) {
    final map = <String, PreviewCardsModel>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = PreviewCardsModel.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of PreviewCardsModel-objects as value to a dart map
  static Map<String, List<PreviewCardsModel>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<PreviewCardsModel>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = PreviewCardsModel.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'cards',
    'total',
  };
}
