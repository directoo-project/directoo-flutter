import '../../core/json.dart';
import '../entities/models.dart';

abstract class ProductsRepository {
  Future<List<Product>> products(int id, {String? search});
  Future<Product> saveProduct(int id, Json data, {int? productId});
  Future<void> deleteProduct(int id, int productId);
}
