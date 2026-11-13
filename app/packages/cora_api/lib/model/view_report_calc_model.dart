//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class ViewReportCalcModel {
  /// Returns a new [ViewReportCalcModel] instance.
  ViewReportCalcModel({
    required this.cap,
    required this.capApplied,
    required this.fixedCash,
    required this.payout,
    required this.ratePerThousand,
    required this.refund,
    required this.viewPay,
  });

  /// 조회수 수당 상한(원).
  int cap;

  /// 수당이 상한에 걸렸으면 true.
  bool capApplied;

  /// 고정 현금(원). 없으면 0.
  int fixedCash;

  /// 크리에이터에게 가는 금액(원).
  int payout;

  /// 1,000회당 단가(원).
  int ratePerThousand;

  /// 맡긴 쪽에게 돌아가는 금액(원).
  int refund;

  /// 조회수 수당(원).
  int viewPay;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ViewReportCalcModel &&
          other.cap == cap &&
          other.capApplied == capApplied &&
          other.fixedCash == fixedCash &&
          other.payout == payout &&
          other.ratePerThousand == ratePerThousand &&
          other.refund == refund &&
          other.viewPay == viewPay;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (cap.hashCode) +
      (capApplied.hashCode) +
      (fixedCash.hashCode) +
      (payout.hashCode) +
      (ratePerThousand.hashCode) +
      (refund.hashCode) +
      (viewPay.hashCode);

  @override
  String toString() =>
      'ViewReportCalcModel[cap=$cap, capApplied=$capApplied, fixedCash=$fixedCash, payout=$payout, ratePerThousand=$ratePerThousand, refund=$refund, viewPay=$viewPay]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'cap'] = this.cap;
    json[r'capApplied'] = this.capApplied;
    json[r'fixedCash'] = this.fixedCash;
    json[r'payout'] = this.payout;
    json[r'ratePerThousand'] = this.ratePerThousand;
    json[r'refund'] = this.refund;
    json[r'viewPay'] = this.viewPay;
    return json;
  }

  /// Returns a new [ViewReportCalcModel] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ViewReportCalcModel? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'cap'),
            'Required key "ViewReportCalcModel[cap]" is missing from JSON.');
        assert(json[r'cap'] != null,
            'Required key "ViewReportCalcModel[cap]" has a null value in JSON.');
        assert(json.containsKey(r'capApplied'),
            'Required key "ViewReportCalcModel[capApplied]" is missing from JSON.');
        assert(json[r'capApplied'] != null,
            'Required key "ViewReportCalcModel[capApplied]" has a null value in JSON.');
        assert(json.containsKey(r'fixedCash'),
            'Required key "ViewReportCalcModel[fixedCash]" is missing from JSON.');
        assert(json[r'fixedCash'] != null,
            'Required key "ViewReportCalcModel[fixedCash]" has a null value in JSON.');
        assert(json.containsKey(r'payout'),
            'Required key "ViewReportCalcModel[payout]" is missing from JSON.');
        assert(json[r'payout'] != null,
            'Required key "ViewReportCalcModel[payout]" has a null value in JSON.');
        assert(json.containsKey(r'ratePerThousand'),
            'Required key "ViewReportCalcModel[ratePerThousand]" is missing from JSON.');
        assert(json[r'ratePerThousand'] != null,
            'Required key "ViewReportCalcModel[ratePerThousand]" has a null value in JSON.');
        assert(json.containsKey(r'refund'),
            'Required key "ViewReportCalcModel[refund]" is missing from JSON.');
        assert(json[r'refund'] != null,
            'Required key "ViewReportCalcModel[refund]" has a null value in JSON.');
        assert(json.containsKey(r'viewPay'),
            'Required key "ViewReportCalcModel[viewPay]" is missing from JSON.');
        assert(json[r'viewPay'] != null,
            'Required key "ViewReportCalcModel[viewPay]" has a null value in JSON.');
        return true;
      }());

      return ViewReportCalcModel(
        cap: mapValueOfType<int>(json, r'cap')!,
        capApplied: mapValueOfType<bool>(json, r'capApplied')!,
        fixedCash: mapValueOfType<int>(json, r'fixedCash')!,
        payout: mapValueOfType<int>(json, r'payout')!,
        ratePerThousand: mapValueOfType<int>(json, r'ratePerThousand')!,
        refund: mapValueOfType<int>(json, r'refund')!,
        viewPay: mapValueOfType<int>(json, r'viewPay')!,
      );
    }
    return null;
  }

  static List<ViewReportCalcModel> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <ViewReportCalcModel>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ViewReportCalcModel.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ViewReportCalcModel> mapFromJson(dynamic json) {
    final map = <String, ViewReportCalcModel>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ViewReportCalcModel.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ViewReportCalcModel-objects as value to a dart map
  static Map<String, List<ViewReportCalcModel>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<ViewReportCalcModel>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ViewReportCalcModel.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'cap',
    'capApplied',
    'fixedCash',
    'payout',
    'ratePerThousand',
    'refund',
    'viewPay',
  };
}
