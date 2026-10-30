import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/api_exception.dart';
import '../../core/format.dart';
import '../../core/labels.dart';
import '../../data/directoo_api.dart';
import '../../models/models.dart';
import '../../state/session.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ui.dart';

class InvoicesPage extends StatefulWidget {
  const InvoicesPage({super.key});

  @override
  State<InvoicesPage> createState() => _InvoicesPageState();
}

class _InvoicesPageState extends State<InvoicesPage> {
  List<SalesInvoice> _items = const [];
  SalesInvoiceSummary? _summary;
  var _status = 'all';
  var _loading = true;
  String? _error;
  int? _loadedFor;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final id = context.read<SessionController>().workspaceId;
    if (id != null && id != _loadedFor) {
      _loadedFor = id;
      _load();
    }
  }

  Future<void> _load() async {
    final id = _loadedFor;
    if (id == null) return;
    setState(() => _loading = true);
    try {
      final api = context.read<DirectooApi>();
      final results = await Future.wait([
        api.invoices(id, status: _status),
        api.invoiceSummary(id),
      ]);
      if (!mounted) return;
      setState(() {
        _items = results[0] as List<SalesInvoice>;
        _summary = results[1] as SalesInvoiceSummary;
        _error = null;
      });
    } catch (error) {
      if (mounted) setState(() => _error = errorText(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canEdit = context.watch<SessionController>().permissions.canEditInvoices;
    final summary = _summary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          title: 'فاکتورها',
          description: 'صدور، پیگیری و تسویه فاکتور فروش',
          action: canEdit
              ? IconButton(
                  onPressed: () async {
                    final saved = await showFormSheet<bool>(context, builder: (_) => const InvoiceFormPage());
                    if (saved == true) _load();
                  },
                  icon: const Icon(Icons.add),
                )
              : null,
        ),
        if (summary != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text('پرداخت‌شده ${toman(summary.paidTotal)} · مانده ${toman(summary.unpaidTotal)}', style: TextStyle(color: context.dt.textMuted)),
          ),
        FilterChips(options: invoiceStatusLabels, selected: _status, onSelected: (value) {
          setState(() => _status = value);
          _load();
        }),
        const SizedBox(height: 12),
        Expanded(
          child: _loading
              ? const LoadingView()
              : _error != null
                  ? ErrorView(message: _error!, onRetry: _load)
                  : _items.isEmpty
                      ? const EmptyView(title: 'فاکتوری نیست')
                      : ListView.separated(
                          itemCount: _items.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final invoice = _items[index];
                            return SurfaceCard(
                              padding: EdgeInsets.zero,
                              child: ListTile(
                                title: Text(invoice.number.isEmpty ? 'فاکتور ${faInt(invoice.id)}' : invoice.number, style: const TextStyle(fontWeight: FontWeight.w800)),
                                subtitle: Text(invoice.customerName),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(toman(invoice.total), style: const TextStyle(fontWeight: FontWeight.w800)),
                                    StatusBadge(label: faLabel(invoiceStatusLabels, invoice.status)),
                                  ],
                                ),
                                onTap: () => context.push('/dashboard/invoices/${invoice.id}'),
                              ),
                            );
                          },
                        ),
        ),
      ],
    );
  }
}

class InvoiceFormPage extends StatefulWidget {
  const InvoiceFormPage({super.key});

  @override
  State<InvoiceFormPage> createState() => _InvoiceFormPageState();
}

class _InvoiceFormPageState extends State<InvoiceFormPage> {
  List<Customer> _customers = const [];
  List<Product> _products = const [];
  int? _customerId;
  final _description = TextEditingController();
  final _qty = TextEditingController(text: '1');
  final _price = TextEditingController();
  int? _productId;
  var _loading = true;
  var _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _description.dispose();
    _qty.dispose();
    _price.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final id = context.read<SessionController>().workspaceId;
    if (id == null) return;
    try {
      final api = context.read<DirectooApi>();
      final customers = await api.customers(id);
      final products = await api.products(id);
      if (!mounted) return;
      setState(() {
        _customers = customers;
        _products = products;
        _customerId = customers.isEmpty ? null : customers.first.id;
        _loading = false;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = errorText(error);
          _loading = false;
        });
      }
    }
  }

  Future<void> _save() async {
    final id = context.read<SessionController>().workspaceId;
    if (id == null || _customerId == null) return;
    final qty = int.tryParse(_qty.text) ?? 0;
    if (qty < 1 || _description.text.trim().isEmpty && _productId == null) {
      setState(() => _error = 'مشتری و حداقل یک قلم را وارد کنید.');
      return;
    }
    setState(() => _saving = true);
    try {
      await context.read<DirectooApi>().saveInvoice(id, {
        'customer': _customerId,
        'items': [
          {
            'product': _productId,
            'description': _description.text.trim(),
            'quantity': qty,
            if (_price.text.trim().isNotEmpty) 'unit_price': int.tryParse(_price.text.trim()),
          },
        ],
      });
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) setState(() => _error = errorText(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return FormSheetScope.isSheet(context) ? const SizedBox(height: 160, child: LoadingView()) : const LoadingView();
    }
    return formBody(context, [
        const PageHeader(title: 'فاکتور جدید', description: 'یک قلم کالا را برای مشتری ثبت کنید'),
        DropdownButtonFormField<int>(
          initialValue: _customerId,
          decoration: const InputDecoration(labelText: 'مشتری'),
          items: [for (final customer in _customers) DropdownMenuItem(value: customer.id, child: Text(customer.name))],
          onChanged: (value) => setState(() => _customerId = value),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<int>(
          initialValue: _productId,
          decoration: const InputDecoration(labelText: 'محصول (اختیاری)'),
          items: [for (final product in _products) DropdownMenuItem(value: product.id, child: Text(product.name))],
          onChanged: (value) {
            final product = _products.where((item) => item.id == value).firstOrNull;
            setState(() {
              _productId = value;
              if (product != null) {
                _description.text = product.name;
                _price.text = product.finalPrice.round().toString();
              }
            });
          },
        ),
        const SizedBox(height: 12),
        TextField(controller: _description, decoration: const InputDecoration(labelText: 'شرح')),
        const SizedBox(height: 12),
        TextField(controller: _qty, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'تعداد')),
        const SizedBox(height: 12),
        TextField(controller: _price, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'قیمت واحد (تومان)')),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!, style: TextStyle(color: context.dt.error)),
        ],
        const SizedBox(height: 16),
        FilledButton(onPressed: _saving ? null : _save, child: Text(_saving ? 'در حال ذخیره...' : 'ثبت پیش‌نویس')),
      ],
    );
  }
}

class InvoiceDetailPage extends StatefulWidget {
  const InvoiceDetailPage({super.key, required this.id});

  final int id;

  @override
  State<InvoiceDetailPage> createState() => _InvoiceDetailPageState();
}

class _InvoiceDetailPageState extends State<InvoiceDetailPage> {
  SalesInvoice? _invoice;
  var _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final workspaceId = context.read<SessionController>().workspaceId;
    if (workspaceId == null) return;
    setState(() => _loading = true);
    try {
      final invoice = await context.read<DirectooApi>().invoice(workspaceId, widget.id);
      if (mounted) setState(() => _invoice = invoice);
    } catch (error) {
      if (mounted) setState(() => _error = errorText(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _act(Future<SalesInvoice> Function(DirectooApi api, int workspaceId) action) async {
    final workspaceId = context.read<SessionController>().workspaceId;
    if (workspaceId == null) return;
    try {
      final invoice = await action(context.read<DirectooApi>(), workspaceId);
      if (mounted) setState(() => _invoice = invoice);
    } catch (error) {
      if (mounted) setState(() => _error = errorText(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingView();
    if (_error != null && _invoice == null) return ErrorView(message: _error!, onRetry: _load);
    final invoice = _invoice!;
    final canEdit = context.watch<SessionController>().permissions.canEditInvoices;
    return ListView(
      children: [
        PageHeader(title: invoice.number.isEmpty ? 'فاکتور' : invoice.number, description: invoice.customerName),
        StatusBadge(label: faLabel(invoiceStatusLabels, invoice.status)),
        const SizedBox(height: 12),
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final line in invoice.items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(child: Text(line.productName.isEmpty ? line.description : line.productName)),
                      Text('${faInt(line.quantity)} × ${toman(line.unitPrice)}'),
                    ],
                  ),
                ),
              const Divider(),
              Text('جمع: ${toman(invoice.subtotal)}'),
              Text('تخفیف: ${toman(invoice.discountAmount)}'),
              Text('مالیات: ${toman(invoice.taxAmount)}'),
              Text('قابل پرداخت: ${toman(invoice.total)}', style: const TextStyle(fontWeight: FontWeight.w800)),
            ],
          ),
        ),
        if (_error != null) Text(_error!, style: TextStyle(color: context.dt.error)),
        if (canEdit && invoice.status == 'draft') ...[
          const SizedBox(height: 12),
          FilledButton(onPressed: () => _act((api, id) => api.issueInvoice(id, invoice.id)), child: const Text('صدور فاکتور')),
        ],
        if (canEdit && invoice.status == 'issued') ...[
          const SizedBox(height: 12),
          FilledButton(onPressed: () => _act((api, id) => api.payInvoice(id, invoice.id, 'cash')), child: const Text('ثبت پرداخت نقدی')),
          const SizedBox(height: 8),
          OutlinedButton(onPressed: () => _act((api, id) => api.cancelInvoice(id, invoice.id)), child: const Text('لغو فاکتور')),
        ],
      ],
    );
  }
}
