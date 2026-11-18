//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class FeaturedPostDraftModel {
  /// Returns a new [FeaturedPostDraftModel] instance.
  FeaturedPostDraftModel({
    required this.caption,
    required this.instagramMediaId,
    required this.kind,
    required this.mediaPath,
    required this.photoUrl,
    required this.source_,
    required this.thumbnailPath,
  });

  /// 인스타그램 글의 첫 줄(40자까지).
  String? caption;

  /// 원본 인스타그램 게시물 ID.
  String instagramMediaId;

  FeaturedPostKind kind;

  /// 서버에 복사한 사진이나 영상 파일의 경로.
  String mediaPath;

  /// 카드에 보이는 그림의 주소(미리보기).
  String photoUrl;

  FeaturedPostSource source_;

  /// 영상의 첫 화면 그림 경로. 사진은 null.
  String? thumbnailPath;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FeaturedPostDraftModel &&
          other.caption == caption &&
          other.instagramMediaId == instagramMediaId &&
          other.kind == kind &&
          other.mediaPath == mediaPath &&
          other.photoUrl == photoUrl &&
          other.source_ == source_ &&
          other.thumbnailPath == thumbnailPath;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (caption == null ? 0 : caption!.hashCode) +
      (instagramMediaId.hashCode) +
      (kind.hashCode) +
      (mediaPath.hashCode) +
      (photoUrl.hashCode) +
      (source_.hashCode) +
      (thumbnailPath == null ? 0 : thumbnailPath!.hashCode);

  @override
  String toString() =>
      'FeaturedPostDraftModel[caption=$caption, instagramMediaId=$instagramMediaId, kind=$kind, mediaPath=$mediaPath, photoUrl=$photoUrl, source_=$source_, thumbnailPath=$thumbnailPath]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.caption != null) {
      json[r'caption'] = this.caption;
    } else {
      json[r'caption'] = null;
    }
    json[r'instagramMediaId'] = this.instagramMediaId;
    json[r'kind'] = this.kind;
    json[r'mediaPath'] = this.mediaPath;
    json[r'photoUrl'] = this.photoUrl;
    json[r'source'] = this.source_;
    if (this.thumbnailPath != null) {
      json[r'thumbnailPath'] = this.thumbnailPath;
    } else {
      json[r'thumbnailPath'] = null;
    }
    return json;
  }

  /// Returns a new [FeaturedPostDraftModel] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static FeaturedPostDraftModel? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'caption'),
            'Required key "FeaturedPostDraftModel[caption]" is missing from JSON.');
        assert(json.containsKey(r'instagramMediaId'),
            'Required key "FeaturedPostDraftModel[instagramMediaId]" is missing from JSON.');
        assert(json[r'instagramMediaId'] != null,
            'Required key "FeaturedPostDraftModel[instagramMediaId]" has a null value in JSON.');
        assert(json.containsKey(r'kind'),
            'Required key "FeaturedPostDraftModel[kind]" is missing from JSON.');
        assert(json[r'kind'] != null,
            'Required key "FeaturedPostDraftModel[kind]" has a null value in JSON.');
        assert(json.containsKey(r'mediaPath'),
            'Required key "FeaturedPostDraftModel[mediaPath]" is missing from JSON.');
        assert(json[r'mediaPath'] != null,
            'Required key "FeaturedPostDraftModel[mediaPath]" has a null value in JSON.');
        assert(json.containsKey(r'photoUrl'),
            'Required key "FeaturedPostDraftModel[photoUrl]" is missing from JSON.');
        assert(json[r'photoUrl'] != null,
            'Required key "FeaturedPostDraftModel[photoUrl]" has a null value in JSON.');
        assert(json.containsKey(r'source'),
            'Required key "FeaturedPostDraftModel[source]" is missing from JSON.');
        assert(json[r'source'] != null,
            'Required key "FeaturedPostDraftModel[source]" has a null value in JSON.');
        assert(json.containsKey(r'thumbnailPath'),
            'Required key "FeaturedPostDraftModel[thumbnailPath]" is missing from JSON.');
        return true;
      }());

      return FeaturedPostDraftModel(
        caption: mapValueOfType<String>(json, r'caption'),
        instagramMediaId: mapValueOfType<String>(json, r'instagramMediaId')!,
        kind: FeaturedPostKind.fromJson(json[r'kind'])!,
        mediaPath: mapValueOfType<String>(json, r'mediaPath')!,
        photoUrl: mapValueOfType<String>(json, r'photoUrl')!,
        source_: FeaturedPostSource.fromJson(json[r'source'])!,
        thumbnailPath: mapValueOfType<String>(json, r'thumbnailPath'),
      );
    }
    return null;
  }

  static List<FeaturedPostDraftModel> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <FeaturedPostDraftModel>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = FeaturedPostDraftModel.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, FeaturedPostDraftModel> mapFromJson(dynamic json) {
    final map = <String, FeaturedPostDraftModel>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = FeaturedPostDraftModel.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of FeaturedPostDraftModel-objects as value to a dart map
  static Map<String, List<FeaturedPostDraftModel>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<FeaturedPostDraftModel>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = FeaturedPostDraftModel.listFromJson(
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
    'instagramMediaId',
    'kind',
    'mediaPath',
    'photoUrl',
    'source',
    'thumbnailPath',
  };
}
