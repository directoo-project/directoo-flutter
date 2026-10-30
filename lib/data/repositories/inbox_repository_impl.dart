import '../../domain/entities/models.dart';
import '../../domain/repositories/inbox_repository.dart';
import '../datasources/inbox_remote_data_source.dart';

class InboxRepositoryImpl implements InboxRepository {
  InboxRepositoryImpl(this._remote);

  final InboxRemoteDataSource _remote;

  @override
  Future<PageResult<DirectChat>> directChats(int id, {int page = 1}) => _remote.directChats(id, page: page);

  @override
  Future<PageResult<DirectMessage>> directMessages(int id, String chatId, {int page = 1}) => _remote.directMessages(id, chatId, page: page);

  @override
  Future<void> sendDirect(int id, String chatId, String text) => _remote.sendDirect(id, chatId, text);

  @override
  Future<PageResult<IgComment>> comments(int id, {int page = 1}) => _remote.comments(id, page: page);

  @override
  Future<void> replyComment(int id, {required String commentId, required String text, String? mediaId}) => _remote.replyComment(id, commentId: commentId, text: text, mediaId: mediaId);
}
