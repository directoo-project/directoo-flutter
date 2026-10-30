import '../../core/api_client.dart';
import '../../core/api_exception.dart';
import '../../core/json.dart';
import '../../domain/entities/models.dart';
import 'api_paths.dart';

abstract class InstagramRemoteDataSource {
  Future<void> deleteInstagramAccount(int id, int accountId);
  Future<List<InstagramAccount>> instagramAccounts(int id);
  Future<String> startInstagramOAuth(int id);
  Future<InstagramAccessRequest?> accessRequest(int id);
  Future<InstagramAccessRequest> submitAccessRequest(int id, String username);
  Future<InstagramAccessRequest> confirmFacebook(int id);
}

class InstagramRemoteDataSourceImpl implements InstagramRemoteDataSource {
  InstagramRemoteDataSourceImpl(this._client);

  final ApiClient _client;

  @override
  Future<void> deleteInstagramAccount(int id, int accountId) {
      return _client.delete(workspacePath(id, 'instagram/accounts/$accountId/'), auth: true);
    }

  @override
  Future<List<InstagramAccount>> instagramAccounts(int id) {
      return _client.get(
        workspacePath(id, 'instagram/accounts/'),
        auth: true,
        parse: (data) => [for (final item in asJsonList(data)) InstagramAccount.fromJson(item)],
      );
    }

  @override
  Future<String> startInstagramOAuth(int id) async {
      final data = await _client.post<Json>(workspacePath(id, 'instagram/oauth/start/'), auth: true, parse: asJson);
      return asString(data['authorization_url']);
    }

  @override
  Future<InstagramAccessRequest?> accessRequest(int id) async {
      try {
        return await _client.get(
          workspacePath(id, 'instagram/access-request/'),
          auth: true,
          parse: (data) => InstagramAccessRequest.fromJson(asJson(data)),
        );
      } on ApiException catch (error) {
        if (error.status == 404) return null;
        rethrow;
      }
    }

  @override
  Future<InstagramAccessRequest> submitAccessRequest(int id, String username) {
      return _client.post(
        workspacePath(id, 'instagram/access-request/'),
        auth: true,
        data: {'username': username},
        parse: (data) => InstagramAccessRequest.fromJson(asJson(data)),
      );
    }

  @override
  Future<InstagramAccessRequest> confirmFacebook(int id) {
      return _client.post(
        workspacePath(id, 'instagram/access-request/confirm-facebook/'),
        auth: true,
        parse: (data) => InstagramAccessRequest.fromJson(asJson(data)),
      );
    }
}
