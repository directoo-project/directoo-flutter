import '../../core/json.dart';
import '../../domain/entities/models.dart';
import '../../domain/repositories/customers_repository.dart';
import '../datasources/customers_remote_data_source.dart';

class CustomersRepositoryImpl implements CustomersRepository {
  CustomersRepositoryImpl(this._remote);

  final CustomersRemoteDataSource _remote;

  @override
  Future<List<Customer>> customers(int id, {String? status, String? search}) => _remote.customers(id, status: status, search: search);

  @override
  Future<Customer> customer(int id, int customerId) => _remote.customer(id, customerId);

  @override
  Future<Customer> saveCustomer(int id, Json data, {int? customerId}) => _remote.saveCustomer(id, data, customerId: customerId);

  @override
  Future<void> deleteCustomer(int id, int customerId) => _remote.deleteCustomer(id, customerId);
}
