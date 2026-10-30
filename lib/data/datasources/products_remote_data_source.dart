import '../../core/api_client.dart';
import '../../core/json.dart';
import '../../domain/entities/models.dart';
import 'api_paths.dart';

abstract class ProductsRemoteDataSource {
  Future<List<Product>> products(int id, {String? search});
  Future<Product> saveProduct(int id, Json data, {int? productId});
  Future<void> deleteProduct(int id, int productId);
}

class ProductsRemoteDataSourceImpl implements ProductsRemoteDataSource {
  ProductsRemoteDataSourceImpl(this._client);

  final ApiClient _client;

  @override
  Future<List<Product>> products(int id, {String? search}) {
      final query = <String, String>{if (search != null && search.isNotEmpty) 'search': search};
      return _client.get(
        Uri(path: workspacePath(id, 'products/'), queryParameters: query).toString(),
        auth: true,
        parse: (data) => [for (final item in asJsonList(data)) Product.fromJson(item)],
      );
    }

  @override
  Future<Product> saveProduct(int id, Json data, {int? productId}) {
      final path = productId == null ? workspacePath(id, 'products/') : workspacePath(id, 'products/$productId/');
      if (productId == null) {
        return _client.post(path, auth: true, data: data, parse: (body) => Product.fromJson(asJson(body)));
      }
      return _client.patch(path, auth: true, data: data, parse: (body) => Product.fromJson(asJson(body)));
    }

  @override
  Future<void> deleteProduct(int id, int productId) => _client.delete(workspacePath(id, 'products/$productId/'), auth: true);
}
