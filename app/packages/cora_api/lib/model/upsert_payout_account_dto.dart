//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class UpsertPayoutAccountDto {
  /// Returns a new [UpsertPayoutAccountDto] instance.
  UpsertPayoutAccountDto({
    required this.accountNumber,
    required this.bankCode,
    required this.holderName,
  });

  /// 계좌번호. 하이픈은 떼고 저장한다. 숫자 10~14자리.
  String accountNumber;

  /// 은행 코드. GET /payout-account/banks의 code 중 하나.
  UpsertPayoutAccountDtoBankCodeEnum bankCode;

  /// 예금주 이름.
  String holderName;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UpsertPayoutAccountDto &&
          other.accountNumber == accountNumber &&
          other.bankCode == bankCode &&
          other.holderName == holderName;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (accountNumber.hashCode) + (bankCode.hashCode) + (holderName.hashCode);

  @override
  String toString() =>
      'UpsertPayoutAccountDto[accountNumber=$accountNumber, bankCode=$bankCode, holderName=$holderName]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'accountNumber'] = this.accountNumber;
    json[r'bankCode'] = this.bankCode;
    json[r'holderName'] = this.holderName;
    return json;
  }

  /// Returns a new [UpsertPayoutAccountDto] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static UpsertPayoutAccountDto? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'accountNumber'),
            'Required key "UpsertPayoutAccountDto[accountNumber]" is missing from JSON.');
        assert(json[r'accountNumber'] != null,
            'Required key "UpsertPayoutAccountDto[accountNumber]" has a null value in JSON.');
        assert(json.containsKey(r'bankCode'),
            'Required key "UpsertPayoutAccountDto[bankCode]" is missing from JSON.');
        assert(json[r'bankCode'] != null,
            'Required key "UpsertPayoutAccountDto[bankCode]" has a null value in JSON.');
        assert(json.containsKey(r'holderName'),
            'Required key "UpsertPayoutAccountDto[holderName]" is missing from JSON.');
        assert(json[r'holderName'] != null,
            'Required key "UpsertPayoutAccountDto[holderName]" has a null value in JSON.');
        return true;
      }());

      return UpsertPayoutAccountDto(
        accountNumber: mapValueOfType<String>(json, r'accountNumber')!,
        bankCode:
            UpsertPayoutAccountDtoBankCodeEnum.fromJson(json[r'bankCode'])!,
        holderName: mapValueOfType<String>(json, r'holderName')!,
      );
    }
    return null;
  }

  static List<UpsertPayoutAccountDto> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <UpsertPayoutAccountDto>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = UpsertPayoutAccountDto.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, UpsertPayoutAccountDto> mapFromJson(dynamic json) {
    final map = <String, UpsertPayoutAccountDto>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = UpsertPayoutAccountDto.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of UpsertPayoutAccountDto-objects as value to a dart map
  static Map<String, List<UpsertPayoutAccountDto>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<UpsertPayoutAccountDto>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = UpsertPayoutAccountDto.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'accountNumber',
    'bankCode',
    'holderName',
  };
}

/// 은행 코드. GET /payout-account/banks의 code 중 하나.
enum UpsertPayoutAccountDtoBankCodeEnum {
  n004._(r'004'),
  n088._(r'088'),
  n020._(r'020'),
  n081._(r'081'),
  n011._(r'011'),
  n003._(r'003'),
  n090._(r'090'),
  n092._(r'092'),
  n089._(r'089'),
  n045._(r'045'),
  n071._(r'071'),
  n023._(r'023'),
  n032._(r'032'),
  n031._(r'031'),
  n034._(r'034'),
  n037._(r'037'),
  n039._(r'039'),
  n035._(r'035'),
  n007._(r'007'),
  n048._(r'048'),
  ;

  /// Instantiate a new enum with the provided value.
  const UpsertPayoutAccountDtoBankCodeEnum._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [UpsertPayoutAccountDtoBankCodeEnum] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static UpsertPayoutAccountDtoBankCodeEnum? fromJson(dynamic value) =>
      UpsertPayoutAccountDtoBankCodeEnumTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [UpsertPayoutAccountDtoBankCodeEnum]
  /// that were successfully decoded from the passed [JSON][json].
  static List<UpsertPayoutAccountDtoBankCodeEnum> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <UpsertPayoutAccountDtoBankCodeEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = UpsertPayoutAccountDtoBankCodeEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [UpsertPayoutAccountDtoBankCodeEnum] to String,
/// and [decode] dynamic data back to [UpsertPayoutAccountDtoBankCodeEnum].
class UpsertPayoutAccountDtoBankCodeEnumTypeTransformer {
  factory UpsertPayoutAccountDtoBankCodeEnumTypeTransformer() =>
      _instance ??= const UpsertPayoutAccountDtoBankCodeEnumTypeTransformer._();

  const UpsertPayoutAccountDtoBankCodeEnumTypeTransformer._();

  String encode(UpsertPayoutAccountDtoBankCodeEnum data) => data._value;

  /// Returns the instance of [UpsertPayoutAccountDtoBankCodeEnum] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  UpsertPayoutAccountDtoBankCodeEnum? decode(dynamic data,
      {bool allowNull = true}) {
    if (data is UpsertPayoutAccountDtoBankCodeEnum) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'004':
          return UpsertPayoutAccountDtoBankCodeEnum.n004;
        case r'088':
          return UpsertPayoutAccountDtoBankCodeEnum.n088;
        case r'020':
          return UpsertPayoutAccountDtoBankCodeEnum.n020;
        case r'081':
          return UpsertPayoutAccountDtoBankCodeEnum.n081;
        case r'011':
          return UpsertPayoutAccountDtoBankCodeEnum.n011;
        case r'003':
          return UpsertPayoutAccountDtoBankCodeEnum.n003;
        case r'090':
          return UpsertPayoutAccountDtoBankCodeEnum.n090;
        case r'092':
          return UpsertPayoutAccountDtoBankCodeEnum.n092;
        case r'089':
          return UpsertPayoutAccountDtoBankCodeEnum.n089;
        case r'045':
          return UpsertPayoutAccountDtoBankCodeEnum.n045;
        case r'071':
          return UpsertPayoutAccountDtoBankCodeEnum.n071;
        case r'023':
          return UpsertPayoutAccountDtoBankCodeEnum.n023;
        case r'032':
          return UpsertPayoutAccountDtoBankCodeEnum.n032;
        case r'031':
          return UpsertPayoutAccountDtoBankCodeEnum.n031;
        case r'034':
          return UpsertPayoutAccountDtoBankCodeEnum.n034;
        case r'037':
          return UpsertPayoutAccountDtoBankCodeEnum.n037;
        case r'039':
          return UpsertPayoutAccountDtoBankCodeEnum.n039;
        case r'035':
          return UpsertPayoutAccountDtoBankCodeEnum.n035;
        case r'007':
          return UpsertPayoutAccountDtoBankCodeEnum.n007;
        case r'048':
          return UpsertPayoutAccountDtoBankCodeEnum.n048;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static UpsertPayoutAccountDtoBankCodeEnumTypeTransformer? _instance;
}
