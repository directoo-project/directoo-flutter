import '../../core/json.dart';
import '../entities/models.dart';

abstract class CustomersRepository {
  Future<List<Customer>> customers(int id, {String? status, String? search});
  Future<Customer> customer(int id, int customerId);
  Future<Customer> saveCustomer(int id, Json data, {int? customerId});
  Future<void> deleteCustomer(int id, int customerId);
}
