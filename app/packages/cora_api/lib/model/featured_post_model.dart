//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class FeaturedPostModel {
  /// Returns a new [FeaturedPostModel] instance.
  FeaturedPostModel({
    required this.caption,
    required this.id,
    required this.instagramMediaId,
    required this.kind,
    required this.mediaUrl,
    required this.photoUrl,
    required this.position,
    required this.source_,
  });

  String? caption;

  String id;

  /// 인스타그램에서 가져왔으면 원본 게시물 ID.
  String? instagramMediaId;

  FeaturedPostKind kind;

  /// 사진이나 영상 파일의 주소.
  String mediaUrl;

  /// 카드에 보이는 그림. 썸네일이 있으면 썸네일, 없으면 사진.
  String photoUrl;

  /// Minimum value: 1
  /// Maximum value: 4
  int position;

  FeaturedPostSource source_;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FeaturedPostModel &&
          other.caption == caption &&
          other.id == id &&
          other.instagramMediaId == instagramMediaId &&
          other.kind == kind &&
          other.mediaUrl == mediaUrl &&
          other.photoUrl == photoUrl &&
          other.position == position &&
          other.source_ == source_;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (caption == null ? 0 : caption!.hashCode) +
      (id.hashCode) +
      (instagramMediaId == null ? 0 : instagramMediaId!.hashCode) +
      (kind.hashCode) +
      (mediaUrl.hashCode) +
      (photoUrl.hashCode) +
      (position.hashCode) +
      (source_.hashCode);

  @override
  String toString() =>
      'FeaturedPostModel[caption=$caption, id=$id, instagramMediaId=$instagramMediaId, kind=$kind, mediaUrl=$mediaUrl, photoUrl=$photoUrl, position=$position, source_=$source_]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.caption != null) {
      json[r'caption'] = this.caption;
    } else {
      json[r'caption'] = null;
    }
    json[r'id'] = this.id;
    if (this.instagramMediaId != null) {
      json[r'instagramMediaId'] = this.instagramMediaId;
    } else {
      json[r'instagramMediaId'] = null;
    }
    json[r'kind'] = this.kind;
    json[r'mediaUrl'] = this.mediaUrl;
    json[r'photoUrl'] = this.photoUrl;
    json[r'position'] = this.position;
    json[r'source'] = this.source_;
    return json;
  }

  /// Returns a new [FeaturedPostModel] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static FeaturedPostModel? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'caption'),
            'Required key "FeaturedPostModel[caption]" is missing from JSON.');
        assert(json.containsKey(r'id'),
            'Required key "FeaturedPostModel[id]" is missing from JSON.');
        assert(json[r'id'] != null,
            'Required key "FeaturedPostModel[id]" has a null value in JSON.');
        assert(json.containsKey(r'instagramMediaId'),
            'Required key "FeaturedPostModel[instagramMediaId]" is missing from JSON.');
        assert(json.containsKey(r'kind'),
            'Required key "FeaturedPostModel[kind]" is missing from JSON.');
        assert(json[r'kind'] != null,
            'Required key "FeaturedPostModel[kind]" has a null value in JSON.');
        assert(json.containsKey(r'mediaUrl'),
            'Required key "FeaturedPostModel[mediaUrl]" is missing from JSON.');
        assert(json[r'mediaUrl'] != null,
            'Required key "FeaturedPostModel[mediaUrl]" has a null value in JSON.');
        assert(json.containsKey(r'photoUrl'),
            'Required key "FeaturedPostModel[photoUrl]" is missing from JSON.');
        assert(json[r'photoUrl'] != null,
            'Required key "FeaturedPostModel[photoUrl]" has a null value in JSON.');
        assert(json.containsKey(r'position'),
            'Required key "FeaturedPostModel[position]" is missing from JSON.');
        assert(json[r'position'] != null,
            'Required key "FeaturedPostModel[position]" has a null value in JSON.');
        assert(json.containsKey(r'source'),
            'Required key "FeaturedPostModel[source]" is missing from JSON.');
        assert(json[r'source'] != null,
            'Required key "FeaturedPostModel[source]" has a null value in JSON.');
        return true;
      }());

      return FeaturedPostModel(
        caption: mapValueOfType<String>(json, r'caption'),
        id: mapValueOfType<String>(json, r'id')!,
        instagramMediaId: mapValueOfType<String>(json, r'instagramMediaId'),
        kind: FeaturedPostKind.fromJson(json[r'kind'])!,
        mediaUrl: mapValueOfType<String>(json, r'mediaUrl')!,
        photoUrl: mapValueOfType<String>(json, r'photoUrl')!,
        position: mapValueOfType<int>(json, r'position')!,
        source_: FeaturedPostSource.fromJson(json[r'source'])!,
      );
    }
    return null;
  }

  static List<FeaturedPostModel> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <FeaturedPostModel>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = FeaturedPostModel.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, FeaturedPostModel> mapFromJson(dynamic json) {
    final map = <String, FeaturedPostModel>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = FeaturedPostModel.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of FeaturedPostModel-objects as value to a dart map
  static Map<String, List<FeaturedPostModel>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<FeaturedPostModel>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = FeaturedPostModel.listFromJson(
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
    'id',
    'instagramMediaId',
    'kind',
    'mediaUrl',
    'photoUrl',
    'position',
    'source',
  };
}
