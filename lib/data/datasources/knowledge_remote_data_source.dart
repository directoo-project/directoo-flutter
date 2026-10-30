import '../../core/api_client.dart';
import '../../core/json.dart';
import '../../domain/entities/models.dart';
import 'api_paths.dart';

abstract class KnowledgeRemoteDataSource {
  Future<BusinessInfo> business(int id);
  Future<BusinessInfo> updateBusiness(int id, Json data);
  Future<AiRules> rules(int id);
  Future<AiRules> updateRules(int id, Json data);
  Future<List<Faq>> faqs(int id);
  Future<Faq> saveFaq(int id, {int? faqId, required String question, required String answer});
  Future<void> deleteFaq(int id, int faqId);
}

class KnowledgeRemoteDataSourceImpl implements KnowledgeRemoteDataSource {
  KnowledgeRemoteDataSourceImpl(this._client);

  final ApiClient _client;

  @override
  Future<BusinessInfo> business(int id) {
      return _client.get(workspacePath(id, 'knowledge/business/'), auth: true, parse: (data) => BusinessInfo.fromJson(asJson(data)));
    }

  @override
  Future<BusinessInfo> updateBusiness(int id, Json data) {
      return _client.patch(workspacePath(id, 'knowledge/business/'), auth: true, data: data, parse: (body) => BusinessInfo.fromJson(asJson(body)));
    }

  @override
  Future<AiRules> rules(int id) {
      return _client.get(workspacePath(id, 'knowledge/rules/'), auth: true, parse: (data) => AiRules.fromJson(asJson(data)));
    }

  @override
  Future<AiRules> updateRules(int id, Json data) {
      return _client.patch(workspacePath(id, 'knowledge/rules/'), auth: true, data: data, parse: (body) => AiRules.fromJson(asJson(body)));
    }

  @override
  Future<List<Faq>> faqs(int id) {
      return _client.get(workspacePath(id, 'faqs/'), auth: true, parse: (data) => [for (final item in asJsonList(data)) Faq.fromJson(item)]);
    }

  @override
  Future<Faq> saveFaq(int id, {int? faqId, required String question, required String answer}) {
      final path = faqId == null ? workspacePath(id, 'faqs/') : workspacePath(id, 'faqs/$faqId/');
      final payload = {'question': question, 'answer': answer};
      if (faqId == null) {
        return _client.post(path, auth: true, data: payload, parse: (data) => Faq.fromJson(asJson(data)));
      }
      return _client.patch(path, auth: true, data: payload, parse: (data) => Faq.fromJson(asJson(data)));
    }

  @override
  Future<void> deleteFaq(int id, int faqId) => _client.delete(workspacePath(id, 'faqs/$faqId/'), auth: true);
}
