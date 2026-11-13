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

part 'api/app_config_api.dart';
part 'api/applications_api.dart';
part 'api/collaborations_api.dart';
part 'api/content_drafts_api.dart';
part 'api/creators_api.dart';
part 'api/health_api.dart';
part 'api/instagram_api.dart';
part 'api/notification_settings_api.dart';
part 'api/notifications_api.dart';
part 'api/offers_api.dart';
part 'api/payments_api.dart';
part 'api/payout_accounts_api.dart';
part 'api/proposals_api.dart';
part 'api/stores_api.dart';
part 'api/submissions_api.dart';
part 'api/uploads_api.dart';
part 'api/users_api.dart';
part 'api/wallet_api.dart';

part 'model/accept_offer_dto.dart';
part 'model/advance_onboarding_dto.dart';
part 'model/advance_onboarding_step.dart';
part 'model/analyze_links_dto.dart';
part 'model/analyze_store_links_result_model.dart';
part 'model/app_config_model.dart';
part 'model/applicant_model.dart';
part 'model/application_model.dart';
part 'model/application_status.dart';
part 'model/apply_dto.dart';
part 'model/bank_model.dart';
part 'model/cancel_request_model.dart';
part 'model/collaboration_counterpart_model.dart';
part 'model/collaboration_kind.dart';
part 'model/collaboration_model.dart';
part 'model/collaboration_role.dart';
part 'model/collaboration_scope.dart';
part 'model/collaboration_settlement_model.dart';
part 'model/collaboration_stage.dart';
part 'model/collaboration_step_key.dart';
part 'model/collaboration_step_model.dart';
part 'model/collaboration_step_state.dart';
part 'model/complete_instagram_connect_dto.dart';
part 'model/content_draft_kind.dart';
part 'model/content_draft_model.dart';
part 'model/content_format.dart';
part 'model/create_creator_series_dto.dart';
part 'model/create_payment_dto.dart';
part 'model/create_photo_upload_dto.dart';
part 'model/creator_profile_model.dart';
part 'model/creator_series_model.dart';
part 'model/creator_summary_model.dart';
part 'model/draft_scene_model.dart';
part 'model/end_offer_dto.dart';
part 'model/ended_offer_model.dart';
part 'model/fee_rates_model.dart';
part 'model/fixed_cash_max_model.dart';
part 'model/fixed_cash_range_model.dart';
part 'model/health_model.dart';
part 'model/industry_category.dart';
part 'model/instagram_connect_url_model.dart';
part 'model/instagram_connection_model.dart';
part 'model/me_model.dart';
part 'model/my_application_status.dart';
part 'model/my_open_offer_model.dart';
part 'model/my_store_model.dart';
part 'model/notification_actor_model.dart';
part 'model/notification_glyph.dart';
part 'model/notification_model.dart';
part 'model/notification_page_model.dart';
part 'model/notification_settings_model.dart';
part 'model/notification_tab.dart';
part 'model/notification_tab_filter.dart';
part 'model/notification_target_model.dart';
part 'model/offer_end_reason.dart';
part 'model/offer_end_status.dart';
part 'model/offer_party.dart';
part 'model/offer_terms_model.dart';
part 'model/offer_version_model.dart';
part 'model/offer_version_series_model.dart';
part 'model/offer_view.dart';
part 'model/payment_created_model.dart';
part 'model/payment_method.dart';
part 'model/payment_quote_model.dart';
part 'model/payment_status.dart';
part 'model/payment_status_model.dart';
part 'model/payout_account_model.dart';
part 'model/payout_status.dart';
part 'model/per_view_input_dto.dart';
part 'model/photo_upload_model.dart';
part 'model/proposal_counterpart_model.dart';
part 'model/proposal_detail_model.dart';
part 'model/proposal_end_kind.dart';
part 'model/proposal_group.dart';
part 'model/proposal_person_model.dart';
part 'model/proposal_row_model.dart';
part 'model/proposal_store_model.dart';
part 'model/proposal_tab.dart';
part 'model/propose_version_dto.dart';
part 'model/quiet_hours.dart';
part 'model/received_offer_model.dart';
part 'model/received_offer_tab.dart';
part 'model/reward_config_model.dart';
part 'model/reward_input_dto.dart';
part 'model/reward_range_model.dart';
part 'model/send_offer_dto.dart';
part 'model/sent_offer_model.dart';
part 'model/set_default_terms_dto.dart';
part 'model/settlement_method.dart';
part 'model/source_link_input_dto.dart';
part 'model/source_link_kind.dart';
part 'model/store_detail_model.dart';
part 'model/store_home_summary_model.dart';
part 'model/store_onboarding_step.dart';
part 'model/store_proposal_dto.dart';
part 'model/store_proposal_result_model.dart';
part 'model/store_source_link_model.dart';
part 'model/store_status.dart';
part 'model/store_summary_model.dart';
part 'model/submit_content_dto.dart';
part 'model/unread_count_model.dart';
part 'model/update_notification_settings_dto.dart';
part 'model/update_role_dto.dart';
part 'model/update_store_dto.dart';
part 'model/upsert_creator_profile_dto.dart';
part 'model/upsert_payout_account_dto.dart';
part 'model/usage_rights.dart';
part 'model/user_role.dart';
part 'model/voucher_defaults_model.dart';
part 'model/voucher_input_dto.dart';
part 'model/wallet_account_model.dart';
part 'model/wallet_entry_kind.dart';
part 'model/wallet_entry_model.dart';
part 'model/wallet_model.dart';
part 'model/wallet_next_payout_model.dart';

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
