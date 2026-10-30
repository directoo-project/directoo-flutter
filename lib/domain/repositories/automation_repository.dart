import '../../core/json.dart';
import '../entities/models.dart';

abstract class AutomationRepository {
  Future<List<AutomationFlow>> automations(int id, String triggerType);
  Future<AutomationFlow> saveAutomation(int id, Json data, {int? flowId});
  Future<void> deleteAutomation(int id, int flowId);
}
