//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class CreatorCardDetailModel {
  /// Returns a new [CreatorCardDetailModel] instance.
  CreatorCardDetailModel({
    required this.creatorId,
    required this.displayName,
    required this.feeBand,
    required this.headline,
    required this.instagramHandle,
    required this.myDecision,
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

  /// 내가 저장한 결정(하트 또는 저장). 결정하지 않았으면 null. 넘긴 카드는 상세가 404라서 PASS는 나오지 않는다.
  SavedDecision? myDecision;

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
      other is CreatorCardDetailModel &&
          other.creatorId == creatorId &&
          other.displayName == displayName &&
          other.feeBand == feeBand &&
          other.headline == headline &&
          other.instagramHandle == instagramHandle &&
          other.myDecision == myDecision &&
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
      (myDecision == null ? 0 : myDecision!.hashCode) +
      (photoUrl == null ? 0 : photoUrl!.hashCode) +
      (posts.hashCode) +
      (reasons.hashCode) +
      (tags.hashCode) +
      (theyLikedMe.hashCode);

  @override
  String toString() =>
      'CreatorCardDetailModel[creatorId=$creatorId, displayName=$displayName, feeBand=$feeBand, headline=$headline, instagramHandle=$instagramHandle, myDecision=$myDecision, photoUrl=$photoUrl, posts=$posts, reasons=$reasons, tags=$tags, theyLikedMe=$theyLikedMe]';

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
    if (this.myDecision != null) {
      json[r'myDecision'] = this.myDecision;
    } else {
      json[r'myDecision'] = null;
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

  /// Returns a new [CreatorCardDetailModel] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static CreatorCardDetailModel? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'creatorId'),
            'Required key "CreatorCardDetailModel[creatorId]" is missing from JSON.');
        assert(json[r'creatorId'] != null,
            'Required key "CreatorCardDetailModel[creatorId]" has a null value in JSON.');
        assert(json.containsKey(r'displayName'),
            'Required key "CreatorCardDetailModel[displayName]" is missing from JSON.');
        assert(json[r'displayName'] != null,
            'Required key "CreatorCardDetailModel[displayName]" has a null value in JSON.');
        assert(json.containsKey(r'feeBand'),
            'Required key "CreatorCardDetailModel[feeBand]" is missing from JSON.');
        assert(json[r'feeBand'] != null,
            'Required key "CreatorCardDetailModel[feeBand]" has a null value in JSON.');
        assert(json.containsKey(r'headline'),
            'Required key "CreatorCardDetailModel[headline]" is missing from JSON.');
        assert(json.containsKey(r'instagramHandle'),
            'Required key "CreatorCardDetailModel[instagramHandle]" is missing from JSON.');
        assert(json.containsKey(r'myDecision'),
            'Required key "CreatorCardDetailModel[myDecision]" is missing from JSON.');
        assert(json.containsKey(r'photoUrl'),
            'Required key "CreatorCardDetailModel[photoUrl]" is missing from JSON.');
        assert(json.containsKey(r'posts'),
            'Required key "CreatorCardDetailModel[posts]" is missing from JSON.');
        assert(json[r'posts'] != null,
            'Required key "CreatorCardDetailModel[posts]" has a null value in JSON.');
        assert(json.containsKey(r'reasons'),
            'Required key "CreatorCardDetailModel[reasons]" is missing from JSON.');
        assert(json[r'reasons'] != null,
            'Required key "CreatorCardDetailModel[reasons]" has a null value in JSON.');
        assert(json.containsKey(r'tags'),
            'Required key "CreatorCardDetailModel[tags]" is missing from JSON.');
        assert(json[r'tags'] != null,
            'Required key "CreatorCardDetailModel[tags]" has a null value in JSON.');
        assert(json.containsKey(r'theyLikedMe'),
            'Required key "CreatorCardDetailModel[theyLikedMe]" is missing from JSON.');
        assert(json[r'theyLikedMe'] != null,
            'Required key "CreatorCardDetailModel[theyLikedMe]" has a null value in JSON.');
        return true;
      }());

      return CreatorCardDetailModel(
        creatorId: mapValueOfType<String>(json, r'creatorId')!,
        displayName: mapValueOfType<String>(json, r'displayName')!,
        feeBand: FeeBand.fromJson(json[r'feeBand'])!,
        headline: mapValueOfType<String>(json, r'headline'),
        instagramHandle: mapValueOfType<String>(json, r'instagramHandle'),
        myDecision: SavedDecision.fromJson(json[r'myDecision']),
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

  static List<CreatorCardDetailModel> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <CreatorCardDetailModel>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = CreatorCardDetailModel.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, CreatorCardDetailModel> mapFromJson(dynamic json) {
    final map = <String, CreatorCardDetailModel>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = CreatorCardDetailModel.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of CreatorCardDetailModel-objects as value to a dart map
  static Map<String, List<CreatorCardDetailModel>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<CreatorCardDetailModel>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = CreatorCardDetailModel.listFromJson(
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
    'myDecision',
    'photoUrl',
    'posts',
    'reasons',
    'tags',
    'theyLikedMe',
  };
}
