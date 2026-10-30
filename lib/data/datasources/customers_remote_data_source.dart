import '../../core/api_client.dart';
import '../../core/json.dart';
import '../../domain/entities/models.dart';
import 'api_paths.dart';

abstract class CustomersRemoteDataSource {
  Future<List<Customer>> customers(int id, {String? status, String? search});
  Future<Customer> customer(int id, int customerId);
  Future<Customer> saveCustomer(int id, Json data, {int? customerId});
  Future<void> deleteCustomer(int id, int customerId);
}

class CustomersRemoteDataSourceImpl implements CustomersRemoteDataSource {
  CustomersRemoteDataSourceImpl(this._client);

  final ApiClient _client;

  @override
  Future<List<Customer>> customers(int id, {String? status, String? search}) {
      final query = <String, String>{
        if (status != null && status.isNotEmpty && status != 'all') 'status': status,
        if (search != null && search.isNotEmpty) 'search': search,
      };
      return _client.get(
        Uri(path: workspacePath(id, 'customers/'), queryParameters: query).toString(),
        auth: true,
        parse: (data) => [for (final item in asJsonList(data)) Customer.fromJson(item)],
      );
    }

  @override
  Future<Customer> customer(int id, int customerId) {
      return _client.get(workspacePath(id, 'customers/$customerId/'), auth: true, parse: (data) => Customer.fromJson(asJson(data)));
    }

  @override
  Future<Customer> saveCustomer(int id, Json data, {int? customerId}) {
      final path = customerId == null ? workspacePath(id, 'customers/') : workspacePath(id, 'customers/$customerId/');
      if (customerId == null) {
        return _client.post(path, auth: true, data: data, parse: (body) => Customer.fromJson(asJson(body)));
      }
      return _client.patch(path, auth: true, data: data, parse: (body) => Customer.fromJson(asJson(body)));
    }

  @override
  Future<void> deleteCustomer(int id, int customerId) => _client.delete(workspacePath(id, 'customers/$customerId/'), auth: true);
}
