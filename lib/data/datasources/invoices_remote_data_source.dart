import '../../core/api_client.dart';
import '../../core/json.dart';
import '../../domain/entities/models.dart';
import 'api_paths.dart';

abstract class InvoicesRemoteDataSource {
  Future<List<SalesInvoice>> invoices(int id, {String? status, String? search});
  Future<SalesInvoiceSummary> invoiceSummary(int id);
  Future<SalesInvoice> invoice(int id, int invoiceId);
  Future<SalesInvoice> saveInvoice(int id, Json data, {int? invoiceId});
  Future<void> deleteInvoice(int id, int invoiceId);
  Future<SalesInvoice> issueInvoice(int id, int invoiceId);
  Future<SalesInvoice> payInvoice(int id, int invoiceId, String method);
  Future<SalesInvoice> cancelInvoice(int id, int invoiceId);
}

class InvoicesRemoteDataSourceImpl implements InvoicesRemoteDataSource {
  InvoicesRemoteDataSourceImpl(this._client);

  final ApiClient _client;

  @override
  Future<List<SalesInvoice>> invoices(int id, {String? status, String? search}) {
      final query = <String, String>{
        if (status != null && status.isNotEmpty && status != 'all') 'status': status,
        if (search != null && search.isNotEmpty) 'search': search,
      };
      return _client.get(
        Uri(path: workspacePath(id, 'invoices/'), queryParameters: query).toString(),
        auth: true,
        parse: (data) => [for (final item in asJsonList(data)) SalesInvoice.fromJson(item)],
      );
    }

  @override
  Future<SalesInvoiceSummary> invoiceSummary(int id) {
      return _client.get(workspacePath(id, 'invoices/summary/'), auth: true, parse: (data) => SalesInvoiceSummary.fromJson(asJson(data)));
    }

  @override
  Future<SalesInvoice> invoice(int id, int invoiceId) {
      return _client.get(workspacePath(id, 'invoices/$invoiceId/'), auth: true, parse: (data) => SalesInvoice.fromJson(asJson(data)));
    }

  @override
  Future<SalesInvoice> saveInvoice(int id, Json data, {int? invoiceId}) {
      final path = invoiceId == null ? workspacePath(id, 'invoices/') : workspacePath(id, 'invoices/$invoiceId/');
      if (invoiceId == null) {
        return _client.post(path, auth: true, data: data, parse: (body) => SalesInvoice.fromJson(asJson(body)));
      }
      return _client.patch(path, auth: true, data: data, parse: (body) => SalesInvoice.fromJson(asJson(body)));
    }

  @override
  Future<void> deleteInvoice(int id, int invoiceId) => _client.delete(workspacePath(id, 'invoices/$invoiceId/'), auth: true);

  @override
  Future<SalesInvoice> issueInvoice(int id, int invoiceId) {
      return _client.post(workspacePath(id, 'invoices/$invoiceId/issue/'), auth: true, parse: (data) => SalesInvoice.fromJson(asJson(data)));
    }

  @override
  Future<SalesInvoice> payInvoice(int id, int invoiceId, String method) {
      return _client.post(
        workspacePath(id, 'invoices/$invoiceId/pay/'),
        auth: true,
        data: {'payment_method': method},
        parse: (data) => SalesInvoice.fromJson(asJson(data)),
      );
    }

  @override
  Future<SalesInvoice> cancelInvoice(int id, int invoiceId) {
      return _client.post(workspacePath(id, 'invoices/$invoiceId/cancel/'), auth: true, parse: (data) => SalesInvoice.fromJson(asJson(data)));
    }
}
