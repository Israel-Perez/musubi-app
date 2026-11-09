import 'package:dio/dio.dart';
import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/core/network/api_paths.dart';
import 'package:musubi_app/features/chat/domain/chat_models.dart';
import 'package:musubi_app/features/chat/domain/chat_repository.dart';
import 'package:musubi_app/features/marketplace/data/product_json.dart';

/// [ChatRepository] sobre las filas "M-07" de `musubi-api/docs/endpoints.md`
/// (specs `musubi-api:HU-20` y `HU-22`). Usa el cliente con sesion.
class HttpChatRepository implements ChatRepository {
  new(this._dio, this._apiBaseUrl);

  final Dio _dio;
  final Uri _apiBaseUrl;

  @override
  Future<Conversation> start(String productId) => _guard(() async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiPaths.conversations,
      data: {'productId': productId},
    );
    return _conversation(_body(response));
  });

  @override
  Future<Conversation> conversation(String id) => _guard(() async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiPaths.conversation(id),
    );
    return _conversation(_body(response));
  });

  @override
  Future<MessagePage> messages(String conversationId, {String? cursor}) =>
      _guard(() async {
        final response = await _dio.get<Map<String, dynamic>>(
          ApiPaths.conversationMessages(conversationId),
          queryParameters: {'cursor': ?cursor},
        );
        final body = _body(response);
        return MessagePage(
          items: [
            for (final item
                in (body['items'] as List<dynamic>)
                    .cast<Map<String, dynamic>>())
              messageFromJson(item),
          ],
          nextCursor: body['nextCursor'] as String?,
        );
      });

  @override
  Future<ChatMessage> send(String conversationId, String text) =>
      _guard(() async {
        final response = await _dio.post<Map<String, dynamic>>(
          ApiPaths.conversationMessages(conversationId),
          data: {'text': text},
        );
        return messageFromJson(_body(response));
      });

  @override
  Future<InboxPage> inbox({
    InboxFilter filter = InboxFilter.all,
    String? cursor,
  }) => _guard(() async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiPaths.conversations,
      queryParameters: {'role': ?filter.role, 'cursor': ?cursor},
    );
    final body = _body(response);
    return InboxPage(
      items: [
        for (final item
            in (body['items'] as List<dynamic>).cast<Map<String, dynamic>>())
          _inboxEntry(item),
      ],
      nextCursor: body['nextCursor'] as String?,
    );
  });

  @override
  Future<void> markRead(String conversationId) => _guard(() async {
    await _dio.post<void>(ApiPaths.conversationRead(conversationId));
  });

  Conversation _conversation(Map<String, dynamic> json) {
    final context = json['context'] as Map<String, dynamic>;
    final photo = context['photo'] as String?;
    return Conversation(
      id: json['id'] as String,
      role: ChatRole.parse(json['role']),
      counterpart: _counterpart(json['counterpart']),
      // Una API anterior a HU-57 no lo manda: se puede responder.
      canReply: json['canReply'] as bool? ?? true,
      context: ChatContext(
        id: context['id'] as String,
        title: context['title'] as String,
        available: context['available'] as bool? ?? false,
        type: context['type'] as String? ?? 'product',
        priceCents: (context['priceCents'] as num?)?.toInt(),
        condition: context['condition'] as String?,
        conditionDetail: context['conditionDetail'] as String?,
        photoUrl: photo == null ? null : mediaUrl(photo, _apiBaseUrl),
      ),
    );
  }

  InboxEntry _inboxEntry(Map<String, dynamic> json) {
    final context = json['context'] as Map<String, dynamic>;
    final last = json['lastMessage'] as Map<String, dynamic>;
    final photo = context['photo'] as String?;
    return InboxEntry(
      id: json['id'] as String,
      role: ChatRole.parse(json['role']),
      counterpart: _counterpart(json['counterpart']),
      contextTitle: context['title'] as String,
      contextPhotoUrl: photo == null ? null : mediaUrl(photo, _apiBaseUrl),
      lastSenderId: last['senderId'] as String,
      lastText: last['text'] as String,
      lastAt: DateTime.parse(last['sentAt'] as String).toUtc(),
      unread: (json['unread'] as num?)?.toInt() ?? 0,
    );
  }

  ChatCounterpart _counterpart(Object? json) {
    final map = json! as Map<String, dynamic>;
    final photo = map['photo'] as String?;
    return ChatCounterpart(
      id: map['id'] as String,
      name: map['name'] as String,
      photoUrl: photo == null ? null : mediaUrl(photo, _apiBaseUrl),
    );
  }

  static Map<String, dynamic> _body(Response<Map<String, dynamic>> response) =>
      response.data ?? const {};

  static Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (error) {
      throw ApiFailure.fromDio(error);
    }
  }
}

/// Un `MessageResponse` de la API (tambien la carga de `messageCreated`).
ChatMessage messageFromJson(Map<String, dynamic> json) => ChatMessage(
  id: json['id'] as String,
  conversationId: json['conversationId'] as String,
  senderId: json['senderId'] as String,
  text: json['text'] as String,
  sentAt: DateTime.parse(json['sentAt'] as String).toUtc(),
);
