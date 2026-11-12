import 'package:cora_api/api.dart' as api;

import '../../../core/network/api_error.dart';
import '../domain/instagram_connection.dart';
import '../domain/instagram_repository.dart';

/// 생성된 API 클라이언트(`cora_api`)로 인스타그램 연동을 읽고 연결한다. 생성된 타입은 이 파일 밖으로
/// 내보내지 않는다.
class ApiInstagramRepository implements InstagramRepository {
  ApiInstagramRepository(api.ApiClient client)
    : _instagram = api.InstagramApi(client);

  final api.InstagramApi _instagram;

  @override
  Future<InstagramConnection?> fetch() async {
    try {
      final m = await _instagram.getInstagramConnection();
      return m == null ? null : _fromModel(m);
    } catch (error) {
      // 연결된 계정이 없으면 서버가 404로 답한다. 실패가 아니라 "없음"이다.
      if (ApiError.from(error).isNotFound) return null;
      throw _failure(error);
    }
  }

  @override
  Future<String> begin() async {
    try {
      final m = await _instagram.beginInstagramConnect();
      if (m == null) throw const InstagramFailure();
      return m.connectUrl;
    } on InstagramFailure {
      rethrow;
    } catch (error) {
      throw _failure(error);
    }
  }

  @override
  Future<InstagramConnection> complete(String code) async {
    try {
      final m = await _instagram.completeInstagramConnect(
        api.CompleteInstagramConnectDto(code: code),
      );
      if (m == null) throw const InstagramFailure();
      return _fromModel(m);
    } on InstagramFailure {
      rethrow;
    } catch (error) {
      throw _failure(error);
    }
  }

  /// 서버 문구는 4xx일 때만 담는다. 5xx 본문은 화면에 보이지 않는다.
  static InstagramFailure _failure(Object error) {
    final e = ApiError.from(error);
    final status = e.status;
    return InstagramFailure(
      message: status != null && status >= 400 && status < 500
          ? e.message
          : null,
    );
  }

  static InstagramConnection _fromModel(api.InstagramConnectionModel m) =>
      InstagramConnection(handle: m.handle, followers: m.followers);
}
