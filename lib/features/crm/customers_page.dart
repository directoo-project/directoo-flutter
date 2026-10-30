import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/api_exception.dart';
import '../../core/format.dart';
import '../../core/labels.dart';
import '../../domain/repositories/customers_repository.dart';
import '../../domain/entities/models.dart';
import '../../presentation/session/session_bloc.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ui.dart';

class CustomersPage extends StatefulWidget {
  const CustomersPage({super.key});

  @override
  State<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends State<CustomersPage> {
  final _search = TextEditingController();
  List<Customer> _items = const [];
  var _status = 'all';
  var _loading = true;
  String? _error;
  int? _loadedFor;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final id = context.read<SessionBloc>().workspaceId;
    if (id != null && id != _loadedFor) {
      _loadedFor = id;
      _load();
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final id = _loadedFor;
    if (id == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await context.read<CustomersRepository>().customers(id, status: _status, search: _search.text.trim());
      if (mounted) setState(() => _items = items);
    } catch (error) {
      if (mounted) setState(() => _error = errorText(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canEdit = context.watch<SessionBloc>().permissions.canEditCustomers;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          title: 'مشتریان',
          description: 'پروفایل، وضعیت و پیگیری لیدها',
          action: canEdit
              ? IconButton(
                  onPressed: () async {
                    final saved = await showFormSheet<bool>(context, builder: (_) => const CustomerFormPage());
                    if (saved == true) _load();
                  },
                  icon: const Icon(Icons.add),
                )
              : null,
        ),
        TextField(
          controller: _search,
          decoration: InputDecoration(
            hintText: 'جستجو نام، موبایل یا اینستاگرام',
            suffixIcon: IconButton(onPressed: _load, icon: const Icon(Icons.search)),
          ),
          onSubmitted: (_) => _load(),
        ),
        const SizedBox(height: 12),
        FilterChips(options: customerStatusLabels, selected: _status, onSelected: (value) {
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
                      ? const EmptyView(title: 'مشتری‌ای پیدا نشد')
                      : ListView.separated(
                          itemCount: _items.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final customer = _items[index];
                            return SurfaceCard(
                              padding: EdgeInsets.zero,
                              child: ListTile(
                                title: Text(customer.name.isEmpty ? 'بدون نام' : customer.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                                subtitle: Text(customer.phone.isEmpty ? customer.instagramUsername : customer.phone),
                                trailing: StatusBadge(label: faLabel(customerStatusLabels, customer.status)),
                                onTap: () => context.push('/dashboard/customers/${customer.id}'),
                              ),
                            );
                          },
                        ),
        ),
      ],
    );
  }
}

class CustomerFormPage extends StatefulWidget {
  const CustomerFormPage({super.key, this.customerId});

  final int? customerId;

  @override
  State<CustomerFormPage> createState() => _CustomerFormPageState();
}

class _CustomerFormPageState extends State<CustomerFormPage> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _instagram = TextEditingController();
  final _notes = TextEditingController();
  final _tags = TextEditingController();
  var _status = 'warm';
  var _score = 50.0;
  var _loading = false;
  var _booting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.customerId != null) {
      _booting = true;
      _load();
    }
  }

  Future<void> _load() async {
    final workspaceId = context.read<SessionBloc>().workspaceId;
    if (workspaceId == null) return;
    try {
      final customer = await context.read<CustomersRepository>().customer(workspaceId, widget.customerId!);
      _name.text = customer.name;
      _phone.text = customer.phone;
      _email.text = customer.email;
      _instagram.text = customer.instagramUsername;
      _notes.text = customer.notes;
      _tags.text = customer.tags.join(', ');
      _status = customer.status.isEmpty ? 'warm' : customer.status;
      _score = customer.leadScore.toDouble();
    } catch (error) {
      _error = errorText(error);
    } finally {
      if (mounted) setState(() => _booting = false);
    }
  }

  @override
  void dispose() {
    for (final controller in [_name, _phone, _email, _instagram, _notes, _tags]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final workspaceId = context.read<SessionBloc>().workspaceId;
    if (workspaceId == null) return;
    if (_name.text.trim().isEmpty) {
      setState(() => _error = 'نام مشتری را وارد کنید.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await context.read<CustomersRepository>().saveCustomer(
        workspaceId,
        {
          'name': _name.text.trim(),
          'phone': _phone.text.trim(),
          'email': _email.text.trim(),
          'instagram_username': _instagram.text.trim(),
          'notes': _notes.text.trim(),
          'status': _status,
          'lead_score': _score.round(),
          'tags': _tags.text.split(',').map((item) => item.trim()).where((item) => item.isNotEmpty).toList(),
        },
        customerId: widget.customerId,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) setState(() => _error = errorText(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_booting) {
      return FormSheetScope.isSheet(context) ? const SizedBox(height: 160, child: LoadingView()) : const LoadingView();
    }
    return formBody(context, [
        PageHeader(title: widget.customerId == null ? 'مشتری جدید' : 'ویرایش مشتری'),
        TextField(controller: _name, decoration: const InputDecoration(labelText: 'نام')),
        const SizedBox(height: 12),
        TextField(controller: _phone, decoration: const InputDecoration(labelText: 'موبایل')),
        const SizedBox(height: 12),
        TextField(controller: _email, decoration: const InputDecoration(labelText: 'ایمیل')),
        const SizedBox(height: 12),
        TextField(controller: _instagram, decoration: const InputDecoration(labelText: 'اینستاگرام')),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _status,
          decoration: const InputDecoration(labelText: 'وضعیت'),
          items: [
            for (final entry in customerStatusLabels.entries)
              if (entry.key != 'all') DropdownMenuItem(value: entry.key, child: Text(entry.value)),
          ],
          onChanged: (value) => setState(() => _status = value ?? 'warm'),
        ),
        const SizedBox(height: 12),
        Text('امتیاز لید: ${faInt(_score)}'),
        Slider(value: _score, max: 100, divisions: 20, onChanged: (value) => setState(() => _score = value)),
        TextField(controller: _tags, decoration: const InputDecoration(labelText: 'برچسب‌ها، با ویرگول')),
        const SizedBox(height: 12),
        TextField(controller: _notes, minLines: 3, maxLines: 5, decoration: const InputDecoration(labelText: 'یادداشت')),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!, style: TextStyle(color: context.dt.error)),
        ],
        const SizedBox(height: 16),
        FilledButton(onPressed: _loading ? null : _save, child: Text(_loading ? 'در حال ذخیره...' : 'ذخیره')),
      ],
    );
  }
}

class CustomerDetailPage extends StatefulWidget {
  const CustomerDetailPage({super.key, required this.id});

  final int id;

  @override
  State<CustomerDetailPage> createState() => _CustomerDetailPageState();
}

class _CustomerDetailPageState extends State<CustomerDetailPage> {
  Customer? _customer;
  var _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final workspaceId = context.read<SessionBloc>().workspaceId;
    if (workspaceId == null) return;
    setState(() => _loading = true);
    try {
      final customer = await context.read<CustomersRepository>().customer(workspaceId, widget.id);
      if (mounted) setState(() => _customer = customer);
    } catch (error) {
      if (mounted) setState(() => _error = errorText(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _delete() async {
    final workspaceId = context.read<SessionBloc>().workspaceId;
    final api = context.read<CustomersRepository>();
    if (workspaceId == null) return;
    if (!await confirmDelete(context, 'حذف مشتری؟')) return;
    if (!mounted) return;
    await api.deleteCustomer(workspaceId, widget.id);
    if (!mounted) return;
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PageHeader(title: 'مشتری', description: 'جزئیات مشتری'),
          Expanded(child: LoadingView()),
        ],
      );
    }
    if (_error != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PageHeader(title: 'مشتری', description: 'جزئیات مشتری'),
          Expanded(child: ErrorView(message: _error!, onRetry: _load)),
        ],
      );
    }
    final customer = _customer!;
    final permissions = context.watch<SessionBloc>().permissions;
    return ListView(
      children: [
        PageHeader(
          title: customer.name.isEmpty ? 'مشتری' : customer.name,
          description: faLabel(customerStatusLabels, customer.status),
          action: permissions.canEditCustomers
              ? IconButton(
                  onPressed: () async {
                    final saved = await showFormSheet<bool>(context, builder: (_) => CustomerFormPage(customerId: customer.id));
                    if (saved == true && context.mounted) _load();
                  },
                  icon: const Icon(Icons.edit_outlined),
                )
              : null,
        ),
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('موبایل: ${customer.phone.isEmpty ? '—' : customer.phone}'),
              Text('ایمیل: ${customer.email.isEmpty ? '—' : customer.email}'),
              Text('اینستاگرام: ${customer.instagramUsername.isEmpty ? '—' : customer.instagramUsername}'),
              Text('امتیاز لید: ${faInt(customer.leadScore)}'),
              Text('فاکتورها: ${faInt(customer.invoiceCount)}'),
              Text('مانده پرداخت‌نشده: ${toman(customer.unpaidTotal)}'),
              if (customer.notes.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(customer.notes),
              ],
            ],
          ),
        ),
        if (permissions.canDeleteCustomers) ...[
          const SizedBox(height: 12),
          OutlinedButton(onPressed: _delete, child: const Text('حذف مشتری')),
        ],
      ],
    );
  }
}
