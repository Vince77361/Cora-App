//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class FeaturedPostInputDto {
  /// Returns a new [FeaturedPostInputDto] instance.
  FeaturedPostInputDto({
    this.caption,
    this.id,
    this.instagramMediaId,
    this.kind,
    this.mediaPath,
    this.source_,
    this.thumbnailPath,
  });

  /// 한 줄 설명. 사진첩 게시물은 필수.
  Object? caption;

  /// 내 대표 게시물의 ID. 이것만 보내면 기존 게시물을 그대로 두고 이 차례에 놓는다.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? id;

  Object? instagramMediaId;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  FeaturedPostKind? kind;

  /// 올린 파일의 경로. 사진첩은 POST /uploads/photos(FEATURED_POST)가 준 경로, 인스타그램은 가져오기가 준 경로.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? mediaPath;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  FeaturedPostSource? source_;

  Object? thumbnailPath;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FeaturedPostInputDto &&
          other.caption == caption &&
          other.id == id &&
          other.instagramMediaId == instagramMediaId &&
          other.kind == kind &&
          other.mediaPath == mediaPath &&
          other.source_ == source_ &&
          other.thumbnailPath == thumbnailPath;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (caption == null ? 0 : caption!.hashCode) +
      (id == null ? 0 : id!.hashCode) +
      (instagramMediaId == null ? 0 : instagramMediaId!.hashCode) +
      (kind == null ? 0 : kind!.hashCode) +
      (mediaPath == null ? 0 : mediaPath!.hashCode) +
      (source_ == null ? 0 : source_!.hashCode) +
      (thumbnailPath == null ? 0 : thumbnailPath!.hashCode);

  @override
  String toString() =>
      'FeaturedPostInputDto[caption=$caption, id=$id, instagramMediaId=$instagramMediaId, kind=$kind, mediaPath=$mediaPath, source_=$source_, thumbnailPath=$thumbnailPath]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.caption != null) {
      json[r'caption'] = this.caption;
    } else {
      json[r'caption'] = null;
    }
    if (this.id != null) {
      json[r'id'] = this.id;
    } else {
      json[r'id'] = null;
    }
    if (this.instagramMediaId != null) {
      json[r'instagramMediaId'] = this.instagramMediaId;
    } else {
      json[r'instagramMediaId'] = null;
    }
    if (this.kind != null) {
      json[r'kind'] = this.kind;
    } else {
      json[r'kind'] = null;
    }
    if (this.mediaPath != null) {
      json[r'mediaPath'] = this.mediaPath;
    } else {
      json[r'mediaPath'] = null;
    }
    if (this.source_ != null) {
      json[r'source'] = this.source_;
    } else {
      json[r'source'] = null;
    }
    if (this.thumbnailPath != null) {
      json[r'thumbnailPath'] = this.thumbnailPath;
    } else {
      json[r'thumbnailPath'] = null;
    }
    return json;
  }

  /// Returns a new [FeaturedPostInputDto] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static FeaturedPostInputDto? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return FeaturedPostInputDto(
        caption: mapValueOfType<Object>(json, r'caption'),
        id: mapValueOfType<String>(json, r'id'),
        instagramMediaId: mapValueOfType<Object>(json, r'instagramMediaId'),
        kind: FeaturedPostKind.fromJson(json[r'kind']),
        mediaPath: mapValueOfType<String>(json, r'mediaPath'),
        source_: FeaturedPostSource.fromJson(json[r'source']),
        thumbnailPath: mapValueOfType<Object>(json, r'thumbnailPath'),
      );
    }
    return null;
  }

  static List<FeaturedPostInputDto> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <FeaturedPostInputDto>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = FeaturedPostInputDto.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, FeaturedPostInputDto> mapFromJson(dynamic json) {
    final map = <String, FeaturedPostInputDto>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = FeaturedPostInputDto.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of FeaturedPostInputDto-objects as value to a dart map
  static Map<String, List<FeaturedPostInputDto>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<FeaturedPostInputDto>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = FeaturedPostInputDto.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{};
}
