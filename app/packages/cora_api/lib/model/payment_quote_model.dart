//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class PaymentQuoteModel {
  /// Returns a new [PaymentQuoteModel] instance.
  PaymentQuoteModel({
    required this.creatorName,
    required this.creatorPhotoUrl,
    required this.escrow,
    required this.fee,
    required this.feeRate,
    required this.fixedCash,
    required this.format,
    required this.orderName,
    required this.perViewCap,
    required this.pieces,
    required this.total,
    required this.voucherName,
    required this.voucherPeople,
    required this.voucherValue,
  });

  /// 오퍼를 수락한 크리에이터의 활동 이름.
  String creatorName;

  String? creatorPhotoUrl;

  /// 에스크로에 보관할 금액. 최대 현금 부담(고정 현금 + 조회수 수당 상한)이다.
  int escrow;

  /// 서비스 수수료. 최대 현금 부담 × 수수료율을 내림한 값.
  int fee;

  /// 수수료율(%).
  int feeRate;

  /// 고정 현금(원). 없으면 0.
  int fixedCash;

  ContentFormat format;

  /// PG에 넘기는 주문 이름.
  String orderName;

  /// 조회수 수당 상한(원). 조회수 수당이 없으면 null.
  int? perViewCap;

  /// 콘텐츠 편 수. 오퍼는 지금 한 편이다.
  int pieces;

  /// 지금 결제할 금액(최대 현금 부담 + 수수료).
  int total;

  /// 식사권 이름. 보상에 식사권이 없으면 null.
  String? voucherName;

  /// 식사권 인원. 보상에 식사권이 없거나 모르면 null.
  int? voucherPeople;

  /// 식사권 금액(원). 보상에 식사권이 없으면 null.
  int? voucherValue;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaymentQuoteModel &&
          other.creatorName == creatorName &&
          other.creatorPhotoUrl == creatorPhotoUrl &&
          other.escrow == escrow &&
          other.fee == fee &&
          other.feeRate == feeRate &&
          other.fixedCash == fixedCash &&
          other.format == format &&
          other.orderName == orderName &&
          other.perViewCap == perViewCap &&
          other.pieces == pieces &&
          other.total == total &&
          other.voucherName == voucherName &&
          other.voucherPeople == voucherPeople &&
          other.voucherValue == voucherValue;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (creatorName.hashCode) +
      (creatorPhotoUrl == null ? 0 : creatorPhotoUrl!.hashCode) +
      (escrow.hashCode) +
      (fee.hashCode) +
      (feeRate.hashCode) +
      (fixedCash.hashCode) +
      (format.hashCode) +
      (orderName.hashCode) +
      (perViewCap == null ? 0 : perViewCap!.hashCode) +
      (pieces.hashCode) +
      (total.hashCode) +
      (voucherName == null ? 0 : voucherName!.hashCode) +
      (voucherPeople == null ? 0 : voucherPeople!.hashCode) +
      (voucherValue == null ? 0 : voucherValue!.hashCode);

  @override
  String toString() =>
      'PaymentQuoteModel[creatorName=$creatorName, creatorPhotoUrl=$creatorPhotoUrl, escrow=$escrow, fee=$fee, feeRate=$feeRate, fixedCash=$fixedCash, format=$format, orderName=$orderName, perViewCap=$perViewCap, pieces=$pieces, total=$total, voucherName=$voucherName, voucherPeople=$voucherPeople, voucherValue=$voucherValue]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'creatorName'] = this.creatorName;
    if (this.creatorPhotoUrl != null) {
      json[r'creatorPhotoUrl'] = this.creatorPhotoUrl;
    } else {
      json[r'creatorPhotoUrl'] = null;
    }
    json[r'escrow'] = this.escrow;
    json[r'fee'] = this.fee;
    json[r'feeRate'] = this.feeRate;
    json[r'fixedCash'] = this.fixedCash;
    json[r'format'] = this.format;
    json[r'orderName'] = this.orderName;
    if (this.perViewCap != null) {
      json[r'perViewCap'] = this.perViewCap;
    } else {
      json[r'perViewCap'] = null;
    }
    json[r'pieces'] = this.pieces;
    json[r'total'] = this.total;
    if (this.voucherName != null) {
      json[r'voucherName'] = this.voucherName;
    } else {
      json[r'voucherName'] = null;
    }
    if (this.voucherPeople != null) {
      json[r'voucherPeople'] = this.voucherPeople;
    } else {
      json[r'voucherPeople'] = null;
    }
    if (this.voucherValue != null) {
      json[r'voucherValue'] = this.voucherValue;
    } else {
      json[r'voucherValue'] = null;
    }
    return json;
  }

  /// Returns a new [PaymentQuoteModel] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static PaymentQuoteModel? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'creatorName'),
            'Required key "PaymentQuoteModel[creatorName]" is missing from JSON.');
        assert(json[r'creatorName'] != null,
            'Required key "PaymentQuoteModel[creatorName]" has a null value in JSON.');
        assert(json.containsKey(r'creatorPhotoUrl'),
            'Required key "PaymentQuoteModel[creatorPhotoUrl]" is missing from JSON.');
        assert(json.containsKey(r'escrow'),
            'Required key "PaymentQuoteModel[escrow]" is missing from JSON.');
        assert(json[r'escrow'] != null,
            'Required key "PaymentQuoteModel[escrow]" has a null value in JSON.');
        assert(json.containsKey(r'fee'),
            'Required key "PaymentQuoteModel[fee]" is missing from JSON.');
        assert(json[r'fee'] != null,
            'Required key "PaymentQuoteModel[fee]" has a null value in JSON.');
        assert(json.containsKey(r'feeRate'),
            'Required key "PaymentQuoteModel[feeRate]" is missing from JSON.');
        assert(json[r'feeRate'] != null,
            'Required key "PaymentQuoteModel[feeRate]" has a null value in JSON.');
        assert(json.containsKey(r'fixedCash'),
            'Required key "PaymentQuoteModel[fixedCash]" is missing from JSON.');
        assert(json[r'fixedCash'] != null,
            'Required key "PaymentQuoteModel[fixedCash]" has a null value in JSON.');
        assert(json.containsKey(r'format'),
            'Required key "PaymentQuoteModel[format]" is missing from JSON.');
        assert(json[r'format'] != null,
            'Required key "PaymentQuoteModel[format]" has a null value in JSON.');
        assert(json.containsKey(r'orderName'),
            'Required key "PaymentQuoteModel[orderName]" is missing from JSON.');
        assert(json[r'orderName'] != null,
            'Required key "PaymentQuoteModel[orderName]" has a null value in JSON.');
        assert(json.containsKey(r'perViewCap'),
            'Required key "PaymentQuoteModel[perViewCap]" is missing from JSON.');
        assert(json.containsKey(r'pieces'),
            'Required key "PaymentQuoteModel[pieces]" is missing from JSON.');
        assert(json[r'pieces'] != null,
            'Required key "PaymentQuoteModel[pieces]" has a null value in JSON.');
        assert(json.containsKey(r'total'),
            'Required key "PaymentQuoteModel[total]" is missing from JSON.');
        assert(json[r'total'] != null,
            'Required key "PaymentQuoteModel[total]" has a null value in JSON.');
        assert(json.containsKey(r'voucherName'),
            'Required key "PaymentQuoteModel[voucherName]" is missing from JSON.');
        assert(json.containsKey(r'voucherPeople'),
            'Required key "PaymentQuoteModel[voucherPeople]" is missing from JSON.');
        assert(json.containsKey(r'voucherValue'),
            'Required key "PaymentQuoteModel[voucherValue]" is missing from JSON.');
        return true;
      }());

      return PaymentQuoteModel(
        creatorName: mapValueOfType<String>(json, r'creatorName')!,
        creatorPhotoUrl: mapValueOfType<String>(json, r'creatorPhotoUrl'),
        escrow: mapValueOfType<int>(json, r'escrow')!,
        fee: mapValueOfType<int>(json, r'fee')!,
        feeRate: mapValueOfType<int>(json, r'feeRate')!,
        fixedCash: mapValueOfType<int>(json, r'fixedCash')!,
        format: ContentFormat.fromJson(json[r'format'])!,
        orderName: mapValueOfType<String>(json, r'orderName')!,
        perViewCap: mapValueOfType<int>(json, r'perViewCap'),
        pieces: mapValueOfType<int>(json, r'pieces')!,
        total: mapValueOfType<int>(json, r'total')!,
        voucherName: mapValueOfType<String>(json, r'voucherName'),
        voucherPeople: mapValueOfType<int>(json, r'voucherPeople'),
        voucherValue: mapValueOfType<int>(json, r'voucherValue'),
      );
    }
    return null;
  }

  static List<PaymentQuoteModel> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <PaymentQuoteModel>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PaymentQuoteModel.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, PaymentQuoteModel> mapFromJson(dynamic json) {
    final map = <String, PaymentQuoteModel>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = PaymentQuoteModel.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of PaymentQuoteModel-objects as value to a dart map
  static Map<String, List<PaymentQuoteModel>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<PaymentQuoteModel>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = PaymentQuoteModel.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'creatorName',
    'creatorPhotoUrl',
    'escrow',
    'fee',
    'feeRate',
    'fixedCash',
    'format',
    'orderName',
    'perViewCap',
    'pieces',
    'total',
    'voucherName',
    'voucherPeople',
    'voucherValue',
  };
}
