import '../../core/json.dart';
import '../../domain/entities/models.dart';
import '../../domain/repositories/automation_repository.dart';
import '../datasources/automation_remote_data_source.dart';

class AutomationRepositoryImpl implements AutomationRepository {
  AutomationRepositoryImpl(this._remote);

  final AutomationRemoteDataSource _remote;

  @override
  Future<List<AutomationFlow>> automations(int id, String triggerType) => _remote.automations(id, triggerType);

  @override
  Future<AutomationFlow> saveAutomation(int id, Json data, {int? flowId}) => _remote.saveAutomation(id, data, flowId: flowId);

  @override
  Future<void> deleteAutomation(int id, int flowId) => _remote.deleteAutomation(id, flowId);
}
