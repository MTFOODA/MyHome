import 'package:dio/dio.dart';
import '../../auth/data/api_auth_repository.dart';
import '../../auth/domain/auth_repository.dart';
import '../domain/chat_repository.dart';

class ApiChatRepository implements ChatRepository {
  final ApiAuthRepository auth;
  const ApiChatRepository(this.auth);
  Future<T> _call<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on DioException catch (e) {
      final data = e.response?.data;
      throw ChatFailure(
        data is Map && data['detail'] is String
            ? data['detail'] as String
            : 'NETWORK_ERROR',
      );
    } on AuthException catch (e) {
      throw ChatFailure(
        e.failure == AuthFailure.credentials
            ? 'CHAT_ACCESS_REVOKED'
            : 'NETWORK_ERROR',
      );
    }
  }

  @override
  Future<String> openDeal(String id) => _call(
    () async =>
        (await auth.authorizedRequest(
              '/deals/$id/conversation',
              method: 'POST',
            ))['id']
            as String,
  );
  @override
  Future<String> openGroup(String id) => _call(
    () async =>
        (await auth.authorizedRequest(
              '/groups/$id/conversation',
              method: 'POST',
            ))['id']
            as String,
  );
  @override
  Future<ChatBatch> read(String id, {int? before, int? after}) =>
      _call(() async {
        final query = Uri(
          queryParameters: {
            if (before != null) 'before_id': '$before',
            if (after != null) 'after_id': '$after',
          },
        ).query;
        final data = await auth.authorizedRequest(
          '/conversations/$id/messages${query.isEmpty ? '' : '?$query'}',
        );
        return ChatBatch(
          (data['items'] as List)
              .map(
                (v) =>
                    ChatMessage.fromJson(Map<String, dynamic>.from(v as Map)),
              )
              .toList(),
          data['next_before'] as int?,
        );
      });
  @override
  Future<ChatMessage> send(String id, String text) => _call(
    () async => ChatMessage.fromJson(
      Map<String, dynamic>.from(
        await auth.authorizedRequest(
              '/conversations/$id/messages',
              method: 'POST',
              data: {'text': text},
            )
            as Map,
      ),
    ),
  );
}
