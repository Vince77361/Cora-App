import 'dart:convert';

import 'package:cora/features/negotiation/data/api_negotiation_repository.dart';
import 'package:cora/features/negotiation/domain/negotiation_repository.dart';
import 'package:cora/features/offer_terms/domain/offer_terms.dart'
    show ContentFormat;
import 'package:cora/features/proposals/domain/proposal.dart';
import 'package:cora_api/api.dart' as api;
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_http_client.dart';

ApiNegotiationRepository _repo(FakeHttpClient fake) => ApiNegotiationRepository(
  api.ApiClient(basePath: 'http://127.0.0.1:3000')..client = fake,
);

Map<String, Object?> _row({
  String collaborationId = 'col-1',
  String group = 'MY_TURN',
  String? endKind,
  String? myDropReason,
  bool counter = false,
  String? photoUrl,
}) => {
  'kind': 'BRAND_CONTRACT',
  'collaborationId': collaborationId,
  'counterpart': {'name': '모아 스튜디오', 'photoUrl': photoUrl},
  'group': group,
  'version': 2,
  'counter': counter,
  'format': 'REELS',
  'pieces': 1,
  'endKind': endKind,
  'myDropReason': myDropReason,
  'updatedAt': '2026-11-17T03:00:00.000Z',
};

void main() {
  test(
    'fetchProposalInbox maps each group, end kind and drop reason',
    () async {
      final fake = FakeHttpClient()
        ..body = jsonEncode([
          _row(counter: true, photoUrl: 'http://x/y.jpg'),
          _row(collaborationId: 'col-2', group: 'WAITING'),
          _row(collaborationId: 'col-3', group: 'ENDED', endKind: 'AGREED'),
          _row(
            collaborationId: 'col-4',
            group: 'ENDED',
            endKind: 'ENDED',
            myDropReason: 'DIRECTION',
          ),
          _row(collaborationId: 'col-5', group: 'ENDED', endKind: 'ENDED'),
        ]);

      final rows = await _repo(fake).fetchProposalInbox();

      expect(fake.requests.single.url.path, '/terms/proposal-inbox');
      expect(rows.map((r) => r.collaborationId), [
        'col-1',
        'col-2',
        'col-3',
        'col-4',
        'col-5',
      ]);
      expect(rows[0].group, ProposalGroup.myTurn);
      expect(rows[0].name, '모아 스튜디오');
      expect(rows[0].photoUrl, 'http://x/y.jpg');
      expect(rows[0].counter, isTrue);
      expect(rows[0].version, 2);
      expect(rows[0].format, ContentFormat.reels);
      expect(rows[0].pieces, 1);
      expect(rows[1].group, ProposalGroup.waiting);
      expect(rows[2].group, ProposalGroup.ended);
      expect(rows[2].endKind, ProposalEndKind.agreed);
      expect(rows[3].endKind, ProposalEndKind.ended);
      expect(rows[3].myDropReason, DropReason.direction);
      expect(rows[4].myDropReason, isNull);
    },
  );

  test(
    'a failed call is a NegotiationFailure without the server text',
    () async {
      final fake = FakeHttpClient()
        ..statusCode = 500
        ..body =
            '{"error":{"code":"INTERNAL","message":"db down","details":null}}';

      await expectLater(
        _repo(fake).fetchProposalInbox(),
        throwsA(isA<NegotiationFailure>()),
      );
    },
  );
}
