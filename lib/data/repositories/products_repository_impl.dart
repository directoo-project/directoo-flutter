import '../../core/json.dart';
import '../../domain/entities/models.dart';
import '../../domain/repositories/products_repository.dart';
import '../datasources/products_remote_data_source.dart';

class ProductsRepositoryImpl implements ProductsRepository {
  ProductsRepositoryImpl(this._remote);

  final ProductsRemoteDataSource _remote;

  @override
  Future<List<Product>> products(int id, {String? search}) => _remote.products(id, search: search);

  @override
  Future<Product> saveProduct(int id, Json data, {int? productId}) => _remote.saveProduct(id, data, productId: productId);

  @override
  Future<void> deleteProduct(int id, int productId) => _remote.deleteProduct(id, productId);
}
