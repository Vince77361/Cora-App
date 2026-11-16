//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class BrandProgressModel {
  /// Returns a new [BrandProgressModel] instance.
  BrandProgressModel({
    required this.current,
    required this.currentNote,
    required this.doneCount,
  });

  /// 지금 하는 단계(1~6). 모두 끝났으면 null.
  ///
  /// Minimum value: 1
  /// Maximum value: 6
  int? current;

  /// 현재 단계 줄의 보조 글. WAITING_OTHER_CONFIRM: 상대의 동의를 기다림, WAITING_CONTRACT: 계약을 진행해야 함.
  BrandProgressNote? currentNote;

  /// 끝난 단계의 수(0~6).
  ///
  /// Minimum value: 0
  /// Maximum value: 6
  int doneCount;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BrandProgressModel &&
          other.current == current &&
          other.currentNote == currentNote &&
          other.doneCount == doneCount;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (current == null ? 0 : current!.hashCode) +
      (currentNote == null ? 0 : currentNote!.hashCode) +
      (doneCount.hashCode);

  @override
  String toString() =>
      'BrandProgressModel[current=$current, currentNote=$currentNote, doneCount=$doneCount]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.current != null) {
      json[r'current'] = this.current;
    } else {
      json[r'current'] = null;
    }
    if (this.currentNote != null) {
      json[r'currentNote'] = this.currentNote;
    } else {
      json[r'currentNote'] = null;
    }
    json[r'doneCount'] = this.doneCount;
    return json;
  }

  /// Returns a new [BrandProgressModel] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static BrandProgressModel? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'current'),
            'Required key "BrandProgressModel[current]" is missing from JSON.');
        assert(json.containsKey(r'currentNote'),
            'Required key "BrandProgressModel[currentNote]" is missing from JSON.');
        assert(json.containsKey(r'doneCount'),
            'Required key "BrandProgressModel[doneCount]" is missing from JSON.');
        assert(json[r'doneCount'] != null,
            'Required key "BrandProgressModel[doneCount]" has a null value in JSON.');
        return true;
      }());

      return BrandProgressModel(
        current: mapValueOfType<int>(json, r'current'),
        currentNote: BrandProgressNote.fromJson(json[r'currentNote']),
        doneCount: mapValueOfType<int>(json, r'doneCount')!,
      );
    }
    return null;
  }

  static List<BrandProgressModel> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <BrandProgressModel>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = BrandProgressModel.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, BrandProgressModel> mapFromJson(dynamic json) {
    final map = <String, BrandProgressModel>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = BrandProgressModel.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of BrandProgressModel-objects as value to a dart map
  static Map<String, List<BrandProgressModel>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<BrandProgressModel>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = BrandProgressModel.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'current',
    'currentNote',
    'doneCount',
  };
}
