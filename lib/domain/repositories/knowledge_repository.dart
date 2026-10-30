import '../../core/json.dart';
import '../entities/models.dart';

abstract class KnowledgeRepository {
  Future<BusinessInfo> business(int id);
  Future<BusinessInfo> updateBusiness(int id, Json data);
  Future<AiRules> rules(int id);
  Future<AiRules> updateRules(int id, Json data);
  Future<List<Faq>> faqs(int id);
  Future<Faq> saveFaq(int id, {int? faqId, required String question, required String answer});
  Future<void> deleteFaq(int id, int faqId);
}
