//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class OfferVersionModel {
  /// Returns a new [OfferVersionModel] instance.
  OfferVersionModel({
    required this.authorParty,
    required this.createdAt,
    required this.idea,
    required this.number,
    this.principles = const [],
    required this.series,
    required this.terms,
  });

  /// 이 판본을 쓴 쪽.
  OfferParty authorParty;

  DateTime createdAt;

  String? idea;

  /// 판본 번호. 1부터 시작한다.
  int number;

  List<String> principles;

  OfferVersionSeriesModel? series;

  OfferTermsModel terms;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OfferVersionModel &&
          other.authorParty == authorParty &&
          other.createdAt == createdAt &&
          other.idea == idea &&
          other.number == number &&
          _deepEquality.equals(other.principles, principles) &&
          other.series == series &&
          other.terms == terms;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (authorParty.hashCode) +
      (createdAt.hashCode) +
      (idea == null ? 0 : idea!.hashCode) +
      (number.hashCode) +
      (principles.hashCode) +
      (series == null ? 0 : series!.hashCode) +
      (terms.hashCode);

  @override
  String toString() =>
      'OfferVersionModel[authorParty=$authorParty, createdAt=$createdAt, idea=$idea, number=$number, principles=$principles, series=$series, terms=$terms]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'authorParty'] = this.authorParty;
    json[r'createdAt'] = this.createdAt.toUtc().toIso8601String();
    if (this.idea != null) {
      json[r'idea'] = this.idea;
    } else {
      json[r'idea'] = null;
    }
    json[r'number'] = this.number;
    json[r'principles'] = this.principles;
    if (this.series != null) {
      json[r'series'] = this.series;
    } else {
      json[r'series'] = null;
    }
    json[r'terms'] = this.terms;
    return json;
  }

  /// Returns a new [OfferVersionModel] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static OfferVersionModel? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'authorParty'),
            'Required key "OfferVersionModel[authorParty]" is missing from JSON.');
        assert(json[r'authorParty'] != null,
            'Required key "OfferVersionModel[authorParty]" has a null value in JSON.');
        assert(json.containsKey(r'createdAt'),
            'Required key "OfferVersionModel[createdAt]" is missing from JSON.');
        assert(json[r'createdAt'] != null,
            'Required key "OfferVersionModel[createdAt]" has a null value in JSON.');
        assert(json.containsKey(r'idea'),
            'Required key "OfferVersionModel[idea]" is missing from JSON.');
        assert(json.containsKey(r'number'),
            'Required key "OfferVersionModel[number]" is missing from JSON.');
        assert(json[r'number'] != null,
            'Required key "OfferVersionModel[number]" has a null value in JSON.');
        assert(json.containsKey(r'principles'),
            'Required key "OfferVersionModel[principles]" is missing from JSON.');
        assert(json[r'principles'] != null,
            'Required key "OfferVersionModel[principles]" has a null value in JSON.');
        assert(json.containsKey(r'series'),
            'Required key "OfferVersionModel[series]" is missing from JSON.');
        assert(json.containsKey(r'terms'),
            'Required key "OfferVersionModel[terms]" is missing from JSON.');
        assert(json[r'terms'] != null,
            'Required key "OfferVersionModel[terms]" has a null value in JSON.');
        return true;
      }());

      return OfferVersionModel(
        authorParty: OfferParty.fromJson(json[r'authorParty'])!,
        createdAt: mapDateTime(json, r'createdAt', r'')!,
        idea: mapValueOfType<String>(json, r'idea'),
        number: mapValueOfType<int>(json, r'number')!,
        principles: json[r'principles'] is Iterable
            ? (json[r'principles'] as Iterable)
                .cast<String>()
                .toList(growable: false)
            : const [],
        series: OfferVersionSeriesModel.fromJson(json[r'series']),
        terms: OfferTermsModel.fromJson(json[r'terms'])!,
      );
    }
    return null;
  }

  static List<OfferVersionModel> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <OfferVersionModel>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = OfferVersionModel.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, OfferVersionModel> mapFromJson(dynamic json) {
    final map = <String, OfferVersionModel>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = OfferVersionModel.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of OfferVersionModel-objects as value to a dart map
  static Map<String, List<OfferVersionModel>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<OfferVersionModel>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = OfferVersionModel.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'authorParty',
    'createdAt',
    'idea',
    'number',
    'principles',
    'series',
    'terms',
  };
}
