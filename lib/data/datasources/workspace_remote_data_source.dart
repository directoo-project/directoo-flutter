import '../../core/api_client.dart';
import '../../core/json.dart';
import '../../domain/entities/models.dart';
import 'api_paths.dart';

abstract class WorkspaceRemoteDataSource {
  Future<List<Workspace>> workspaces();
  Future<Workspace> createWorkspace(String name);
  Future<Workspace> updateWorkspace(int id, Json data);
  Future<List<WorkspaceMember>> members(int id);
  Future<WorkspaceMember> addMember(int id, String phone, String role);
}

class WorkspaceRemoteDataSourceImpl implements WorkspaceRemoteDataSource {
  WorkspaceRemoteDataSourceImpl(this._client);

  final ApiClient _client;

  @override
  Future<List<Workspace>> workspaces() {
      return _client.get('/api/v1/workspaces/', auth: true, parse: (data) => [for (final item in asJsonList(data)) Workspace.fromJson(item)]);
    }

  @override
  Future<Workspace> createWorkspace(String name) {
      return _client.post('/api/v1/workspaces/', auth: true, data: {'name': name}, parse: (data) => Workspace.fromJson(asJson(data)));
    }

  @override
  Future<Workspace> updateWorkspace(int id, Json data) {
      return _client.patch('/api/v1/workspaces/$id/', auth: true, data: data, parse: (body) => Workspace.fromJson(asJson(body)));
    }

  @override
  Future<List<WorkspaceMember>> members(int id) {
      return _client.get(workspacePath(id, 'members/'), auth: true, parse: (data) => [for (final item in asJsonList(data)) WorkspaceMember.fromJson(item)]);
    }

  @override
  Future<WorkspaceMember> addMember(int id, String phone, String role) {
      return _client.post(
        workspacePath(id, 'members/'),
        auth: true,
        data: {'phone_number': phone, 'role': role},
        parse: (data) => WorkspaceMember.fromJson(asJson(data)),
      );
    }
}
