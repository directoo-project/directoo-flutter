import '../../core/json.dart';
import '../../domain/entities/models.dart';
import '../../domain/repositories/invoices_repository.dart';
import '../datasources/invoices_remote_data_source.dart';

class InvoicesRepositoryImpl implements InvoicesRepository {
  InvoicesRepositoryImpl(this._remote);

  final InvoicesRemoteDataSource _remote;

  @override
  Future<List<SalesInvoice>> invoices(int id, {String? status, String? search}) => _remote.invoices(id, status: status, search: search);

  @override
  Future<SalesInvoiceSummary> invoiceSummary(int id) => _remote.invoiceSummary(id);

  @override
  Future<SalesInvoice> invoice(int id, int invoiceId) => _remote.invoice(id, invoiceId);

  @override
  Future<SalesInvoice> saveInvoice(int id, Json data, {int? invoiceId}) => _remote.saveInvoice(id, data, invoiceId: invoiceId);

  @override
  Future<void> deleteInvoice(int id, int invoiceId) => _remote.deleteInvoice(id, invoiceId);

  @override
  Future<SalesInvoice> issueInvoice(int id, int invoiceId) => _remote.issueInvoice(id, invoiceId);

  @override
  Future<SalesInvoice> payInvoice(int id, int invoiceId, String method) => _remote.payInvoice(id, invoiceId, method);

  @override
  Future<SalesInvoice> cancelInvoice(int id, int invoiceId) => _remote.cancelInvoice(id, invoiceId);
}
