import '../../core/json.dart';
import '../entities/models.dart';

abstract class WorkspaceRepository {
  Future<List<Workspace>> workspaces();
  Future<Workspace> createWorkspace(String name);
  Future<Workspace> updateWorkspace(int id, Json data);
  Future<List<WorkspaceMember>> members(int id);
  Future<WorkspaceMember> addMember(int id, String phone, String role);
}
