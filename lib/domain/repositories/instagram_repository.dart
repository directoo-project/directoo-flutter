import '../entities/models.dart';

abstract class InstagramRepository {
  Future<void> deleteInstagramAccount(int id, int accountId);
  Future<List<InstagramAccount>> instagramAccounts(int id);
  Future<String> startInstagramOAuth(int id);
  Future<InstagramAccessRequest?> accessRequest(int id);
  Future<InstagramAccessRequest> submitAccessRequest(int id, String username);
  Future<InstagramAccessRequest> confirmFacebook(int id);
}
