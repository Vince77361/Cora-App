//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class InstagramPostModel {
  /// Returns a new [InstagramPostModel] instance.
  InstagramPostModel({
    required this.caption,
    required this.durationSec,
    required this.id,
    required this.kind,
    required this.sizeBytes,
    required this.thumbnailUrl,
  });

  /// 게시물 글 전체.
  String? caption;

  /// 영상 길이(초). 사진이거나 모르면 null. 60초를 넘으면 가져올 수 없다.
  int? durationSec;

  /// 인스타그램 게시물 ID.
  String id;

  FeaturedPostKind kind;

  /// 영상 파일 크기(바이트). 사진이거나 모르면 null. 100MB를 넘으면 가져올 수 없다.
  int? sizeBytes;

  /// 격자에 보일 그림의 주소.
  String thumbnailUrl;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InstagramPostModel &&
          other.caption == caption &&
          other.durationSec == durationSec &&
          other.id == id &&
          other.kind == kind &&
          other.sizeBytes == sizeBytes &&
          other.thumbnailUrl == thumbnailUrl;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (caption == null ? 0 : caption!.hashCode) +
      (durationSec == null ? 0 : durationSec!.hashCode) +
      (id.hashCode) +
      (kind.hashCode) +
      (sizeBytes == null ? 0 : sizeBytes!.hashCode) +
      (thumbnailUrl.hashCode);

  @override
  String toString() =>
      'InstagramPostModel[caption=$caption, durationSec=$durationSec, id=$id, kind=$kind, sizeBytes=$sizeBytes, thumbnailUrl=$thumbnailUrl]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.caption != null) {
      json[r'caption'] = this.caption;
    } else {
      json[r'caption'] = null;
    }
    if (this.durationSec != null) {
      json[r'durationSec'] = this.durationSec;
    } else {
      json[r'durationSec'] = null;
    }
    json[r'id'] = this.id;
    json[r'kind'] = this.kind;
    if (this.sizeBytes != null) {
      json[r'sizeBytes'] = this.sizeBytes;
    } else {
      json[r'sizeBytes'] = null;
    }
    json[r'thumbnailUrl'] = this.thumbnailUrl;
    return json;
  }

  /// Returns a new [InstagramPostModel] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static InstagramPostModel? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'caption'),
            'Required key "InstagramPostModel[caption]" is missing from JSON.');
        assert(json.containsKey(r'durationSec'),
            'Required key "InstagramPostModel[durationSec]" is missing from JSON.');
        assert(json.containsKey(r'id'),
            'Required key "InstagramPostModel[id]" is missing from JSON.');
        assert(json[r'id'] != null,
            'Required key "InstagramPostModel[id]" has a null value in JSON.');
        assert(json.containsKey(r'kind'),
            'Required key "InstagramPostModel[kind]" is missing from JSON.');
        assert(json[r'kind'] != null,
            'Required key "InstagramPostModel[kind]" has a null value in JSON.');
        assert(json.containsKey(r'sizeBytes'),
            'Required key "InstagramPostModel[sizeBytes]" is missing from JSON.');
        assert(json.containsKey(r'thumbnailUrl'),
            'Required key "InstagramPostModel[thumbnailUrl]" is missing from JSON.');
        assert(json[r'thumbnailUrl'] != null,
            'Required key "InstagramPostModel[thumbnailUrl]" has a null value in JSON.');
        return true;
      }());

      return InstagramPostModel(
        caption: mapValueOfType<String>(json, r'caption'),
        durationSec: mapValueOfType<int>(json, r'durationSec'),
        id: mapValueOfType<String>(json, r'id')!,
        kind: FeaturedPostKind.fromJson(json[r'kind'])!,
        sizeBytes: mapValueOfType<int>(json, r'sizeBytes'),
        thumbnailUrl: mapValueOfType<String>(json, r'thumbnailUrl')!,
      );
    }
    return null;
  }

  static List<InstagramPostModel> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <InstagramPostModel>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = InstagramPostModel.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, InstagramPostModel> mapFromJson(dynamic json) {
    final map = <String, InstagramPostModel>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = InstagramPostModel.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of InstagramPostModel-objects as value to a dart map
  static Map<String, List<InstagramPostModel>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<InstagramPostModel>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = InstagramPostModel.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'caption',
    'durationSec',
    'id',
    'kind',
    'sizeBytes',
    'thumbnailUrl',
  };
}
