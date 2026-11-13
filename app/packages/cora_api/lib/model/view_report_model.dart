//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class ViewReportModel {
  /// Returns a new [ViewReportModel] instance.
  ViewReportModel({
    required this.calc,
    required this.canConfirm,
    required this.canDispute,
    required this.canUploadEvidence,
    required this.confirmDueAt,
    required this.evidence,
    required this.periodEnd,
    required this.periodStart,
    required this.postUrl,
    required this.source_,
    required this.status,
    required this.views,
  });

  /// 계산. 집계 중에는 null이다.
  ViewReportCalcModel? calc;

  /// 내가 지금 \"자료 확인했어요\"를 누를 수 있으면 true(맡긴 쪽, 확인 전, 연결 계정 자료일 때만).
  bool canConfirm;

  /// 내가 지금 이의를 제기할 수 있으면 true.
  bool canDispute;

  /// 내가 지금 캡처 자료를 올릴 수 있으면 true.
  bool canUploadEvidence;

  /// 확인 전일 때 자동으로 확인되는 시각.
  DateTime? confirmDueAt;

  /// 올라온 캡처 자료. 없으면 null.
  ViewReportEvidenceModel? evidence;

  /// 집계가 끝나는 시각.
  DateTime periodEnd;

  /// 집계 시작(링크 제출 시각).
  DateTime periodStart;

  /// 크리에이터가 낸 게시 링크.
  String postUrl;

  /// CONNECTED_ACCOUNT: 연결한 인스타그램 계정에서 읽음, CAPTURE_PENDING: 캡처 자료(확인 전), CAPTURE_CONFIRMED: 캡처 자료(확정됨).
  ViewReportSource source_;

  /// COUNTING: 집계 중(계산 없음), UNCONFIRMED: 계산이 나왔고 확인을 기다림, CONFIRMED: 확인되어 정산됨, DISPUTED: 이의가 걸려 돈이 그대로 보관됨.
  ViewReportStatus status;

  /// 조회수. 집계 중에는 그날까지 읽은 값(없으면 null), 계산이 나온 뒤에는 정산에 쓰는 값.
  int? views;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ViewReportModel &&
          other.calc == calc &&
          other.canConfirm == canConfirm &&
          other.canDispute == canDispute &&
          other.canUploadEvidence == canUploadEvidence &&
          other.confirmDueAt == confirmDueAt &&
          other.evidence == evidence &&
          other.periodEnd == periodEnd &&
          other.periodStart == periodStart &&
          other.postUrl == postUrl &&
          other.source_ == source_ &&
          other.status == status &&
          other.views == views;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (calc == null ? 0 : calc!.hashCode) +
      (canConfirm.hashCode) +
      (canDispute.hashCode) +
      (canUploadEvidence.hashCode) +
      (confirmDueAt == null ? 0 : confirmDueAt!.hashCode) +
      (evidence == null ? 0 : evidence!.hashCode) +
      (periodEnd.hashCode) +
      (periodStart.hashCode) +
      (postUrl.hashCode) +
      (source_.hashCode) +
      (status.hashCode) +
      (views == null ? 0 : views!.hashCode);

  @override
  String toString() =>
      'ViewReportModel[calc=$calc, canConfirm=$canConfirm, canDispute=$canDispute, canUploadEvidence=$canUploadEvidence, confirmDueAt=$confirmDueAt, evidence=$evidence, periodEnd=$periodEnd, periodStart=$periodStart, postUrl=$postUrl, source_=$source_, status=$status, views=$views]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.calc != null) {
      json[r'calc'] = this.calc;
    } else {
      json[r'calc'] = null;
    }
    json[r'canConfirm'] = this.canConfirm;
    json[r'canDispute'] = this.canDispute;
    json[r'canUploadEvidence'] = this.canUploadEvidence;
    if (this.confirmDueAt != null) {
      json[r'confirmDueAt'] = this.confirmDueAt!.toUtc().toIso8601String();
    } else {
      json[r'confirmDueAt'] = null;
    }
    if (this.evidence != null) {
      json[r'evidence'] = this.evidence;
    } else {
      json[r'evidence'] = null;
    }
    json[r'periodEnd'] = this.periodEnd.toUtc().toIso8601String();
    json[r'periodStart'] = this.periodStart.toUtc().toIso8601String();
    json[r'postUrl'] = this.postUrl;
    json[r'source'] = this.source_;
    json[r'status'] = this.status;
    if (this.views != null) {
      json[r'views'] = this.views;
    } else {
      json[r'views'] = null;
    }
    return json;
  }

  /// Returns a new [ViewReportModel] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ViewReportModel? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'calc'),
            'Required key "ViewReportModel[calc]" is missing from JSON.');
        assert(json.containsKey(r'canConfirm'),
            'Required key "ViewReportModel[canConfirm]" is missing from JSON.');
        assert(json[r'canConfirm'] != null,
            'Required key "ViewReportModel[canConfirm]" has a null value in JSON.');
        assert(json.containsKey(r'canDispute'),
            'Required key "ViewReportModel[canDispute]" is missing from JSON.');
        assert(json[r'canDispute'] != null,
            'Required key "ViewReportModel[canDispute]" has a null value in JSON.');
        assert(json.containsKey(r'canUploadEvidence'),
            'Required key "ViewReportModel[canUploadEvidence]" is missing from JSON.');
        assert(json[r'canUploadEvidence'] != null,
            'Required key "ViewReportModel[canUploadEvidence]" has a null value in JSON.');
        assert(json.containsKey(r'confirmDueAt'),
            'Required key "ViewReportModel[confirmDueAt]" is missing from JSON.');
        assert(json.containsKey(r'evidence'),
            'Required key "ViewReportModel[evidence]" is missing from JSON.');
        assert(json.containsKey(r'periodEnd'),
            'Required key "ViewReportModel[periodEnd]" is missing from JSON.');
        assert(json[r'periodEnd'] != null,
            'Required key "ViewReportModel[periodEnd]" has a null value in JSON.');
        assert(json.containsKey(r'periodStart'),
            'Required key "ViewReportModel[periodStart]" is missing from JSON.');
        assert(json[r'periodStart'] != null,
            'Required key "ViewReportModel[periodStart]" has a null value in JSON.');
        assert(json.containsKey(r'postUrl'),
            'Required key "ViewReportModel[postUrl]" is missing from JSON.');
        assert(json[r'postUrl'] != null,
            'Required key "ViewReportModel[postUrl]" has a null value in JSON.');
        assert(json.containsKey(r'source'),
            'Required key "ViewReportModel[source]" is missing from JSON.');
        assert(json[r'source'] != null,
            'Required key "ViewReportModel[source]" has a null value in JSON.');
        assert(json.containsKey(r'status'),
            'Required key "ViewReportModel[status]" is missing from JSON.');
        assert(json[r'status'] != null,
            'Required key "ViewReportModel[status]" has a null value in JSON.');
        assert(json.containsKey(r'views'),
            'Required key "ViewReportModel[views]" is missing from JSON.');
        return true;
      }());

      return ViewReportModel(
        calc: ViewReportCalcModel.fromJson(json[r'calc']),
        canConfirm: mapValueOfType<bool>(json, r'canConfirm')!,
        canDispute: mapValueOfType<bool>(json, r'canDispute')!,
        canUploadEvidence: mapValueOfType<bool>(json, r'canUploadEvidence')!,
        confirmDueAt: mapDateTime(json, r'confirmDueAt', r''),
        evidence: ViewReportEvidenceModel.fromJson(json[r'evidence']),
        periodEnd: mapDateTime(json, r'periodEnd', r'')!,
        periodStart: mapDateTime(json, r'periodStart', r'')!,
        postUrl: mapValueOfType<String>(json, r'postUrl')!,
        source_: ViewReportSource.fromJson(json[r'source'])!,
        status: ViewReportStatus.fromJson(json[r'status'])!,
        views: mapValueOfType<int>(json, r'views'),
      );
    }
    return null;
  }

  static List<ViewReportModel> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <ViewReportModel>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ViewReportModel.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ViewReportModel> mapFromJson(dynamic json) {
    final map = <String, ViewReportModel>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ViewReportModel.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ViewReportModel-objects as value to a dart map
  static Map<String, List<ViewReportModel>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<ViewReportModel>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ViewReportModel.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'calc',
    'canConfirm',
    'canDispute',
    'canUploadEvidence',
    'confirmDueAt',
    'evidence',
    'periodEnd',
    'periodStart',
    'postUrl',
    'source',
    'status',
    'views',
  };
}
