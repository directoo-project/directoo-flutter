import '../../core/json.dart';
import '../entities/models.dart';

abstract class InvoicesRepository {
  Future<List<SalesInvoice>> invoices(int id, {String? status, String? search});
  Future<SalesInvoiceSummary> invoiceSummary(int id);
  Future<SalesInvoice> invoice(int id, int invoiceId);
  Future<SalesInvoice> saveInvoice(int id, Json data, {int? invoiceId});
  Future<void> deleteInvoice(int id, int invoiceId);
  Future<SalesInvoice> issueInvoice(int id, int invoiceId);
  Future<SalesInvoice> payInvoice(int id, int invoiceId, String method);
  Future<SalesInvoice> cancelInvoice(int id, int invoiceId);
}
