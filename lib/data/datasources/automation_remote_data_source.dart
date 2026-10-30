import '../../core/api_client.dart';
import '../../core/json.dart';
import '../../domain/entities/models.dart';
import 'api_paths.dart';

abstract class AutomationRemoteDataSource {
  Future<List<AutomationFlow>> automations(int id, String triggerType);
  Future<AutomationFlow> saveAutomation(int id, Json data, {int? flowId});
  Future<void> deleteAutomation(int id, int flowId);
}

class AutomationRemoteDataSourceImpl implements AutomationRemoteDataSource {
  AutomationRemoteDataSourceImpl(this._client);

  final ApiClient _client;

  @override
  Future<List<AutomationFlow>> automations(int id, String triggerType) {
      return _client.get(
        workspacePath(id, 'automations/?trigger_type=$triggerType'),
        auth: true,
        parse: (data) => [for (final item in asJsonList(data)) AutomationFlow.fromJson(item)],
      );
    }

  @override
  Future<AutomationFlow> saveAutomation(int id, Json data, {int? flowId}) {
      final path = flowId == null ? workspacePath(id, 'automations/') : workspacePath(id, 'automations/$flowId/');
      if (flowId == null) {
        return _client.post(path, auth: true, data: data, parse: (body) => AutomationFlow.fromJson(asJson(body)));
      }
      return _client.patch(path, auth: true, data: data, parse: (body) => AutomationFlow.fromJson(asJson(body)));
    }

  @override
  Future<void> deleteAutomation(int id, int flowId) => _client.delete(workspacePath(id, 'automations/$flowId/'), auth: true);
}
