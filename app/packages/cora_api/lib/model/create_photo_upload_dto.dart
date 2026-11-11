//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class CreatePhotoUploadDto {
  /// Returns a new [CreatePhotoUploadDto] instance.
  CreatePhotoUploadDto({
    required this.contentType,
    required this.purpose,
    required this.sizeBytes,
  });

  CreatePhotoUploadDtoContentTypeEnum contentType;

  CreatePhotoUploadDtoPurposeEnum purpose;

  /// Minimum value: 1
  /// Maximum value: 5242880
  int sizeBytes;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CreatePhotoUploadDto &&
          other.contentType == contentType &&
          other.purpose == purpose &&
          other.sizeBytes == sizeBytes;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (contentType.hashCode) + (purpose.hashCode) + (sizeBytes.hashCode);

  @override
  String toString() =>
      'CreatePhotoUploadDto[contentType=$contentType, purpose=$purpose, sizeBytes=$sizeBytes]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'contentType'] = this.contentType;
    json[r'purpose'] = this.purpose;
    json[r'sizeBytes'] = this.sizeBytes;
    return json;
  }

  /// Returns a new [CreatePhotoUploadDto] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static CreatePhotoUploadDto? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'contentType'),
            'Required key "CreatePhotoUploadDto[contentType]" is missing from JSON.');
        assert(json[r'contentType'] != null,
            'Required key "CreatePhotoUploadDto[contentType]" has a null value in JSON.');
        assert(json.containsKey(r'purpose'),
            'Required key "CreatePhotoUploadDto[purpose]" is missing from JSON.');
        assert(json[r'purpose'] != null,
            'Required key "CreatePhotoUploadDto[purpose]" has a null value in JSON.');
        assert(json.containsKey(r'sizeBytes'),
            'Required key "CreatePhotoUploadDto[sizeBytes]" is missing from JSON.');
        assert(json[r'sizeBytes'] != null,
            'Required key "CreatePhotoUploadDto[sizeBytes]" has a null value in JSON.');
        return true;
      }());

      return CreatePhotoUploadDto(
        contentType:
            CreatePhotoUploadDtoContentTypeEnum.fromJson(json[r'contentType'])!,
        purpose: CreatePhotoUploadDtoPurposeEnum.fromJson(json[r'purpose'])!,
        sizeBytes: mapValueOfType<int>(json, r'sizeBytes')!,
      );
    }
    return null;
  }

  static List<CreatePhotoUploadDto> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <CreatePhotoUploadDto>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = CreatePhotoUploadDto.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, CreatePhotoUploadDto> mapFromJson(dynamic json) {
    final map = <String, CreatePhotoUploadDto>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = CreatePhotoUploadDto.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of CreatePhotoUploadDto-objects as value to a dart map
  static Map<String, List<CreatePhotoUploadDto>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<CreatePhotoUploadDto>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = CreatePhotoUploadDto.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'contentType',
    'purpose',
    'sizeBytes',
  };
}

enum CreatePhotoUploadDtoContentTypeEnum {
  imageSlashJpeg._(r'image/jpeg'),
  imageSlashPng._(r'image/png'),
  imageSlashHeic._(r'image/heic'),
  ;

  /// Instantiate a new enum with the provided value.
  const CreatePhotoUploadDtoContentTypeEnum._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [CreatePhotoUploadDtoContentTypeEnum] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static CreatePhotoUploadDtoContentTypeEnum? fromJson(dynamic value) =>
      CreatePhotoUploadDtoContentTypeEnumTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [CreatePhotoUploadDtoContentTypeEnum]
  /// that were successfully decoded from the passed [JSON][json].
  static List<CreatePhotoUploadDtoContentTypeEnum> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <CreatePhotoUploadDtoContentTypeEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = CreatePhotoUploadDtoContentTypeEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [CreatePhotoUploadDtoContentTypeEnum] to String,
/// and [decode] dynamic data back to [CreatePhotoUploadDtoContentTypeEnum].
class CreatePhotoUploadDtoContentTypeEnumTypeTransformer {
  factory CreatePhotoUploadDtoContentTypeEnumTypeTransformer() => _instance ??=
      const CreatePhotoUploadDtoContentTypeEnumTypeTransformer._();

  const CreatePhotoUploadDtoContentTypeEnumTypeTransformer._();

  String encode(CreatePhotoUploadDtoContentTypeEnum data) => data._value;

  /// Returns the instance of [CreatePhotoUploadDtoContentTypeEnum] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  CreatePhotoUploadDtoContentTypeEnum? decode(dynamic data,
      {bool allowNull = true}) {
    if (data is CreatePhotoUploadDtoContentTypeEnum) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'image/jpeg':
          return CreatePhotoUploadDtoContentTypeEnum.imageSlashJpeg;
        case r'image/png':
          return CreatePhotoUploadDtoContentTypeEnum.imageSlashPng;
        case r'image/heic':
          return CreatePhotoUploadDtoContentTypeEnum.imageSlashHeic;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static CreatePhotoUploadDtoContentTypeEnumTypeTransformer? _instance;
}

enum CreatePhotoUploadDtoPurposeEnum {
  STORE_COVER._(r'STORE_COVER'),
  CREATOR_PHOTO._(r'CREATOR_PHOTO'),
  ;

  /// Instantiate a new enum with the provided value.
  const CreatePhotoUploadDtoPurposeEnum._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [CreatePhotoUploadDtoPurposeEnum] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static CreatePhotoUploadDtoPurposeEnum? fromJson(dynamic value) =>
      CreatePhotoUploadDtoPurposeEnumTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [CreatePhotoUploadDtoPurposeEnum]
  /// that were successfully decoded from the passed [JSON][json].
  static List<CreatePhotoUploadDtoPurposeEnum> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <CreatePhotoUploadDtoPurposeEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = CreatePhotoUploadDtoPurposeEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [CreatePhotoUploadDtoPurposeEnum] to String,
/// and [decode] dynamic data back to [CreatePhotoUploadDtoPurposeEnum].
class CreatePhotoUploadDtoPurposeEnumTypeTransformer {
  factory CreatePhotoUploadDtoPurposeEnumTypeTransformer() =>
      _instance ??= const CreatePhotoUploadDtoPurposeEnumTypeTransformer._();

  const CreatePhotoUploadDtoPurposeEnumTypeTransformer._();

  String encode(CreatePhotoUploadDtoPurposeEnum data) => data._value;

  /// Returns the instance of [CreatePhotoUploadDtoPurposeEnum] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  CreatePhotoUploadDtoPurposeEnum? decode(dynamic data,
      {bool allowNull = true}) {
    if (data is CreatePhotoUploadDtoPurposeEnum) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'STORE_COVER':
          return CreatePhotoUploadDtoPurposeEnum.STORE_COVER;
        case r'CREATOR_PHOTO':
          return CreatePhotoUploadDtoPurposeEnum.CREATOR_PHOTO;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static CreatePhotoUploadDtoPurposeEnumTypeTransformer? _instance;
}
