import '../../core/api_client.dart';
import '../../core/json.dart';
import '../../domain/entities/models.dart';

abstract class TutorialsRemoteDataSource {
  Future<List<MenuTutorial>> tutorials();
}

class TutorialsRemoteDataSourceImpl implements TutorialsRemoteDataSource {
  TutorialsRemoteDataSourceImpl(this._client);

  final ApiClient _client;

  @override
  Future<List<MenuTutorial>> tutorials() {
      return _client.get(
        '/api/v1/menu-tutorials/',
        auth: true,
        parse: (data) => [for (final item in asJsonList(data)) MenuTutorial.fromJson(item)],
      );
    }
}
