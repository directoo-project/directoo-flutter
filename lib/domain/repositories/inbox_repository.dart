import '../entities/models.dart';

abstract class InboxRepository {
  Future<PageResult<DirectChat>> directChats(int id, {int page = 1});
  Future<PageResult<DirectMessage>> directMessages(int id, String chatId, {int page = 1});
  Future<void> sendDirect(int id, String chatId, String text);
  Future<PageResult<IgComment>> comments(int id, {int page = 1});
  Future<void> replyComment(int id, {required String commentId, required String text, String? mediaId});
}
