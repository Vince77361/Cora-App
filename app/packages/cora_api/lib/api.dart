//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

library cora_api;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:meta/meta.dart';

part 'api_client.dart';
part 'api_helper.dart';
part 'api_exception.dart';
part 'auth/authentication.dart';
part 'auth/api_key_auth.dart';
part 'auth/oauth.dart';
part 'auth/http_basic_auth.dart';
part 'auth/http_bearer_auth.dart';

part 'api/content_drafts_api.dart';
part 'api/creators_api.dart';
part 'api/health_api.dart';
part 'api/stores_api.dart';
part 'api/uploads_api.dart';
part 'api/users_api.dart';

part 'model/advance_onboarding_dto.dart';
part 'model/advance_onboarding_step.dart';
part 'model/analyze_links_dto.dart';
part 'model/analyze_store_links_result_model.dart';
part 'model/content_draft_kind.dart';
part 'model/content_draft_model.dart';
part 'model/content_format.dart';
part 'model/create_photo_upload_dto.dart';
part 'model/creator_profile_model.dart';
part 'model/draft_scene_model.dart';
part 'model/health_model.dart';
part 'model/industry_category.dart';
part 'model/me_model.dart';
part 'model/my_application_status.dart';
part 'model/my_store_model.dart';
part 'model/offer_terms_model.dart';
part 'model/photo_upload_model.dart';
part 'model/reward_type.dart';
part 'model/set_default_terms_dto.dart';
part 'model/source_link_input_dto.dart';
part 'model/source_link_kind.dart';
part 'model/store_detail_model.dart';
part 'model/store_onboarding_step.dart';
part 'model/store_source_link_model.dart';
part 'model/store_status.dart';
part 'model/store_summary_model.dart';
part 'model/update_role_dto.dart';
part 'model/update_store_dto.dart';
part 'model/upsert_creator_profile_dto.dart';
part 'model/user_role.dart';

/// An [ApiClient] instance that uses the default values obtained from
/// the OpenAPI specification file.
var defaultApiClient = ApiClient();

const _delimiters = {'csv': ',', 'ssv': ' ', 'tsv': '\t', 'pipes': '|'};
const _dateEpochMarker = 'epoch';
const _deepEquality = DeepCollectionEquality();
final _dateFormatter = DateFormat('yyyy-MM-dd');
final _regList = RegExp(r'^List<(.*)>$');
final _regSet = RegExp(r'^Set<(.*)>$');
final _regMap = RegExp(r'^Map<String,(.*)>$');

bool _isEpochMarker(String? pattern) =>
    pattern == _dateEpochMarker || pattern == '/$_dateEpochMarker/';
