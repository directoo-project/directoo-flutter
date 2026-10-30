import '../../core/json.dart';
import '../../domain/entities/models.dart';
import '../../domain/repositories/workspace_repository.dart';
import '../datasources/workspace_remote_data_source.dart';

class WorkspaceRepositoryImpl implements WorkspaceRepository {
  WorkspaceRepositoryImpl(this._remote);

  final WorkspaceRemoteDataSource _remote;

  @override
  Future<List<Workspace>> workspaces() => _remote.workspaces();

  @override
  Future<Workspace> createWorkspace(String name) => _remote.createWorkspace(name);

  @override
  Future<Workspace> updateWorkspace(int id, Json data) => _remote.updateWorkspace(id, data);

  @override
  Future<List<WorkspaceMember>> members(int id) => _remote.members(id);

  @override
  Future<WorkspaceMember> addMember(int id, String phone, String role) => _remote.addMember(id, phone, role);
}
