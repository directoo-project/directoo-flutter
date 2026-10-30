import '../../core/api_client.dart';
import '../../domain/entities/models.dart';
import 'api_paths.dart';

abstract class InboxRemoteDataSource {
  Future<PageResult<DirectChat>> directChats(int id, {int page = 1});
  Future<PageResult<DirectMessage>> directMessages(int id, String chatId, {int page = 1});
  Future<void> sendDirect(int id, String chatId, String text);
  Future<PageResult<IgComment>> comments(int id, {int page = 1});
  Future<void> replyComment(int id, {required String commentId, required String text, String? mediaId});
}

class InboxRemoteDataSourceImpl implements InboxRemoteDataSource {
  InboxRemoteDataSourceImpl(this._client);

  final ApiClient _client;

  @override
  Future<PageResult<DirectChat>> directChats(int id, {int page = 1}) {
      return _client.get(
        workspacePath(id, 'instagram/directs/chats/?page=$page&page_size=30'),
        auth: true,
        parse: (data) => PageResult.parse(data, DirectChat.fromJson),
      );
    }

  @override
  Future<PageResult<DirectMessage>> directMessages(int id, String chatId, {int page = 1}) {
      final encoded = Uri.encodeComponent(chatId);
      return _client.get(
        workspacePath(id, 'instagram/directs/chats/$encoded/messages/?page=$page&page_size=50&order=asc'),
        auth: true,
        parse: (data) => PageResult.parse(data, DirectMessage.fromJson),
      );
    }

  @override
  Future<void> sendDirect(int id, String chatId, String text) async {
      await _client.post(workspacePath(id, 'instagram/directs/send/'), auth: true, data: {'chat_id': chatId, 'text': text});
    }

  @override
  Future<PageResult<IgComment>> comments(int id, {int page = 1}) {
      return _client.get(
        workspacePath(id, 'instagram/comments/?page=$page&page_size=30'),
        auth: true,
        parse: (data) => PageResult.parse(data, IgComment.fromJson),
      );
    }

  @override
  Future<void> replyComment(int id, {required String commentId, required String text, String? mediaId}) async {
      await _client.post(
        workspacePath(id, 'instagram/comments/reply/'),
        auth: true,
        data: {
          'comment_id': commentId,
          'text': text,
          if (mediaId != null && mediaId.isNotEmpty) 'media_id': mediaId,
        },
      );
    }
}
