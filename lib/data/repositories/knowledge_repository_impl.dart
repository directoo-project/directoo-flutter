import '../../core/json.dart';
import '../../domain/entities/models.dart';
import '../../domain/repositories/knowledge_repository.dart';
import '../datasources/knowledge_remote_data_source.dart';

class KnowledgeRepositoryImpl implements KnowledgeRepository {
  KnowledgeRepositoryImpl(this._remote);

  final KnowledgeRemoteDataSource _remote;

  @override
  Future<BusinessInfo> business(int id) => _remote.business(id);

  @override
  Future<BusinessInfo> updateBusiness(int id, Json data) => _remote.updateBusiness(id, data);

  @override
  Future<AiRules> rules(int id) => _remote.rules(id);

  @override
  Future<AiRules> updateRules(int id, Json data) => _remote.updateRules(id, data);

  @override
  Future<List<Faq>> faqs(int id) => _remote.faqs(id);

  @override
  Future<Faq> saveFaq(int id, {int? faqId, required String question, required String answer}) => _remote.saveFaq(id, faqId: faqId, question: question, answer: answer);

  @override
  Future<void> deleteFaq(int id, int faqId) => _remote.deleteFaq(id, faqId);
}
