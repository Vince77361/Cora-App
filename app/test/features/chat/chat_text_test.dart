import 'package:cora/features/chat/domain/conversation.dart';
import 'package:cora/features/chat/presentation/chat_text.dart';
import 'package:cora/features/offer_terms/domain/offer_terms.dart' show ViewPay;
import 'package:flutter_test/flutter_test.dart';

import 'chat_fixtures.dart';

void main() {
  // 한국 시간 2026-11-11 15:20 = UTC 06:20.
  final now = DateTime.utc(2026, 11, 11, 6, 20);

  group('listTime', () {
    test('formats list times as time, yesterday or date', () {
      expect(listTime(DateTime.utc(2026, 11, 11, 6, 20), now), '오후 3:20');
      expect(listTime(DateTime.utc(2026, 11, 10, 6, 20), now), '어제');
      expect(listTime(DateTime.utc(2026, 11, 8, 6, 20), now), '11월 8일');
    });

    test('counts the day in Korea time, not UTC', () {
      // UTC 11월 10일 16:00은 한국 시간 11월 11일 01:00이라 오늘이다.
      expect(listTime(DateTime.utc(2026, 11, 10, 16), now), '오전 1:00');
      expect(listTime(DateTime.utc(2026, 11, 11, 3), now), '오후 12:00');
      expect(listTime(DateTime.utc(2026, 11, 10, 15), now), '오전 12:00');
    });

    test('pads the minute with a zero', () {
      expect(listTime(DateTime.utc(2026, 11, 11, 0, 5), now), '오전 9:05');
    });
  });

  test('labels the day divider with the Korean month and day', () {
    expect(dayDivider(DateTime.utc(2026, 11, 23, 3)), '11월 23일');
    // 한국 시간으로 넘어간 날은 다음 날이다.
    expect(dayDivider(DateTime.utc(2026, 11, 29, 16)), '11월 30일');
  });

  test('prefixes the request time with today or yesterday', () {
    expect(requestTime(DateTime.utc(2026, 11, 11, 5, 14), now), '오늘 오후 2:14');
    expect(requestTime(DateTime.utc(2026, 11, 10, 5, 14), now), '어제 오후 2:14');
    expect(
      requestTime(DateTime.utc(2026, 11, 3, 5, 14), now),
      '11월 3일 오후 2:14',
    );
  });

  group('termsSummary', () {
    test('summarizes terms the way the canvas does', () {
      expect(termsSummary(termsVersion()), '릴스 1편, 35만 원 + 제품, 11월 23일 시작');
    });

    test('adds the performance bonus to the terms summary', () {
      expect(
        termsSummary(
          termsVersion(
            performance: const ViewPay(ratePerThousand: 2000, cap: 60000),
          ),
        ),
        '릴스 1편, 35만 원 + 제품 + 성과 추가, 11월 23일 시작',
      );
    });

    test('leaves out the product when none is provided', () {
      expect(
        termsSummary(termsVersion(productProvided: false)),
        '릴스 1편, 35만 원, 11월 23일 시작',
      );
    });
  });

  group('statusLine', () {
    test('names who has not confirmed yet', () {
      expect(
        statusLine(roomDetail(terms: termsVersion())),
        '조건 버전 2 · 브랜드 확인 대기',
      );
      expect(
        statusLine(
          roomDetail(
            terms: termsVersion(brandConfirmed: true, creatorConfirmed: false),
          ),
        ),
        '조건 버전 2 · 크리에이터 확인 대기',
      );
      expect(
        statusLine(
          roomDetail(terms: termsVersion(version: 1, creatorConfirmed: false)),
        ),
        '조건 버전 1 · 양쪽 확인 대기',
      );
    });

    test('follows the contract after both confirmed', () {
      final agreed = termsVersion(brandConfirmed: true);
      expect(
        statusLine(roomDetail(stage: ConversationStage.agreed, terms: agreed)),
        '조건 버전 2 · 합의됨 · 계약 대기',
      );
      expect(
        statusLine(
          roomDetail(
            stage: ConversationStage.agreed,
            contractStatus: ContractProgress.awaitingBrand,
            terms: agreed,
          ),
        ),
        '크리에이터 동의함 · 브랜드 결제 대기',
      );
      expect(
        statusLine(roomDetail(stage: ConversationStage.contracted)),
        '계약 체결 · 제작 중',
      );
      expect(statusLine(roomDetail(stage: ConversationStage.settled)), '협업 완료');
    });

    test('says so for an inquiry, a dropped negotiation and a halt', () {
      expect(statusLine(requestDetail('r1')), '서로 관심 전 · 조건 문의 중');
      expect(
        statusLine(roomDetail(stage: ConversationStage.dropped)),
        '협의가 끝났어요',
      );
      expect(
        statusLine(roomDetail(stage: ConversationStage.halted)),
        '운영팀 확인 중',
      );
    });
  });

  group('rowMessage', () {
    test('shows the last message of an open room', () {
      expect(rowMessage(summary('a', preview: '안녕하세요!')), '안녕하세요!');
    });

    test('shows the first message of a request I have to answer', () {
      expect(
        rowMessage(requestSummary('a', preview: '조건부터 여쭤볼게요.')),
        '조건부터 여쭤볼게요.',
      );
    });

    test('tells the requester the request is waiting, declined or closed', () {
      expect(
        rowMessage(summary('a', status: ConversationStatus.requested)),
        '수락을 기다리고 있어요',
      );
      expect(
        rowMessage(summary('a', status: ConversationStatus.declined)),
        '대화가 열리지 않았어요.',
      );
      expect(
        rowMessage(summary('a', status: ConversationStatus.closed)),
        '대화가 종료됐어요.',
      );
    });
  });

  test('builds the three request cells from the campaign terms', () {
    final terms = requestDetail('r1').campaignTerms!;
    expect(requestDeliverable(terms), '릴스 1편');
    expect(requestFee(terms), '30만 원');
    expect(requestShooting(terms), '11/16 이후');
  });
}
