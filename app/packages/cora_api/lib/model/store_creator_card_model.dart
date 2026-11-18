//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class StoreCreatorCardModel {
  /// Returns a new [StoreCreatorCardModel] instance.
  StoreCreatorCardModel({
    required this.contentFocus,
    required this.creatorId,
    required this.displayName,
    required this.followers,
    required this.headline,
    required this.photoUrl,
    this.posts = const [],
    this.tags = const [],
  });

  /// 콘텐츠 분야(크리에이터가 쓴 글). 없으면 null.
  String? contentFocus;

  String creatorId;

  String displayName;

  /// 연결한 인스타그램 계정의 팔로워 수. 연결이 없으면 null.
  int? followers;

  /// 1번 대표 게시물의 한 줄.
  String? headline;

  /// 1번 대표 게시물의 그림.
  String? photoUrl;

  /// 대표 게시물(1~4개, 차례대로).
  List<FeaturedPostModel> posts;

  /// 협업 원칙의 꼬리표. 협업 원칙이 없으면 빈 목록.
  List<String> tags;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StoreCreatorCardModel &&
          other.contentFocus == contentFocus &&
          other.creatorId == creatorId &&
          other.displayName == displayName &&
          other.followers == followers &&
          other.headline == headline &&
          other.photoUrl == photoUrl &&
          _deepEquality.equals(other.posts, posts) &&
          _deepEquality.equals(other.tags, tags);

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (contentFocus == null ? 0 : contentFocus!.hashCode) +
      (creatorId.hashCode) +
      (displayName.hashCode) +
      (followers == null ? 0 : followers!.hashCode) +
      (headline == null ? 0 : headline!.hashCode) +
      (photoUrl == null ? 0 : photoUrl!.hashCode) +
      (posts.hashCode) +
      (tags.hashCode);

  @override
  String toString() =>
      'StoreCreatorCardModel[contentFocus=$contentFocus, creatorId=$creatorId, displayName=$displayName, followers=$followers, headline=$headline, photoUrl=$photoUrl, posts=$posts, tags=$tags]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.contentFocus != null) {
      json[r'contentFocus'] = this.contentFocus;
    } else {
      json[r'contentFocus'] = null;
    }
    json[r'creatorId'] = this.creatorId;
    json[r'displayName'] = this.displayName;
    if (this.followers != null) {
      json[r'followers'] = this.followers;
    } else {
      json[r'followers'] = null;
    }
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
    json[r'posts'] = this.posts;
    json[r'tags'] = this.tags;
    return json;
  }

  /// Returns a new [StoreCreatorCardModel] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static StoreCreatorCardModel? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'contentFocus'),
            'Required key "StoreCreatorCardModel[contentFocus]" is missing from JSON.');
        assert(json.containsKey(r'creatorId'),
            'Required key "StoreCreatorCardModel[creatorId]" is missing from JSON.');
        assert(json[r'creatorId'] != null,
            'Required key "StoreCreatorCardModel[creatorId]" has a null value in JSON.');
        assert(json.containsKey(r'displayName'),
            'Required key "StoreCreatorCardModel[displayName]" is missing from JSON.');
        assert(json[r'displayName'] != null,
            'Required key "StoreCreatorCardModel[displayName]" has a null value in JSON.');
        assert(json.containsKey(r'followers'),
            'Required key "StoreCreatorCardModel[followers]" is missing from JSON.');
        assert(json.containsKey(r'headline'),
            'Required key "StoreCreatorCardModel[headline]" is missing from JSON.');
        assert(json.containsKey(r'photoUrl'),
            'Required key "StoreCreatorCardModel[photoUrl]" is missing from JSON.');
        assert(json.containsKey(r'posts'),
            'Required key "StoreCreatorCardModel[posts]" is missing from JSON.');
        assert(json[r'posts'] != null,
            'Required key "StoreCreatorCardModel[posts]" has a null value in JSON.');
        assert(json.containsKey(r'tags'),
            'Required key "StoreCreatorCardModel[tags]" is missing from JSON.');
        assert(json[r'tags'] != null,
            'Required key "StoreCreatorCardModel[tags]" has a null value in JSON.');
        return true;
      }());

      return StoreCreatorCardModel(
        contentFocus: mapValueOfType<String>(json, r'contentFocus'),
        creatorId: mapValueOfType<String>(json, r'creatorId')!,
        displayName: mapValueOfType<String>(json, r'displayName')!,
        followers: mapValueOfType<int>(json, r'followers'),
        headline: mapValueOfType<String>(json, r'headline'),
        photoUrl: mapValueOfType<String>(json, r'photoUrl'),
        posts: FeaturedPostModel.listFromJson(json[r'posts']),
        tags: json[r'tags'] is Iterable
            ? (json[r'tags'] as Iterable).cast<String>().toList(growable: false)
            : const [],
      );
    }
    return null;
  }

  static List<StoreCreatorCardModel> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <StoreCreatorCardModel>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = StoreCreatorCardModel.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, StoreCreatorCardModel> mapFromJson(dynamic json) {
    final map = <String, StoreCreatorCardModel>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = StoreCreatorCardModel.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of StoreCreatorCardModel-objects as value to a dart map
  static Map<String, List<StoreCreatorCardModel>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<StoreCreatorCardModel>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = StoreCreatorCardModel.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'contentFocus',
    'creatorId',
    'displayName',
    'followers',
    'headline',
    'photoUrl',
    'posts',
    'tags',
  };
}
