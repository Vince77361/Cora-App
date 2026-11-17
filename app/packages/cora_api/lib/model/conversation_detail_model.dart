//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class ConversationDetailModel {
  /// Returns a new [ConversationDetailModel] instance.
  ConversationDetailModel({
    required this.blockedByMe,
    required this.campaignTerms,
    required this.canDrop,
    required this.canLikeCampaign,
    required this.canProposeTerms,
    required this.canSend,
    required this.canSendContentCard,
    required this.collaborationId,
    required this.contextLabel,
    required this.contractStatus,
    required this.counterpart,
    required this.id,
    required this.kind,
    required this.lastMessage,
    required this.lastReadSeq,
    required this.lastSeq,
    required this.muted,
    required this.myRole,
    required this.requestedByMe,
    required this.section,
    required this.stage,
    required this.status,
    required this.storeTerms,
    required this.terms,
    required this.unreadCount,
  });

  /// 내가 이 상대를 차단했으면 true.
  bool blockedByMe;

  /// 서로 관심 전(INQUIRY)의 캠페인 조건. 그 밖은 null.
  CampaignTermsModel? campaignTerms;

  /// 협의를 그만둘 수 있는 단계이면 true.
  bool canDrop;

  /// 서로 관심 전, 크리에이터가 캠페인에 관심을 보낼 수 있으면 true.
  bool canLikeCampaign;

  /// 조건 수정 제안을 보낼 수 있는 단계이면 true.
  bool canProposeTerms;

  /// 지금 글을 보낼 수 있으면 true(방이 열려 있다).
  bool canSend;

  /// 크리에이터가 콘텐츠 카드를 보낼 수 있으면 true(카드가 있다).
  bool canSendContentCard;

  String collaborationId;

  /// 캠페인 한 줄 또는 가게 이름.
  String contextLabel;

  /// NONE: 계약 동의 전, AWAITING_BRAND: 크리에이터가 동의해 브랜드 결제 대기, CONCLUDED: 체결.
  ContractProgress contractStatus;

  ConversationCounterpartModel counterpart;

  String id;

  CollaborationKind kind;

  ConversationLastMessageModel? lastMessage;

  int lastReadSeq;

  int lastSeq;

  /// 이 방의 알림을 꺼 두었으면 true.
  bool muted;

  /// 내 쪽. COMMISSIONER는 맡긴 쪽(사장님·브랜드), CREATOR는 크리에이터.
  CollaborationRole myRole;

  /// 내가 먼저 보낸 메시지 요청이면 true.
  bool requestedByMe;

  /// REQUEST: 내가 답해야 하는 메시지 요청(목록 맨 위에 모인다). 그 밖은 NORMAL.
  ConversationSection section;

  CollaborationStage stage;

  ConversationStatus status;

  /// 가게 오퍼의 수락된 판본의 조건(사본). 브랜드 계약은 null.
  OfferTermsModel? storeTerms;

  /// 브랜드 계약의 최신 조건 버전. 아직 없으면 null.
  TermsVersionModel? terms;

  /// 내 읽은 번호 뒤에 상대나 안내로 온 메시지의 수.
  int unreadCount;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConversationDetailModel &&
          other.blockedByMe == blockedByMe &&
          other.campaignTerms == campaignTerms &&
          other.canDrop == canDrop &&
          other.canLikeCampaign == canLikeCampaign &&
          other.canProposeTerms == canProposeTerms &&
          other.canSend == canSend &&
          other.canSendContentCard == canSendContentCard &&
          other.collaborationId == collaborationId &&
          other.contextLabel == contextLabel &&
          other.contractStatus == contractStatus &&
          other.counterpart == counterpart &&
          other.id == id &&
          other.kind == kind &&
          other.lastMessage == lastMessage &&
          other.lastReadSeq == lastReadSeq &&
          other.lastSeq == lastSeq &&
          other.muted == muted &&
          other.myRole == myRole &&
          other.requestedByMe == requestedByMe &&
          other.section == section &&
          other.stage == stage &&
          other.status == status &&
          other.storeTerms == storeTerms &&
          other.terms == terms &&
          other.unreadCount == unreadCount;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (blockedByMe.hashCode) +
      (campaignTerms == null ? 0 : campaignTerms!.hashCode) +
      (canDrop.hashCode) +
      (canLikeCampaign.hashCode) +
      (canProposeTerms.hashCode) +
      (canSend.hashCode) +
      (canSendContentCard.hashCode) +
      (collaborationId.hashCode) +
      (contextLabel.hashCode) +
      (contractStatus.hashCode) +
      (counterpart.hashCode) +
      (id.hashCode) +
      (kind.hashCode) +
      (lastMessage == null ? 0 : lastMessage!.hashCode) +
      (lastReadSeq.hashCode) +
      (lastSeq.hashCode) +
      (muted.hashCode) +
      (myRole.hashCode) +
      (requestedByMe.hashCode) +
      (section.hashCode) +
      (stage.hashCode) +
      (status.hashCode) +
      (storeTerms == null ? 0 : storeTerms!.hashCode) +
      (terms == null ? 0 : terms!.hashCode) +
      (unreadCount.hashCode);

  @override
  String toString() =>
      'ConversationDetailModel[blockedByMe=$blockedByMe, campaignTerms=$campaignTerms, canDrop=$canDrop, canLikeCampaign=$canLikeCampaign, canProposeTerms=$canProposeTerms, canSend=$canSend, canSendContentCard=$canSendContentCard, collaborationId=$collaborationId, contextLabel=$contextLabel, contractStatus=$contractStatus, counterpart=$counterpart, id=$id, kind=$kind, lastMessage=$lastMessage, lastReadSeq=$lastReadSeq, lastSeq=$lastSeq, muted=$muted, myRole=$myRole, requestedByMe=$requestedByMe, section=$section, stage=$stage, status=$status, storeTerms=$storeTerms, terms=$terms, unreadCount=$unreadCount]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'blockedByMe'] = this.blockedByMe;
    if (this.campaignTerms != null) {
      json[r'campaignTerms'] = this.campaignTerms;
    } else {
      json[r'campaignTerms'] = null;
    }
    json[r'canDrop'] = this.canDrop;
    json[r'canLikeCampaign'] = this.canLikeCampaign;
    json[r'canProposeTerms'] = this.canProposeTerms;
    json[r'canSend'] = this.canSend;
    json[r'canSendContentCard'] = this.canSendContentCard;
    json[r'collaborationId'] = this.collaborationId;
    json[r'contextLabel'] = this.contextLabel;
    json[r'contractStatus'] = this.contractStatus;
    json[r'counterpart'] = this.counterpart;
    json[r'id'] = this.id;
    json[r'kind'] = this.kind;
    if (this.lastMessage != null) {
      json[r'lastMessage'] = this.lastMessage;
    } else {
      json[r'lastMessage'] = null;
    }
    json[r'lastReadSeq'] = this.lastReadSeq;
    json[r'lastSeq'] = this.lastSeq;
    json[r'muted'] = this.muted;
    json[r'myRole'] = this.myRole;
    json[r'requestedByMe'] = this.requestedByMe;
    json[r'section'] = this.section;
    json[r'stage'] = this.stage;
    json[r'status'] = this.status;
    if (this.storeTerms != null) {
      json[r'storeTerms'] = this.storeTerms;
    } else {
      json[r'storeTerms'] = null;
    }
    if (this.terms != null) {
      json[r'terms'] = this.terms;
    } else {
      json[r'terms'] = null;
    }
    json[r'unreadCount'] = this.unreadCount;
    return json;
  }

  /// Returns a new [ConversationDetailModel] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ConversationDetailModel? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'blockedByMe'),
            'Required key "ConversationDetailModel[blockedByMe]" is missing from JSON.');
        assert(json[r'blockedByMe'] != null,
            'Required key "ConversationDetailModel[blockedByMe]" has a null value in JSON.');
        assert(json.containsKey(r'campaignTerms'),
            'Required key "ConversationDetailModel[campaignTerms]" is missing from JSON.');
        assert(json.containsKey(r'canDrop'),
            'Required key "ConversationDetailModel[canDrop]" is missing from JSON.');
        assert(json[r'canDrop'] != null,
            'Required key "ConversationDetailModel[canDrop]" has a null value in JSON.');
        assert(json.containsKey(r'canLikeCampaign'),
            'Required key "ConversationDetailModel[canLikeCampaign]" is missing from JSON.');
        assert(json[r'canLikeCampaign'] != null,
            'Required key "ConversationDetailModel[canLikeCampaign]" has a null value in JSON.');
        assert(json.containsKey(r'canProposeTerms'),
            'Required key "ConversationDetailModel[canProposeTerms]" is missing from JSON.');
        assert(json[r'canProposeTerms'] != null,
            'Required key "ConversationDetailModel[canProposeTerms]" has a null value in JSON.');
        assert(json.containsKey(r'canSend'),
            'Required key "ConversationDetailModel[canSend]" is missing from JSON.');
        assert(json[r'canSend'] != null,
            'Required key "ConversationDetailModel[canSend]" has a null value in JSON.');
        assert(json.containsKey(r'canSendContentCard'),
            'Required key "ConversationDetailModel[canSendContentCard]" is missing from JSON.');
        assert(json[r'canSendContentCard'] != null,
            'Required key "ConversationDetailModel[canSendContentCard]" has a null value in JSON.');
        assert(json.containsKey(r'collaborationId'),
            'Required key "ConversationDetailModel[collaborationId]" is missing from JSON.');
        assert(json[r'collaborationId'] != null,
            'Required key "ConversationDetailModel[collaborationId]" has a null value in JSON.');
        assert(json.containsKey(r'contextLabel'),
            'Required key "ConversationDetailModel[contextLabel]" is missing from JSON.');
        assert(json[r'contextLabel'] != null,
            'Required key "ConversationDetailModel[contextLabel]" has a null value in JSON.');
        assert(json.containsKey(r'contractStatus'),
            'Required key "ConversationDetailModel[contractStatus]" is missing from JSON.');
        assert(json[r'contractStatus'] != null,
            'Required key "ConversationDetailModel[contractStatus]" has a null value in JSON.');
        assert(json.containsKey(r'counterpart'),
            'Required key "ConversationDetailModel[counterpart]" is missing from JSON.');
        assert(json[r'counterpart'] != null,
            'Required key "ConversationDetailModel[counterpart]" has a null value in JSON.');
        assert(json.containsKey(r'id'),
            'Required key "ConversationDetailModel[id]" is missing from JSON.');
        assert(json[r'id'] != null,
            'Required key "ConversationDetailModel[id]" has a null value in JSON.');
        assert(json.containsKey(r'kind'),
            'Required key "ConversationDetailModel[kind]" is missing from JSON.');
        assert(json[r'kind'] != null,
            'Required key "ConversationDetailModel[kind]" has a null value in JSON.');
        assert(json.containsKey(r'lastMessage'),
            'Required key "ConversationDetailModel[lastMessage]" is missing from JSON.');
        assert(json.containsKey(r'lastReadSeq'),
            'Required key "ConversationDetailModel[lastReadSeq]" is missing from JSON.');
        assert(json[r'lastReadSeq'] != null,
            'Required key "ConversationDetailModel[lastReadSeq]" has a null value in JSON.');
        assert(json.containsKey(r'lastSeq'),
            'Required key "ConversationDetailModel[lastSeq]" is missing from JSON.');
        assert(json[r'lastSeq'] != null,
            'Required key "ConversationDetailModel[lastSeq]" has a null value in JSON.');
        assert(json.containsKey(r'muted'),
            'Required key "ConversationDetailModel[muted]" is missing from JSON.');
        assert(json[r'muted'] != null,
            'Required key "ConversationDetailModel[muted]" has a null value in JSON.');
        assert(json.containsKey(r'myRole'),
            'Required key "ConversationDetailModel[myRole]" is missing from JSON.');
        assert(json[r'myRole'] != null,
            'Required key "ConversationDetailModel[myRole]" has a null value in JSON.');
        assert(json.containsKey(r'requestedByMe'),
            'Required key "ConversationDetailModel[requestedByMe]" is missing from JSON.');
        assert(json[r'requestedByMe'] != null,
            'Required key "ConversationDetailModel[requestedByMe]" has a null value in JSON.');
        assert(json.containsKey(r'section'),
            'Required key "ConversationDetailModel[section]" is missing from JSON.');
        assert(json[r'section'] != null,
            'Required key "ConversationDetailModel[section]" has a null value in JSON.');
        assert(json.containsKey(r'stage'),
            'Required key "ConversationDetailModel[stage]" is missing from JSON.');
        assert(json[r'stage'] != null,
            'Required key "ConversationDetailModel[stage]" has a null value in JSON.');
        assert(json.containsKey(r'status'),
            'Required key "ConversationDetailModel[status]" is missing from JSON.');
        assert(json[r'status'] != null,
            'Required key "ConversationDetailModel[status]" has a null value in JSON.');
        assert(json.containsKey(r'storeTerms'),
            'Required key "ConversationDetailModel[storeTerms]" is missing from JSON.');
        assert(json.containsKey(r'terms'),
            'Required key "ConversationDetailModel[terms]" is missing from JSON.');
        assert(json.containsKey(r'unreadCount'),
            'Required key "ConversationDetailModel[unreadCount]" is missing from JSON.');
        assert(json[r'unreadCount'] != null,
            'Required key "ConversationDetailModel[unreadCount]" has a null value in JSON.');
        return true;
      }());

      return ConversationDetailModel(
        blockedByMe: mapValueOfType<bool>(json, r'blockedByMe')!,
        campaignTerms: CampaignTermsModel.fromJson(json[r'campaignTerms']),
        canDrop: mapValueOfType<bool>(json, r'canDrop')!,
        canLikeCampaign: mapValueOfType<bool>(json, r'canLikeCampaign')!,
        canProposeTerms: mapValueOfType<bool>(json, r'canProposeTerms')!,
        canSend: mapValueOfType<bool>(json, r'canSend')!,
        canSendContentCard: mapValueOfType<bool>(json, r'canSendContentCard')!,
        collaborationId: mapValueOfType<String>(json, r'collaborationId')!,
        contextLabel: mapValueOfType<String>(json, r'contextLabel')!,
        contractStatus: ContractProgress.fromJson(json[r'contractStatus'])!,
        counterpart:
            ConversationCounterpartModel.fromJson(json[r'counterpart'])!,
        id: mapValueOfType<String>(json, r'id')!,
        kind: CollaborationKind.fromJson(json[r'kind'])!,
        lastMessage:
            ConversationLastMessageModel.fromJson(json[r'lastMessage']),
        lastReadSeq: mapValueOfType<int>(json, r'lastReadSeq')!,
        lastSeq: mapValueOfType<int>(json, r'lastSeq')!,
        muted: mapValueOfType<bool>(json, r'muted')!,
        myRole: CollaborationRole.fromJson(json[r'myRole'])!,
        requestedByMe: mapValueOfType<bool>(json, r'requestedByMe')!,
        section: ConversationSection.fromJson(json[r'section'])!,
        stage: CollaborationStage.fromJson(json[r'stage'])!,
        status: ConversationStatus.fromJson(json[r'status'])!,
        storeTerms: OfferTermsModel.fromJson(json[r'storeTerms']),
        terms: TermsVersionModel.fromJson(json[r'terms']),
        unreadCount: mapValueOfType<int>(json, r'unreadCount')!,
      );
    }
    return null;
  }

  static List<ConversationDetailModel> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <ConversationDetailModel>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ConversationDetailModel.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ConversationDetailModel> mapFromJson(dynamic json) {
    final map = <String, ConversationDetailModel>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ConversationDetailModel.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ConversationDetailModel-objects as value to a dart map
  static Map<String, List<ConversationDetailModel>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<ConversationDetailModel>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ConversationDetailModel.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'blockedByMe',
    'campaignTerms',
    'canDrop',
    'canLikeCampaign',
    'canProposeTerms',
    'canSend',
    'canSendContentCard',
    'collaborationId',
    'contextLabel',
    'contractStatus',
    'counterpart',
    'id',
    'kind',
    'lastMessage',
    'lastReadSeq',
    'lastSeq',
    'muted',
    'myRole',
    'requestedByMe',
    'section',
    'stage',
    'status',
    'storeTerms',
    'terms',
    'unreadCount',
  };
}
