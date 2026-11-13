import 'package:cora/features/store_onboarding/domain/source_link.dart';
import 'package:cora/features/store_onboarding/presentation/viewmodels/store_links_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_store_repository.dart';
import 'store_view_model_support.dart';

Future<ProviderContainer> _open({FakeStoreRepository? stores}) async {
  final container = storeContainer(stores: stores);
  // autoDispose 상태가 테스트 동안 살아 있게 듣는다.
  container.listen(storeLinksViewModelProvider, (_, _) {});
  await container.read(storeLinksViewModelProvider.future);
  return container;
}

StoreLinksViewModel _vm(ProviderContainer c) =>
    c.read(storeLinksViewModelProvider.notifier);
StoreLinksState _state(ProviderContainer c) =>
    c.read(storeLinksViewModelProvider).requireValue;

void main() {
  test('cannot submit without a link', () async {
    final c = await _open();
    expect(_state(c).canSubmit, isFalse);
  });

  test('accepts hosts without https and rejects other services', () {
    expect(SourceLinkKind.naverMap.accepts('naver.me/abc'), isTrue);
    expect(
      SourceLinkKind.naverMap.accepts('https://map.naver.com/p/1'),
      isTrue,
    );
    expect(SourceLinkKind.naverMap.accepts('https://naver.com/x'), isFalse);
    expect(SourceLinkKind.naverMap.accepts('http://naver.me/abc'), isFalse);
    expect(SourceLinkKind.catchtable.accepts('app.catchtable.co.kr/x'), isTrue);
    expect(
      SourceLinkKind.instagram.accepts('https://www.instagram.com/a'),
      isTrue,
    );
    expect(
      SourceLinkKind.instagram.accepts('https://evil.com/instagram.com'),
      isFalse,
    );
    expect(SourceLinkKind.naverMap.accepts('https://user@naver.me/a'), isFalse);
  });

  test('accepts naver blog and tistory urls as a review post', () {
    const kind = SourceLinkKind.reviewPost;
    expect(kind.accepts('blog.naver.com/shop/123'), isTrue);
    expect(kind.accepts('https://m.blog.naver.com/shop/123'), isTrue);
    expect(kind.accepts('https://shop.tistory.com/12'), isTrue);
    expect(kind.accepts('https://evil-tistory.com/12'), isFalse);
    expect(kind.accepts('https://tistory.com/12'), isFalse);
    expect(kind.accepts('https://example.com/blog.naver.com'), isFalse);
    // 다른 종류는 티스토리를 받지 않는다.
    expect(
      SourceLinkKind.instagram.accepts('https://a.tistory.com/1'),
      isFalse,
    );
    expect(kind.invalidHint, '체험단 후기 글 링크가 맞는지 확인해 주세요.');
  });

  test('one valid link enables submit, one invalid link disables it', () async {
    final c = await _open();

    _vm(c).setInput(SourceLinkKind.naverMap, 'naver.me/abc');
    expect(_state(c).canSubmit, isTrue);

    _vm(c).setInput(SourceLinkKind.instagram, 'https://example.com');
    expect(_state(c).isInvalid(SourceLinkKind.instagram), isTrue);
    expect(_state(c).canSubmit, isFalse);

    _vm(c).setInput(SourceLinkKind.instagram, '   ');
    expect(_state(c).canSubmit, isTrue);
  });

  test(
    'starts from the links of the saved store with their summaries',
    () async {
      final c = await _open(stores: FakeStoreRepository(store: sampleStore()));

      expect(_state(c).textOf(SourceLinkKind.naverMap), 'naver.me/abc');
      expect(_state(c).summaryOf(SourceLinkKind.naverMap), '사진 12장, 메뉴 8개 찾음');
      expect(_state(c).summaryOf(SourceLinkKind.catchtable), isNull);

      _vm(c).setInput(SourceLinkKind.naverMap, 'naver.me/other');
      expect(_state(c).summaryOf(SourceLinkKind.naverMap), isNull);
    },
  );

  test('submit sends normalized urls and reports the outcome', () async {
    final stores = FakeStoreRepository();
    final c = await _open(stores: stores);
    _vm(c).setInput(SourceLinkKind.naverMap, ' naver.me/abc ');
    _vm(c).setInput(SourceLinkKind.instagram, 'instagram.com/shop');

    final outcome = await _vm(c).submit();

    expect(outcome, StoreLinksOutcome.analyzed);
    expect(stores.analyzed.single.map((l) => l.url), [
      'https://naver.me/abc',
      'https://instagram.com/shop',
    ]);
    expect(_state(c).analyzing, isFalse);
    expect(_state(c).summaryOf(SourceLinkKind.naverMap), isNotNull);
  });

  test('submit reports an analysis that read nothing', () async {
    final c = await _open(stores: FakeStoreRepository()..analysisFails = true);
    _vm(c).setInput(SourceLinkKind.naverMap, 'naver.me/fail');

    expect(await _vm(c).submit(), StoreLinksOutcome.analysisFailed);
    expect(_state(c).analyzing, isFalse);
    expect(_state(c).errorMessage, isNull);
  });

  test(
    'submit keeps the input and sets a message when the server fails',
    () async {
      final c = await _open(stores: FakeStoreRepository()..failAnalyze = true);
      _vm(c).setInput(SourceLinkKind.naverMap, 'naver.me/abc');

      expect(await _vm(c).submit(), StoreLinksOutcome.failed);

      expect(_state(c).errorMessage, StoreLinksViewModel.unreachable);
      expect(_state(c).textOf(SourceLinkKind.naverMap), 'naver.me/abc');
      expect(_state(c).canSubmit, isTrue);
    },
  );
}
