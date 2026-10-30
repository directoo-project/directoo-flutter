import '../../core/api_client.dart';
import '../../core/json.dart';
import '../../domain/entities/models.dart';
import 'api_paths.dart';

abstract class AnalyticsRemoteDataSource {
  Future<AnalyticsOverview> analytics(int id);
}

class AnalyticsRemoteDataSourceImpl implements AnalyticsRemoteDataSource {
  AnalyticsRemoteDataSourceImpl(this._client);

  final ApiClient _client;

  @override
  Future<AnalyticsOverview> analytics(int id) {
      return _client.get(workspacePath(id, 'analytics/overview/'), auth: true, parse: (data) => AnalyticsOverview.fromJson(asJson(data)));
    }
}
