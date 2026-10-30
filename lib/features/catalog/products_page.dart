import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/api_exception.dart';
import '../../core/format.dart';
import '../../core/labels.dart';
import '../../domain/repositories/knowledge_repository.dart';
import '../../domain/repositories/products_repository.dart';
import '../../domain/repositories/workspace_repository.dart';
import '../../domain/entities/models.dart';
import '../../presentation/session/session_bloc.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ui.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  final _search = TextEditingController();
  List<Product> _items = const [];
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
    setState(() => _loading = true);
    try {
      final items = await context.read<ProductsRepository>().products(id, search: _search.text.trim());
      if (mounted) {
        setState(() {
          _items = items;
          _error = null;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = errorText(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _edit([Product? product]) async {
    final name = TextEditingController(text: product?.name ?? '');
    final description = TextEditingController(text: product?.description ?? '');
    final price = TextEditingController(text: product == null ? '' : product.price.round().toString());
    final discount = TextEditingController(text: product == null ? '0' : product.discount.round().toString());
    final sku = TextEditingController(text: product?.sku ?? '');
    final inventory = TextEditingController(text: product == null ? '0' : '${product.inventory}');
    final url = TextEditingController(text: product?.productUrl ?? '');
    var status = product?.status.isNotEmpty == true ? product!.status : 'active';
    final saved = await showFormSheet<bool>(
      context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PageHeader(title: product == null ? 'محصول جدید' : 'ویرایش محصول'),
            TextField(controller: name, decoration: const InputDecoration(labelText: 'نام')),
            const SizedBox(height: 12),
            TextField(controller: description, decoration: const InputDecoration(labelText: 'توضیح')),
            const SizedBox(height: 12),
            TextField(controller: price, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'قیمت')),
            const SizedBox(height: 12),
            TextField(controller: discount, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'درصد تخفیف')),
            const SizedBox(height: 12),
            TextField(controller: sku, decoration: const InputDecoration(labelText: 'کد کالا')),
            const SizedBox(height: 12),
            TextField(controller: inventory, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'موجودی')),
            const SizedBox(height: 12),
            TextField(controller: url, decoration: const InputDecoration(labelText: 'لینک محصول')),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: status,
              decoration: const InputDecoration(labelText: 'وضعیت'),
              items: [for (final entry in productStatusLabels.entries) DropdownMenuItem(value: entry.key, child: Text(entry.value))],
              onChanged: (value) => setLocal(() => status = value ?? 'active'),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('ذخیره')),
          ],
        ),
      ),
    );
    if (saved != true || !mounted) return;
    final id = context.read<SessionBloc>().workspaceId;
    if (id == null || name.text.trim().isEmpty) return;
    try {
      await context.read<ProductsRepository>().saveProduct(id, {
        'name': name.text.trim(),
        'description': description.text.trim(),
        'price': int.tryParse(price.text) ?? 0,
        'discount': int.tryParse(discount.text) ?? 0,
        'sku': sku.text.trim(),
        'inventory': int.tryParse(inventory.text) ?? 0,
        'product_url': url.text.trim(),
        'status': status,
      }, productId: product?.id);
      await _load();
    } catch (error) {
      if (mounted) setState(() => _error = errorText(error));
    }
  }

  Future<void> _delete(Product product) async {
    final id = context.read<SessionBloc>().workspaceId;
    final api = context.read<ProductsRepository>();
    if (id == null || !await confirmDelete(context, 'حذف محصول؟')) return;
    if (!mounted) return;
    await api.deleteProduct(id, product.id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final canEdit = context.watch<SessionBloc>().permissions.canManageProducts;
    return Column(
      children: [
        PageHeader(
          title: 'محصولات',
          description: 'کاتالوگ، قیمت و موجودی',
          action: canEdit ? IconButton(onPressed: () => _edit(), icon: const Icon(Icons.add)) : null,
        ),
        TextField(
          controller: _search,
          decoration: InputDecoration(hintText: 'جستجو', suffixIcon: IconButton(onPressed: _load, icon: const Icon(Icons.search))),
          onSubmitted: (_) => _load(),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _loading
              ? const LoadingView()
              : _error != null
                  ? ErrorView(message: _error!, onRetry: _load)
                  : _items.isEmpty
                      ? const EmptyView(title: 'محصولی ثبت نشده')
                      : ListView.separated(
                          itemCount: _items.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final product = _items[index];
                            final price = product.finalPrice > 0 ? product.finalPrice : product.price;
                            return SurfaceCard(
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(product.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                                        Text(toman(price), style: TextStyle(color: context.dt.textMuted)),
                                        StatusBadge(label: faLabel(productStatusLabels, product.status)),
                                      ],
                                    ),
                                  ),
                                  if (canEdit) ...[
                                    IconButton(onPressed: () => _edit(product), icon: const Icon(Icons.edit_outlined)),
                                    IconButton(onPressed: () => _delete(product), icon: const Icon(Icons.delete_outline)),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
        ),
      ],
    );
  }
}

class StorefrontPage extends StatefulWidget {
  const StorefrontPage({super.key});

  @override
  State<StorefrontPage> createState() => _StorefrontPageState();
}

class _StorefrontPageState extends State<StorefrontPage> {
  final _name = TextEditingController();
  final _about = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _hours = TextEditingController();
  String _industry = '';
  var _loading = true;
  var _saving = false;
  String? _message;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final controller in [_name, _about, _phone, _address, _hours]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final id = context.read<SessionBloc>().workspaceId;
    if (id == null) return;
    try {
      final info = await context.read<KnowledgeRepository>().business(id);
      _name.text = info.businessName;
      _industry = info.industry;
      _about.text = info.about;
      _phone.text = info.phone;
      _address.text = info.address;
      _hours.text = info.workingHours;
    } catch (error) {
      _error = errorText(error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggle(bool value) async {
    final session = context.read<SessionBloc>();
    final workspace = session.workspace;
    if (workspace == null) return;
    if (value && !workspace.features.enabled('storefront_enabled')) {
      setState(() => _error = 'فروشگاه‌ساز در اشتراک فعلی فعال نیست.');
      return;
    }
    try {
      await context.read<WorkspaceRepository>().updateWorkspace(workspace.id, {'storefront_active': value});
      await session.reloadWorkspaces();
      if (mounted) setState(() => _message = value ? 'فروشگاه عمومی فعال شد.' : 'فروشگاه عمومی غیرفعال شد.');
    } catch (error) {
      if (mounted) setState(() => _error = errorText(error));
    }
  }

  Future<void> _save() async {
    final id = context.read<SessionBloc>().workspaceId;
    if (id == null) return;
    setState(() => _saving = true);
    try {
      await context.read<KnowledgeRepository>().updateBusiness(id, {
        'business_name': _name.text.trim(),
        'industry': _industry,
        'about': _about.text.trim(),
        'phone': _phone.text.trim(),
        'address': _address.text.trim(),
        'working_hours': _hours.text.trim(),
      });
      if (mounted) setState(() => _message = 'اطلاعات فروشگاه ذخیره شد.');
    } catch (error) {
      if (mounted) setState(() => _error = errorText(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PageHeader(title: 'فروشگاه‌ساز', description: 'صفحه عمومی فروشگاه با محصولات و اطلاعات کسب‌وکار'),
          Expanded(child: LoadingView()),
        ],
      );
    }
    final workspace = context.watch<SessionBloc>().workspace;
    final active = workspace?.storefrontActive ?? false;
    return ListView(
      children: [
        const PageHeader(title: 'فروشگاه‌ساز', description: 'صفحه عمومی فروشگاه با محصولات و اطلاعات کسب‌وکار'),
        if (_message != null) NoticeBanner(message: _message!),
        if (_error != null) NoticeBanner(message: _error!, error: true),
        SurfaceCard(
          child: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('فروشگاه عمومی'),
            subtitle: Text(workspace == null ? '' : 'directoo.ir/s/${workspace.slug}', textDirection: TextDirection.ltr),
            value: active,
            onChanged: _toggle,
          ),
        ),
        const SizedBox(height: 12),
        TextField(controller: _name, decoration: const InputDecoration(labelText: 'نام کسب‌وکار')),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _industry.isEmpty ? null : _industry,
          decoration: const InputDecoration(labelText: 'حوزه'),
          items: [for (final entry in industryLabels.entries) DropdownMenuItem(value: entry.key, child: Text(entry.value))],
          onChanged: (value) => setState(() => _industry = value ?? ''),
        ),
        const SizedBox(height: 12),
        TextField(controller: _about, minLines: 3, maxLines: 5, decoration: const InputDecoration(labelText: 'درباره')),
        const SizedBox(height: 12),
        TextField(controller: _phone, decoration: const InputDecoration(labelText: 'تلفن')),
        const SizedBox(height: 12),
        TextField(controller: _address, decoration: const InputDecoration(labelText: 'آدرس')),
        const SizedBox(height: 12),
        TextField(controller: _hours, decoration: const InputDecoration(labelText: 'ساعات کاری')),
        const SizedBox(height: 16),
        FilledButton(onPressed: _saving ? null : _save, child: Text(_saving ? 'در حال ذخیره...' : 'ذخیره فروشگاه')),
      ],
    );
  }
}
