import '../../domain/entities/models.dart';
import '../../domain/repositories/instagram_repository.dart';
import '../datasources/instagram_remote_data_source.dart';

class InstagramRepositoryImpl implements InstagramRepository {
  InstagramRepositoryImpl(this._remote);

  final InstagramRemoteDataSource _remote;

  @override
  Future<void> deleteInstagramAccount(int id, int accountId) => _remote.deleteInstagramAccount(id, accountId);

  @override
  Future<List<InstagramAccount>> instagramAccounts(int id) => _remote.instagramAccounts(id);

  @override
  Future<String> startInstagramOAuth(int id) => _remote.startInstagramOAuth(id);

  @override
  Future<InstagramAccessRequest?> accessRequest(int id) => _remote.accessRequest(id);

  @override
  Future<InstagramAccessRequest> submitAccessRequest(int id, String username) => _remote.submitAccessRequest(id, username);

  @override
  Future<InstagramAccessRequest> confirmFacebook(int id) => _remote.confirmFacebook(id);
}
