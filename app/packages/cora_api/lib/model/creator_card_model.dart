//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class CreatorCardModel {
  /// Returns a new [CreatorCardModel] instance.
  CreatorCardModel({
    required this.creatorId,
    required this.displayName,
    required this.feeBand,
    required this.headline,
    required this.instagramHandle,
    required this.photoUrl,
    this.posts = const [],
    this.reasons = const [],
    this.tags = const [],
    required this.theyLikedMe,
  });

  String creatorId;

  String displayName;

  FeeBand feeBand;

  String? headline;

  String? instagramHandle;

  String? photoUrl;

  /// 대표 게시물(최대 4개, 차례대로). 없으면 빈 목록이고 이때 photoUrl이 프로필 사진이다.
  List<FeaturedPostModel> posts;

  /// 크리에이터의 협업 원칙과 겹치는 규칙. 많을수록 잘 맞는다.
  List<MatchReason> reasons;

  List<String> tags;

  /// 항상 false. 상대가 먼저 하트를 보냈는지는 미리 알려 주지 않고, 순서에만 쓴다.
  bool theyLikedMe;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CreatorCardModel &&
          other.creatorId == creatorId &&
          other.displayName == displayName &&
          other.feeBand == feeBand &&
          other.headline == headline &&
          other.instagramHandle == instagramHandle &&
          other.photoUrl == photoUrl &&
          _deepEquality.equals(other.posts, posts) &&
          _deepEquality.equals(other.reasons, reasons) &&
          _deepEquality.equals(other.tags, tags) &&
          other.theyLikedMe == theyLikedMe;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (creatorId.hashCode) +
      (displayName.hashCode) +
      (feeBand.hashCode) +
      (headline == null ? 0 : headline!.hashCode) +
      (instagramHandle == null ? 0 : instagramHandle!.hashCode) +
      (photoUrl == null ? 0 : photoUrl!.hashCode) +
      (posts.hashCode) +
      (reasons.hashCode) +
      (tags.hashCode) +
      (theyLikedMe.hashCode);

  @override
  String toString() =>
      'CreatorCardModel[creatorId=$creatorId, displayName=$displayName, feeBand=$feeBand, headline=$headline, instagramHandle=$instagramHandle, photoUrl=$photoUrl, posts=$posts, reasons=$reasons, tags=$tags, theyLikedMe=$theyLikedMe]';

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
    if (this.instagramHandle != null) {
      json[r'instagramHandle'] = this.instagramHandle;
    } else {
      json[r'instagramHandle'] = null;
    }
    if (this.photoUrl != null) {
      json[r'photoUrl'] = this.photoUrl;
    } else {
      json[r'photoUrl'] = null;
    }
    json[r'posts'] = this.posts;
    json[r'reasons'] = this.reasons;
    json[r'tags'] = this.tags;
    json[r'theyLikedMe'] = this.theyLikedMe;
    return json;
  }

  /// Returns a new [CreatorCardModel] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static CreatorCardModel? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'creatorId'),
            'Required key "CreatorCardModel[creatorId]" is missing from JSON.');
        assert(json[r'creatorId'] != null,
            'Required key "CreatorCardModel[creatorId]" has a null value in JSON.');
        assert(json.containsKey(r'displayName'),
            'Required key "CreatorCardModel[displayName]" is missing from JSON.');
        assert(json[r'displayName'] != null,
            'Required key "CreatorCardModel[displayName]" has a null value in JSON.');
        assert(json.containsKey(r'feeBand'),
            'Required key "CreatorCardModel[feeBand]" is missing from JSON.');
        assert(json[r'feeBand'] != null,
            'Required key "CreatorCardModel[feeBand]" has a null value in JSON.');
        assert(json.containsKey(r'headline'),
            'Required key "CreatorCardModel[headline]" is missing from JSON.');
        assert(json.containsKey(r'instagramHandle'),
            'Required key "CreatorCardModel[instagramHandle]" is missing from JSON.');
        assert(json.containsKey(r'photoUrl'),
            'Required key "CreatorCardModel[photoUrl]" is missing from JSON.');
        assert(json.containsKey(r'posts'),
            'Required key "CreatorCardModel[posts]" is missing from JSON.');
        assert(json[r'posts'] != null,
            'Required key "CreatorCardModel[posts]" has a null value in JSON.');
        assert(json.containsKey(r'reasons'),
            'Required key "CreatorCardModel[reasons]" is missing from JSON.');
        assert(json[r'reasons'] != null,
            'Required key "CreatorCardModel[reasons]" has a null value in JSON.');
        assert(json.containsKey(r'tags'),
            'Required key "CreatorCardModel[tags]" is missing from JSON.');
        assert(json[r'tags'] != null,
            'Required key "CreatorCardModel[tags]" has a null value in JSON.');
        assert(json.containsKey(r'theyLikedMe'),
            'Required key "CreatorCardModel[theyLikedMe]" is missing from JSON.');
        assert(json[r'theyLikedMe'] != null,
            'Required key "CreatorCardModel[theyLikedMe]" has a null value in JSON.');
        return true;
      }());

      return CreatorCardModel(
        creatorId: mapValueOfType<String>(json, r'creatorId')!,
        displayName: mapValueOfType<String>(json, r'displayName')!,
        feeBand: FeeBand.fromJson(json[r'feeBand'])!,
        headline: mapValueOfType<String>(json, r'headline'),
        instagramHandle: mapValueOfType<String>(json, r'instagramHandle'),
        photoUrl: mapValueOfType<String>(json, r'photoUrl'),
        posts: FeaturedPostModel.listFromJson(json[r'posts']),
        reasons: MatchReason.listFromJson(json[r'reasons']),
        tags: json[r'tags'] is Iterable
            ? (json[r'tags'] as Iterable).cast<String>().toList(growable: false)
            : const [],
        theyLikedMe: mapValueOfType<bool>(json, r'theyLikedMe')!,
      );
    }
    return null;
  }

  static List<CreatorCardModel> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <CreatorCardModel>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = CreatorCardModel.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, CreatorCardModel> mapFromJson(dynamic json) {
    final map = <String, CreatorCardModel>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = CreatorCardModel.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of CreatorCardModel-objects as value to a dart map
  static Map<String, List<CreatorCardModel>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<CreatorCardModel>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = CreatorCardModel.listFromJson(
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
    'instagramHandle',
    'photoUrl',
    'posts',
    'reasons',
    'tags',
    'theyLikedMe',
  };
}
