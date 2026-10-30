import '../entities/models.dart';

abstract class AnalyticsRepository {
  Future<AnalyticsOverview> analytics(int id);
}
