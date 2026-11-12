//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class WalletEntryModel {
  /// Returns a new [WalletEntryModel] instance.
  WalletEntryModel({
    required this.amount,
    required this.at,
    required this.collaborationId,
    required this.counterpartName,
    required this.format,
    required this.kind,
    required this.pieces,
    required this.stage,
    required this.views,
    required this.voucherName,
    required this.voucherUsed,
  });

  /// 금액(원). 식사권 줄은 null.
  int? amount;

  /// 줄의 기준 시각. 지급 예정은 정산 시각, 지급 완료는 송금 시각, 보관 중은 보관 시작.
  DateTime at;

  String collaborationId;

  /// 크리에이터에게는 가게 이름. 읽을 수 없으면 \"가게\"(브랜드 계약은 \"브랜드\").
  String counterpartName;

  ContentFormat format;

  /// PAYOUT_SCHEDULED: 정산이 확정되고 송금 전, PAYOUT_DONE: 송금 끝, PAYOUT_FAILED: 송금 실패(운영팀이 확인), HELD: Cora가 보관 중, VOUCHER: 식사권.
  WalletEntryKind kind;

  /// 콘텐츠 편 수. 오퍼는 지금 한 편이다.
  int pieces;

  CollaborationStage stage;

  /// 정산에 쓴 최종 조회수. 지급 줄에서만 값이 있다.
  int? views;

  /// 식사권 이름. 식사권 줄에서만 값이 있다.
  String? voucherName;

  /// 링크를 제출해 식사권을 쓴 것으로 보면 true. 식사권 줄에서만 값이 있다.
  bool? voucherUsed;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WalletEntryModel &&
          other.amount == amount &&
          other.at == at &&
          other.collaborationId == collaborationId &&
          other.counterpartName == counterpartName &&
          other.format == format &&
          other.kind == kind &&
          other.pieces == pieces &&
          other.stage == stage &&
          other.views == views &&
          other.voucherName == voucherName &&
          other.voucherUsed == voucherUsed;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (amount == null ? 0 : amount!.hashCode) +
      (at.hashCode) +
      (collaborationId.hashCode) +
      (counterpartName.hashCode) +
      (format.hashCode) +
      (kind.hashCode) +
      (pieces.hashCode) +
      (stage.hashCode) +
      (views == null ? 0 : views!.hashCode) +
      (voucherName == null ? 0 : voucherName!.hashCode) +
      (voucherUsed == null ? 0 : voucherUsed!.hashCode);

  @override
  String toString() =>
      'WalletEntryModel[amount=$amount, at=$at, collaborationId=$collaborationId, counterpartName=$counterpartName, format=$format, kind=$kind, pieces=$pieces, stage=$stage, views=$views, voucherName=$voucherName, voucherUsed=$voucherUsed]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.amount != null) {
      json[r'amount'] = this.amount;
    } else {
      json[r'amount'] = null;
    }
    json[r'at'] = this.at.toUtc().toIso8601String();
    json[r'collaborationId'] = this.collaborationId;
    json[r'counterpartName'] = this.counterpartName;
    json[r'format'] = this.format;
    json[r'kind'] = this.kind;
    json[r'pieces'] = this.pieces;
    json[r'stage'] = this.stage;
    if (this.views != null) {
      json[r'views'] = this.views;
    } else {
      json[r'views'] = null;
    }
    if (this.voucherName != null) {
      json[r'voucherName'] = this.voucherName;
    } else {
      json[r'voucherName'] = null;
    }
    if (this.voucherUsed != null) {
      json[r'voucherUsed'] = this.voucherUsed;
    } else {
      json[r'voucherUsed'] = null;
    }
    return json;
  }

  /// Returns a new [WalletEntryModel] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static WalletEntryModel? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'amount'),
            'Required key "WalletEntryModel[amount]" is missing from JSON.');
        assert(json.containsKey(r'at'),
            'Required key "WalletEntryModel[at]" is missing from JSON.');
        assert(json[r'at'] != null,
            'Required key "WalletEntryModel[at]" has a null value in JSON.');
        assert(json.containsKey(r'collaborationId'),
            'Required key "WalletEntryModel[collaborationId]" is missing from JSON.');
        assert(json[r'collaborationId'] != null,
            'Required key "WalletEntryModel[collaborationId]" has a null value in JSON.');
        assert(json.containsKey(r'counterpartName'),
            'Required key "WalletEntryModel[counterpartName]" is missing from JSON.');
        assert(json[r'counterpartName'] != null,
            'Required key "WalletEntryModel[counterpartName]" has a null value in JSON.');
        assert(json.containsKey(r'format'),
            'Required key "WalletEntryModel[format]" is missing from JSON.');
        assert(json[r'format'] != null,
            'Required key "WalletEntryModel[format]" has a null value in JSON.');
        assert(json.containsKey(r'kind'),
            'Required key "WalletEntryModel[kind]" is missing from JSON.');
        assert(json[r'kind'] != null,
            'Required key "WalletEntryModel[kind]" has a null value in JSON.');
        assert(json.containsKey(r'pieces'),
            'Required key "WalletEntryModel[pieces]" is missing from JSON.');
        assert(json[r'pieces'] != null,
            'Required key "WalletEntryModel[pieces]" has a null value in JSON.');
        assert(json.containsKey(r'stage'),
            'Required key "WalletEntryModel[stage]" is missing from JSON.');
        assert(json[r'stage'] != null,
            'Required key "WalletEntryModel[stage]" has a null value in JSON.');
        assert(json.containsKey(r'views'),
            'Required key "WalletEntryModel[views]" is missing from JSON.');
        assert(json.containsKey(r'voucherName'),
            'Required key "WalletEntryModel[voucherName]" is missing from JSON.');
        assert(json.containsKey(r'voucherUsed'),
            'Required key "WalletEntryModel[voucherUsed]" is missing from JSON.');
        return true;
      }());

      return WalletEntryModel(
        amount: mapValueOfType<int>(json, r'amount'),
        at: mapDateTime(json, r'at', r'')!,
        collaborationId: mapValueOfType<String>(json, r'collaborationId')!,
        counterpartName: mapValueOfType<String>(json, r'counterpartName')!,
        format: ContentFormat.fromJson(json[r'format'])!,
        kind: WalletEntryKind.fromJson(json[r'kind'])!,
        pieces: mapValueOfType<int>(json, r'pieces')!,
        stage: CollaborationStage.fromJson(json[r'stage'])!,
        views: mapValueOfType<int>(json, r'views'),
        voucherName: mapValueOfType<String>(json, r'voucherName'),
        voucherUsed: mapValueOfType<bool>(json, r'voucherUsed'),
      );
    }
    return null;
  }

  static List<WalletEntryModel> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <WalletEntryModel>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = WalletEntryModel.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, WalletEntryModel> mapFromJson(dynamic json) {
    final map = <String, WalletEntryModel>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = WalletEntryModel.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of WalletEntryModel-objects as value to a dart map
  static Map<String, List<WalletEntryModel>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<WalletEntryModel>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = WalletEntryModel.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'amount',
    'at',
    'collaborationId',
    'counterpartName',
    'format',
    'kind',
    'pieces',
    'stage',
    'views',
    'voucherName',
    'voucherUsed',
  };
}
