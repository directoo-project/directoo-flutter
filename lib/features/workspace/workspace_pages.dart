import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api_exception.dart';
import '../../core/format.dart';
import '../../core/labels.dart';
import '../../core/permissions.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/billing_repository.dart';
import '../../domain/repositories/instagram_repository.dart';
import '../../domain/repositories/knowledge_repository.dart';
import '../../domain/repositories/workspace_repository.dart';
import '../../domain/entities/models.dart';
import '../../presentation/session/session_bloc.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ui.dart';
import '../home/home_page.dart';
import '../shell/dashboard_shell.dart';

class AnalyticsPage extends StatelessWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const HomePage(mode: HomeMode.analytics);
  }
}

class KnowledgePage extends StatefulWidget {
  const KnowledgePage({super.key});

  @override
  State<KnowledgePage> createState() => _KnowledgePageState();
}

class _KnowledgePageState extends State<KnowledgePage> {
  final _name = TextEditingController();
  final _about = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _hours = TextEditingController();
  final _allowed = TextEditingController();
  final _forbidden = TextEditingController();
  String _industry = '';
  List<Faq> _faqs = const [];
  var _loading = true;
  String? _message;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final controller in [_name, _about, _phone, _address, _hours, _allowed, _forbidden]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final id = context.read<SessionBloc>().workspaceId;
    if (id == null) return;
    final api = context.read<KnowledgeRepository>();
    try {
      final business = await api.business(id);
      final rules = await api.rules(id);
      final faqs = await api.faqs(id);
      _name.text = business.businessName;
      _industry = business.industry;
      _about.text = business.about;
      _phone.text = business.phone;
      _address.text = business.address;
      _hours.text = business.workingHours;
      _allowed.text = rules.allowedTopics;
      _forbidden.text = rules.forbiddenTopics;
      _faqs = faqs;
    } catch (error) {
      _error = errorText(error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveBusiness() async {
    final id = context.read<SessionBloc>().workspaceId;
    final api = context.read<KnowledgeRepository>();
    if (id == null) return;
    try {
      await api.updateBusiness(id, {
        'business_name': _name.text.trim(),
        'industry': _industry,
        'about': _about.text.trim(),
        'phone': _phone.text.trim(),
        'address': _address.text.trim(),
        'working_hours': _hours.text.trim(),
      });
      await api.updateRules(id, {
        'allowed_topics': _allowed.text.trim(),
        'forbidden_topics': _forbidden.text.trim(),
      });
      if (mounted) setState(() => _message = 'پایگاه دانش ذخیره شد.');
    } catch (error) {
      if (mounted) setState(() => _error = errorText(error));
    }
  }

  Future<void> _addFaq() async {
    final question = TextEditingController();
    final answer = TextEditingController();
    final ok = await showFormSheet<bool>(
      context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PageHeader(title: 'سؤال متداول', description: 'سؤال و پاسخ را برای پایگاه دانش بنویسید'),
          TextField(controller: question, decoration: const InputDecoration(labelText: 'سؤال')),
          const SizedBox(height: 12),
          TextField(controller: answer, minLines: 3, maxLines: 5, decoration: const InputDecoration(labelText: 'پاسخ')),
          const SizedBox(height: 16),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('افزودن')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final id = context.read<SessionBloc>().workspaceId;
    if (id == null) return;
    final created = await context.read<KnowledgeRepository>().saveFaq(id, question: question.text.trim(), answer: answer.text.trim());
    setState(() => _faqs = [..._faqs, created]);
  }

  Future<void> _deleteFaq(Faq faq) async {
    final id = context.read<SessionBloc>().workspaceId;
    if (id == null) return;
    await context.read<KnowledgeRepository>().deleteFaq(id, faq.id);
    setState(() => _faqs = _faqs.where((item) => item.id != faq.id).toList());
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PageHeader(title: 'پایگاه دانش', description: 'اطلاعات کسب‌وکار، قوانین پاسخ و سؤالات متداول'),
          Expanded(child: LoadingView()),
        ],
      );
    }
    return ListView(
      children: [
        const PageHeader(title: 'پایگاه دانش', description: 'اطلاعات کسب‌وکار، قوانین پاسخ و سؤالات متداول'),
        if (_message != null) NoticeBanner(message: _message!),
        if (_error != null) NoticeBanner(message: _error!, error: true),
        const SectionTitle(title: 'کسب‌وکار'),
        TextField(controller: _name, decoration: const InputDecoration(labelText: 'نام')),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _industry.isEmpty ? null : _industry,
          decoration: const InputDecoration(labelText: 'حوزه'),
          items: [for (final entry in industryLabels.entries) DropdownMenuItem(value: entry.key, child: Text(entry.value))],
          onChanged: (value) => setState(() => _industry = value ?? ''),
        ),
        const SizedBox(height: 12),
        TextField(controller: _about, minLines: 2, maxLines: 4, decoration: const InputDecoration(labelText: 'درباره')),
        const SizedBox(height: 12),
        TextField(controller: _phone, decoration: const InputDecoration(labelText: 'تلفن')),
        const SizedBox(height: 12),
        TextField(controller: _address, decoration: const InputDecoration(labelText: 'آدرس')),
        const SizedBox(height: 12),
        TextField(controller: _hours, decoration: const InputDecoration(labelText: 'ساعات')),
        const SizedBox(height: 16),
        const SectionTitle(title: 'قوانین هوشمند'),
        TextField(controller: _allowed, minLines: 2, maxLines: 4, decoration: const InputDecoration(labelText: 'موضوعات مجاز')),
        const SizedBox(height: 12),
        TextField(controller: _forbidden, minLines: 2, maxLines: 4, decoration: const InputDecoration(labelText: 'موضوعات ممنوع')),
        const SizedBox(height: 16),
        FilledButton(onPressed: _saveBusiness, child: const Text('ذخیره')),
        const SizedBox(height: 20),
        Row(
          children: [
            const Expanded(child: SectionTitle(title: 'سؤالات متداول')),
            IconButton(onPressed: _addFaq, icon: const Icon(Icons.add)),
          ],
        ),
        for (final faq in _faqs)
          SurfaceCard(
            child: Row(
              children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(faq.question, style: const TextStyle(fontWeight: FontWeight.w800)), Text(faq.answer)])),
                IconButton(onPressed: () => _deleteFaq(faq), icon: const Icon(Icons.delete_outline)),
              ],
            ),
          ),
      ],
    );
  }
}

class TeamPage extends StatefulWidget {
  const TeamPage({super.key});

  @override
  State<TeamPage> createState() => _TeamPageState();
}

class _TeamPageState extends State<TeamPage> {
  List<WorkspaceMember> _items = const [];
  var _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final id = context.read<SessionBloc>().workspaceId;
    if (id == null) return;
    setState(() => _loading = true);
    try {
      final items = await context.read<WorkspaceRepository>().members(id);
      if (mounted) setState(() => _items = items);
    } catch (error) {
      if (mounted) setState(() => _error = errorText(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _invite() async {
    final phone = TextEditingController();
    final roles = assignableRoles(context.read<SessionBloc>().workspace?.role);
    if (roles.isEmpty) return;
    var role = roles.first;
    final ok = await showFormSheet<bool>(
      context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const PageHeader(title: 'دعوت عضو', description: 'شماره موبایل و نقش را وارد کنید'),
            TextField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'شماره موبایل')),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: role,
              decoration: const InputDecoration(labelText: 'نقش'),
              items: [for (final item in roles) DropdownMenuItem(value: item, child: Text(faLabel(roleLabels, item)))],
              onChanged: (value) => setLocal(() => role = value ?? role),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('دعوت')),
          ],
        ),
      ),
    );
    if (ok != true || !mounted) return;
    final id = context.read<SessionBloc>().workspaceId;
    if (id == null) return;
    try {
      await context.read<WorkspaceRepository>().addMember(id, normalizePhone(phone.text), role);
      await _load();
    } catch (error) {
      if (mounted) setState(() => _error = errorText(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final canInvite = context.watch<SessionBloc>().permissions.canManageTeam;
    if (_loading) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PageHeader(title: 'تیم', description: 'اعضا و نقش‌های فضای کاری'),
          Expanded(child: LoadingView()),
        ],
      );
    }
    return Column(
      children: [
        PageHeader(title: 'تیم', description: 'اعضا و نقش‌های فضای کاری', action: canInvite ? IconButton(onPressed: _invite, icon: const Icon(Icons.person_add_alt)) : null),
        if (_error != null) NoticeBanner(message: _error!, error: true),
        Expanded(
          child: _items.isEmpty
              ? const EmptyView(title: 'عضوی نیست')
              : ListView.separated(
                  itemCount: _items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final member = _items[index];
                    return SurfaceCard(
                      child: Row(
                        children: [
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(member.userName.isEmpty ? member.userPhone : member.userName, style: const TextStyle(fontWeight: FontWeight.w800)), Text(member.userPhone)])),
                          StatusBadge(label: faLabel(roleLabels, member.role)),
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

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  WalletInfo? _wallet;
  List<WalletPackage> _packages = const [];
  List<WalletTx> _transactions = const [];
  String? _selected;
  final _amount = TextEditingController();
  var _filter = 'all';
  var _loading = true;
  var _submitting = false;
  String? _message;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final id = context.read<SessionBloc>().workspaceId;
    if (id == null) return;
    setState(() => _loading = true);
    try {
      final api = context.read<BillingRepository>();
      final wallet = await api.wallet(id);
      final packages = await api.walletPackages(id);
      final transactions = await api.walletTransactions(id);
      if (!mounted) return;
      setState(() {
        _wallet = wallet;
        _packages = packages;
        _transactions = transactions;
        _error = null;
      });
    } catch (error) {
      if (mounted) setState(() => _error = errorText(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  ({String? packageId, int? amount})? _payload() {
    final custom = int.tryParse(_amount.text.replaceAll(',', ''));
    if (custom != null && custom > 0) return (packageId: null, amount: custom);
    if (_selected != null) return (packageId: _selected, amount: null);
    return null;
  }

  Future<void> _topUp() async {
    final id = context.read<SessionBloc>().workspaceId;
    final payload = _payload();
    if (id == null || payload == null) {
      setState(() => _error = 'یک بسته یا مبلغ سفارشی انتخاب کنید.');
      return;
    }
    setState(() => _submitting = true);
    try {
      final url = await context.read<BillingRepository>().topUp(id, packageId: payload.packageId, amount: payload.amount);
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (error) {
      if (mounted) setState(() => _error = errorText(error));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _card() async {
    final id = context.read<SessionBloc>().workspaceId;
    final payload = _payload();
    if (id == null || payload == null) return;
    if (payload.amount != null && (payload.amount! < 10000 || payload.amount! > 50000000)) {
      setState(() => _error = 'مبلغ باید بین ۱۰٬۰۰۰ تا ۵۰٬۰۰۰٬۰۰۰ تومان باشد.');
      return;
    }
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file == null || !mounted) return;
    setState(() => _submitting = true);
    try {
      final message = await context.read<BillingRepository>().topUpCard(
            id,
            packageId: payload.packageId,
            amount: payload.amount,
            receiptPath: file.path,
            filename: file.name,
          );
      if (mounted) setState(() => _message = message);
      await _load();
    } catch (error) {
      if (mounted) setState(() => _error = errorText(error));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PageHeader(title: 'کیف پول', description: 'موجودی، شارژ و تاریخچه تراکنش‌ها'),
          Expanded(child: LoadingView()),
        ],
      );
    }
    final tx = _transactions.where((item) => _filter == 'all' || item.type == _filter).toList();
    return ListView(
      children: [
        const PageHeader(title: 'کیف پول', description: 'موجودی، شارژ و تاریخچه تراکنش‌ها'),
        if (_message != null) NoticeBanner(message: _message!),
        if (_error != null) NoticeBanner(message: _error!, error: true),
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('موجودی فعلی', style: TextStyle(color: context.dt.textMuted)),
              Text(toman(_wallet?.balance ?? 0), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
              Text('آخرین به‌روزرسانی: ${formatJalali(_wallet?.updatedAt)}', style: TextStyle(color: context.dt.textSubtle, fontSize: 12)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final pack in _packages)
              ChoiceChip(
                label: Text(pack.label.isEmpty ? toman(pack.amount) : pack.label),
                selected: _selected == pack.id && _amount.text.isEmpty,
                onSelected: (_) => setState(() {
                  _selected = pack.id;
                  _amount.clear();
                }),
              ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(controller: _amount, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'مبلغ سفارشی (تومان)'), onChanged: (_) => setState(() => _selected = null)),
        const SizedBox(height: 12),
        FilledButton(onPressed: _submitting ? null : _topUp, child: Text(_submitting ? 'در حال اتصال...' : 'پرداخت آنلاین')),
        const SizedBox(height: 8),
        OutlinedButton(onPressed: _submitting ? null : _card, child: const Text('کارت به کارت و ارسال فیش')),
        const SizedBox(height: 16),
        FilterChips(
          options: const {'all': 'همه', 'deposit': 'شارژ', 'usage': 'مصرف', 'bonus': 'بونوس', 'refund': 'بازگشت'},
          selected: _filter,
          onSelected: (value) => setState(() => _filter = value),
        ),
        const SizedBox(height: 12),
        for (final item in tx)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: SurfaceCard(
              child: Row(
                children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(item.description.isEmpty ? faLabel(walletTxTypeLabels, item.type) : item.description, style: const TextStyle(fontWeight: FontWeight.w700)), Text(formatJalali(item.createdAt), style: TextStyle(color: context.dt.textSubtle, fontSize: 12))])),
                  Text(toman(item.amount), style: const TextStyle(fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class BillingPage extends StatefulWidget {
  const BillingPage({super.key});

  @override
  State<BillingPage> createState() => _BillingPageState();
}

class _BillingPageState extends State<BillingPage> {
  List<Plan> _plans = const [];
  List<PaymentRecord> _payments = const [];
  Subscription? _subscription;
  WalletInfo? _wallet;
  var _interval = 'monthly';
  var _pickedInterval = false;
  final _discount = TextEditingController();
  final _referral = TextEditingController();
  var _loading = true;
  int? _busy;
  String? _message;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _discount.dispose();
    _referral.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final id = context.read<SessionBloc>().workspaceId;
    if (id == null) return;
    setState(() => _loading = true);
    try {
      final api = context.read<BillingRepository>();
      final plans = await api.plans();
      final subscription = await api.subscription(id);
      final wallet = await api.wallet(id);
      List<PaymentRecord> payments = const [];
      try {
        payments = await api.payments(id);
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _plans = plans;
        _subscription = subscription;
        _wallet = wallet;
        _payments = payments;
        _error = null;
        if (!_pickedInterval && subscription != null) {
          _interval = subscription.billingInterval == 'yearly' ? 'yearly' : 'monthly';
        }
      });
    } catch (error) {
      if (mounted) setState(() => _error = errorText(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _upgrade(Plan plan, String method) async {
    final session = context.read<SessionBloc>();
    final api = context.read<BillingRepository>();
    final id = session.workspaceId;
    if (id == null) return;
    setState(() => _busy = plan.id);
    try {
      final url = await api.upgradePlan(
            id,
            planId: plan.id,
            interval: _interval,
            paymentMethod: method,
            discount: _discount.text.trim(),
            referral: _referral.text.trim(),
          );
      if (!mounted) return;
      if (url != null) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } else {
        setState(() => _message = 'اشتراک با موفقیت به‌روز شد.');
        await session.reloadWorkspaces();
        if (!mounted) return;
        await _load();
      }
    } catch (error) {
      if (mounted) setState(() => _error = errorText(error));
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  Future<void> _submitReceipt(Plan plan, String path, String filename) async {
    final id = context.read<SessionBloc>().workspaceId;
    if (id == null) return;
    setState(() => _busy = plan.id);
    try {
      final message = await context.read<BillingRepository>().upgradeCardToCard(
            id,
            planId: plan.id,
            interval: _interval,
            receiptPath: path,
            filename: filename,
            discount: _discount.text.trim(),
            referral: _referral.text.trim(),
          );
      if (mounted) setState(() => _message = message);
      await _load();
    } catch (error) {
      if (mounted) setState(() => _error = errorText(error));
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  Future<void> _openPayment(Plan plan) async {
    await showFormSheet<void>(
      context,
      builder: (sheetContext) => _UpgradeSheet(
        plan: plan,
        interval: _interval,
        discount: _discount,
        referral: _referral,
        walletBalance: _wallet?.balance,
        onGateway: () {
          Navigator.pop(sheetContext);
          _upgrade(plan, 'gateway');
        },
        onWallet: () {
          Navigator.pop(sheetContext);
          _upgrade(plan, 'wallet');
        },
        onReceipt: (path, filename) {
          Navigator.pop(sheetContext);
          _submitReceipt(plan, path, filename);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const header = PageHeader(title: 'اشتراک', description: 'طرح، مصرف و پرداخت از درگاه، کیف پول یا کارت به کارت');
    if (_loading && _plans.isEmpty && _subscription == null) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          Expanded(child: _BillingSkeleton()),
        ],
      );
    }
    if (_error != null && _plans.isEmpty && _subscription == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          Expanded(child: ErrorView(message: _error!, onRetry: _load)),
        ],
      );
    }
    final current = _subscription;
    final canBill = context.watch<SessionBloc>().permissions.canManageBilling;
    final plans = [for (final plan in _plans) if (plan.offersInterval(_interval)) plan];
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          header,
          if (_message != null) NoticeBanner(message: _message!),
          if (_error != null) NoticeBanner(message: _error!, error: true),
          _CurrentPlanCard(subscription: current, period: current == null ? null : _period(current), statusLabel: current == null ? '' : _subscriptionStatus(current.status)),
          if (_wallet != null) ...[
            const SizedBox(height: 12),
            _WalletStrip(balance: _wallet!.balance),
          ],
          const SizedBox(height: 22),
          Row(
            children: [
              const Expanded(child: Text('طرح‌ها', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18))),
              _IntervalToggle(
                interval: _interval,
                onChanged: (value) => setState(() {
                  _pickedInterval = true;
                  _interval = value;
                }),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (plans.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text('برای این بازه طرحی تعریف نشده.', textAlign: TextAlign.center),
            ),
          for (final plan in plans) ...[
            _PlanCard(
              plan: plan,
              interval: _interval,
              current: current != null && current.plan.id == plan.id && current.billingInterval == _interval && current.status == 'active',
              busy: _busy == plan.id,
              enabled: canBill,
              onSelect: () => _openPayment(plan),
            ),
            const SizedBox(height: 12),
          ],
          if (_payments.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Text('تاریخچه پرداخت', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            const SizedBox(height: 10),
            for (final payment in _payments) ...[
              _PaymentRow(payment: payment),
              const SizedBox(height: 8),
            ],
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  _Period? _period(Subscription subscription) {
    final start = DateTime.tryParse(subscription.periodStart ?? '');
    final end = DateTime.tryParse(subscription.periodEnd ?? '');
    if (start == null || end == null || !end.isAfter(start)) return null;
    final total = end.difference(start).inDays.clamp(1, 100000);
    final now = DateTime.now();
    final elapsed = now.difference(start).inDays.clamp(0, total);
    final remaining = end.difference(now).inDays.clamp(0, total);
    final percent = (now.difference(start).inSeconds / end.difference(start).inSeconds).clamp(0.0, 1.0);
    return _Period(total: total, elapsed: elapsed, remaining: remaining, percent: percent);
  }

  String _subscriptionStatus(String status) {
    return switch (status) {
      'active' => 'فعال',
      'past_due' => 'معوق',
      'expired' => 'منقضی',
      'cancelled' => 'لغو شده',
      'trialing' => 'آزمایشی',
      _ => status.isEmpty ? '—' : status,
    };
  }
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _email = TextEditingController();
  final _workspaceName = TextEditingController();
  final _timezone = TextEditingController();
  AuthUser? _user;
  List<InstagramAccount> _accounts = const [];
  var _loading = true;
  String? _message;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final controller in [_first, _last, _email, _workspaceName, _timezone]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final session = context.read<SessionBloc>();
    final auth = context.read<AuthRepository>();
    final instagram = context.read<InstagramRepository>();
    try {
      _user = await auth.me();
      _first.text = _user?.firstName ?? '';
      _last.text = _user?.lastName ?? '';
      _email.text = _user?.email ?? '';
      _workspaceName.text = session.workspace?.name ?? '';
      _timezone.text = session.workspace?.timezone ?? '';
      final id = session.workspaceId;
      if (id != null) {
        try {
          _accounts = await instagram.instagramAccounts(id);
        } catch (_) {}
      }
    } catch (error) {
      _error = errorText(error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveProfile() async {
    try {
      _user = await context.read<AuthRepository>().updateProfile(firstName: _first.text.trim(), lastName: _last.text.trim(), email: _email.text.trim());
      if (mounted) setState(() => _message = 'پروفایل ذخیره شد.');
    } catch (error) {
      if (mounted) setState(() => _error = errorText(error));
    }
  }

  Future<void> _avatar() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file == null || !mounted) return;
    try {
      _user = await context.read<AuthRepository>().uploadAvatar(file.path, file.name);
      if (mounted) setState(() => _message = 'تصویر پروفایل ذخیره شد.');
    } catch (error) {
      if (mounted) setState(() => _error = errorText(error));
    }
  }

  Future<void> _saveWorkspace() async {
    final session = context.read<SessionBloc>();
    final workspace = session.workspace;
    if (workspace == null) return;
    try {
      await context.read<WorkspaceRepository>().updateWorkspace(workspace.id, {
        'name': _workspaceName.text.trim(),
        'timezone': _timezone.text.trim(),
      });
      await session.reloadWorkspaces();
      if (mounted) setState(() => _message = 'فضای کاری ذخیره شد.');
    } catch (error) {
      if (mounted) setState(() => _error = errorText(error));
    }
  }

  Future<void> _createWorkspace() async {
    final name = TextEditingController();
    final ok = await showFormSheet<bool>(
      context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PageHeader(title: 'فضای کاری جدید', description: 'نام فضای کاری را وارد کنید'),
          TextField(controller: name, decoration: const InputDecoration(labelText: 'نام فضا')),
          const SizedBox(height: 16),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('ساخت')),
        ],
      ),
    );
    final title = name.text.trim();
    name.dispose();
    if (ok != true || !mounted || title.isEmpty) return;
    final session = context.read<SessionBloc>();
    final api = context.read<WorkspaceRepository>();
    try {
      final created = await api.createWorkspace(title);
      await session.reloadWorkspaces();
      await session.selectWorkspace(created.id);
      if (mounted) setState(() => _message = 'فضای کاری ساخته شد.');
    } catch (error) {
      if (mounted) setState(() => _error = errorText(error));
    }
  }

  Future<void> _disconnect(InstagramAccount account) async {
    final id = context.read<SessionBloc>().workspaceId;
    final api = context.read<InstagramRepository>();
    if (id == null || !await confirmDelete(context, 'قطع اتصال اینستاگرام؟')) return;
    if (!mounted) return;
    try {
      await api.deleteInstagramAccount(id, account.id);
      if (!mounted) return;
      setState(() {
        _accounts = _accounts.where((item) => item.id != account.id).toList();
        _message = 'اتصال اینستاگرام قطع شد.';
      });
    } catch (error) {
      if (mounted) setState(() => _error = errorText(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PageHeader(title: 'تنظیمات', description: 'حساب کاربری، فضای کاری و اینستاگرام'),
          Expanded(child: LoadingView()),
        ],
      );
    }
    final session = context.watch<SessionBloc>();
    final dt = context.dt;
    final user = _user;
    final connected = _accounts.where((account) => account.status == 'connected' || account.status.isEmpty).toList();
    return ListView(
      children: [
        PageHeader(
          title: 'تنظیمات',
          description: 'حساب کاربری، فضای کاری و اینستاگرام',
          action: OutlinedButton.icon(
            onPressed: session.logout,
            icon: const Icon(Icons.logout, size: 18),
            label: const Text('خروج'),
            style: OutlinedButton.styleFrom(minimumSize: const Size(0, 40), padding: const EdgeInsets.symmetric(horizontal: 12)),
          ),
        ),
        if (_message != null) NoticeBanner(message: _message!),
        if (_error != null) NoticeBanner(message: _error!, error: true),
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('حساب کاربری', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 16),
              Center(child: _ProfileAvatar(user: user)),
              const SizedBox(height: 10),
              Center(
                child: OutlinedButton.icon(
                  onPressed: _avatar,
                  icon: const Icon(Icons.photo_camera_outlined, size: 18),
                  label: const Text('تغییر تصویر'),
                  style: OutlinedButton.styleFrom(minimumSize: const Size(0, 40), padding: const EdgeInsets.symmetric(horizontal: 14)),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'این تصویر در صفحه عمومی فروشگاه نمایش داده می‌شود. حداکثر ۵ مگابایت.',
                textAlign: TextAlign.center,
                style: TextStyle(color: dt.textMuted, fontSize: 12, height: 1.6),
              ),
              if ((user?.phoneNumber ?? '').isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(user!.phoneNumber, textAlign: TextAlign.center, textDirection: TextDirection.ltr, style: TextStyle(color: dt.textSubtle, fontSize: 13)),
              ],
              const SizedBox(height: 16),
              TextField(controller: _first, decoration: const InputDecoration(labelText: 'نام')),
              const SizedBox(height: 10),
              TextField(controller: _last, decoration: const InputDecoration(labelText: 'نام خانوادگی')),
              const SizedBox(height: 10),
              TextField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'ایمیل')),
              const SizedBox(height: 16),
              FilledButton(onPressed: _saveProfile, child: const Text('ذخیره پروفایل')),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Expanded(child: Text('فضای کاری', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
                  if (session.workspace?.role != null) StatusBadge(label: faLabel(roleLabels, session.workspace?.role), color: dt.primary),
                ],
              ),
              const SizedBox(height: 14),
              if (session.workspaces.length > 1) ...[
                DropdownButtonFormField<int>(
                  initialValue: session.workspaceId,
                  decoration: const InputDecoration(labelText: 'فضای فعال'),
                  items: [for (final workspace in session.workspaces) DropdownMenuItem(value: workspace.id, child: Text(workspace.name))],
                  onChanged: (value) {
                    if (value != null) session.selectWorkspace(value);
                  },
                ),
                const SizedBox(height: 10),
              ],
              TextField(controller: _workspaceName, decoration: const InputDecoration(labelText: 'نام')),
              const SizedBox(height: 10),
              TextField(controller: _timezone, decoration: const InputDecoration(labelText: 'منطقه زمانی')),
              const SizedBox(height: 16),
              FilledButton(onPressed: session.permissions.canEditWorkspace ? _saveWorkspace : null, child: const Text('ذخیره فضای کاری')),
              const SizedBox(height: 10),
              OutlinedButton.icon(onPressed: _createWorkspace, icon: const Icon(Icons.add), label: const Text('ایجاد')),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('اینستاگرام', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 12),
              if (connected.isEmpty)
                FilledButton(onPressed: () => context.go('/setup/instagram'), child: const Text('اتصال اینستاگرام'))
              else
                for (final account in connected) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(color: dt.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: dt.success, size: 18),
                        const SizedBox(width: 8),
                        Expanded(child: Text('اکانت @${account.username} متصل شد.', style: TextStyle(color: dt.success, fontWeight: FontWeight.w700))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.camera_alt_outlined, color: dt.coral, size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text('@${account.username}', textDirection: TextDirection.ltr, style: const TextStyle(fontWeight: FontWeight.w800))),
                      if (session.permissions.canManageInstagram)
                        TextButton(
                          onPressed: () => _disconnect(account),
                          style: TextButton.styleFrom(foregroundColor: dt.error),
                          child: const Text('قطع اتصال'),
                        ),
                    ],
                  ),
                ],
            ],
          ),
        ),
      ],
    );
  }
}

class _Period {
  const _Period({required this.total, required this.elapsed, required this.remaining, required this.percent});
  final int total;
  final int elapsed;
  final int remaining;
  final double percent;
}

class _BillingSkeleton extends StatelessWidget {
  const _BillingSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      children: const [
        SkeletonBox(height: 176, radius: 22),
        SizedBox(height: 12),
        SkeletonBox(height: 72, radius: 18),
        SizedBox(height: 22),
        SkeletonBox(height: 36, width: 180, radius: 18),
        SizedBox(height: 12),
        SkeletonBox(height: 168, radius: 20),
        SizedBox(height: 12),
        SkeletonBox(height: 168, radius: 20),
        SizedBox(height: 12),
        SkeletonBox(height: 168, radius: 20),
      ],
    );
  }
}

class _CurrentPlanCard extends StatelessWidget {
  const _CurrentPlanCard({required this.subscription, required this.period, required this.statusLabel});

  final Subscription? subscription;
  final _Period? period;
  final String statusLabel;

  @override
  Widget build(BuildContext context) {
    final dt = context.dt;
    final current = subscription;
    final active = current?.status == 'active';
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: dt.primary.withValues(alpha: 0.28)),
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [dt.primary50, dt.surface],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: dt.surface, borderRadius: BorderRadius.circular(14)),
                child: Icon(Icons.credit_card_rounded, color: dt.primary, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text('طرح فعلی', style: TextStyle(color: dt.textMuted, fontWeight: FontWeight.w700))),
              if (current != null) StatusBadge(label: statusLabel, color: active ? dt.success : dt.warning),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            current?.plan.name ?? 'بدون اشتراک',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, height: 1.2, color: dt.text),
          ),
          const SizedBox(height: 8),
          if (current == null)
            Text('یکی از طرح‌ها را انتخاب کنید تا ابزارهای پنل باز شود.', style: TextStyle(color: dt.textMuted, height: 1.6))
          else
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: StatusBadge(
                label: current.billingInterval == 'yearly' ? 'پرداخت سالانه' : 'پرداخت ماهانه',
                color: dt.primary,
              ),
            ),
          if (period != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Text('باقی‌مانده', style: TextStyle(color: dt.textMuted, fontSize: 13)),
                const Spacer(),
                Text('${faInt(period!.remaining)} روز', style: const TextStyle(fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: period!.percent,
                minHeight: 8,
                backgroundColor: dt.surface,
                color: dt.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'گذشته از دوره ${faInt(period!.elapsed)} از ${faInt(period!.total)} روز',
              style: TextStyle(color: dt.textSubtle, fontSize: 12, height: 1.5),
            ),
          ],
          if (current != null && current.plan.maxConversations > 0) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Text('مصرف گفتگو', style: TextStyle(color: dt.textMuted, fontSize: 13)),
                const Spacer(),
                Text(
                  '${faInt(current.usageConversations)} از ${faInt(current.plan.maxConversations)}',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: (current.usageConversations / current.plan.maxConversations).clamp(0, 1).toDouble(),
                minHeight: 6,
                backgroundColor: dt.surface,
                color: dt.coral,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _WalletStrip extends StatelessWidget {
  const _WalletStrip({required this.balance});

  final double balance;

  @override
  Widget build(BuildContext context) {
    final dt = context.dt;
    return Material(
      color: dt.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: dt.border)),
      child: InkWell(
        onTap: () => openDashboardRoute(context, '/dashboard/wallet'),
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(color: dt.primary50, borderRadius: BorderRadius.circular(14)),
                child: Icon(Icons.account_balance_wallet_outlined, color: dt.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('کیف پول', style: TextStyle(color: dt.textMuted, fontSize: 12)),
                    const SizedBox(height: 2),
                    Text(toman(balance), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  ],
                ),
              ),
              Text('شارژ', style: TextStyle(color: dt.primary, fontWeight: FontWeight.w800)),
              Icon(Icons.chevron_left, color: dt.primary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _IntervalToggle extends StatelessWidget {
  const _IntervalToggle({required this.interval, required this.onChanged});

  final String interval;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final dt = context.dt;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: dt.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: dt.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _chip(context, 'ماهانه', interval == 'monthly', () => onChanged('monthly')),
          _chip(context, 'سالانه', interval == 'yearly', () => onChanged('yearly')),
        ],
      ),
    );
  }

  Widget _chip(BuildContext context, String label, bool selected, VoidCallback onTap) {
    final dt = context.dt;
    return Material(
      color: selected ? dt.primary : Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          child: Text(
            label,
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: selected ? dt.onPrimary : dt.textMuted),
          ),
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.interval,
    required this.current,
    required this.busy,
    required this.enabled,
    required this.onSelect,
  });

  final Plan plan;
  final String interval;
  final bool current;
  final bool busy;
  final bool enabled;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final dt = context.dt;
    final price = plan.finalPrice(interval);
    final list = plan.listPrice(interval);
    final discount = plan.discountPercent(interval);
    final free = price <= 0 || plan.tier == 'free';
    final days = plan.periodDays(interval);
    final bullets = plan.features.isNotEmpty
        ? plan.features
        : [
            if (plan.maxConversations > 0) 'تا ${faInt(plan.maxConversations)} گفتگو',
          ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: current ? dt.primary50 : dt.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: current ? dt.primary : dt.border, width: current ? 1.6 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(plan.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
              if (current) StatusBadge(label: 'فعال', color: dt.success),
            ],
          ),
          if (days > 0) ...[
            const SizedBox(height: 4),
            Text('مدت اشتراک: ${faInt(days)} روز', style: TextStyle(color: dt.textMuted, fontSize: 13)),
          ],
          const SizedBox(height: 12),
          if (!free && discount > 0 && list > price)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Text(
                    toman(list),
                    style: TextStyle(color: dt.textSubtle, decoration: TextDecoration.lineThrough, fontSize: 13),
                  ),
                  const SizedBox(width: 8),
                  StatusBadge(label: '${faInt(discount)}٪ تخفیف', color: dt.coral),
                ],
              ),
            ),
          Text(free ? 'رایگان' : toman(price), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, height: 1.2)),
          if (interval == 'yearly' && !free && days > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'معادل ${toman(price / (days / 30))} در ماه',
                style: TextStyle(color: dt.textMuted, fontSize: 12),
              ),
            ),
          if (bullets.isNotEmpty) ...[
            const SizedBox(height: 14),
            for (final feature in bullets.take(5))
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle_rounded, size: 18, color: current ? dt.primary : dt.success),
                    const SizedBox(width: 8),
                    Expanded(child: Text(feature, style: TextStyle(color: dt.text, height: 1.45))),
                  ],
                ),
              ),
          ],
          const SizedBox(height: 6),
          if (current)
            Container(
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: dt.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: dt.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: dt.success, shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Text('فعال', style: TextStyle(color: dt.success, fontWeight: FontWeight.w800)),
                ],
              ),
            )
          else if (enabled)
            FilledButton(
              onPressed: busy ? null : onSelect,
              child: Text(busy ? 'در حال پردازش...' : (free ? 'انتخاب' : 'پرداخت و ارتقا')),
            ),
        ],
      ),
    );
  }
}

class _PaymentRow extends StatelessWidget {
  const _PaymentRow({required this.payment});
  final PaymentRecord payment;

  @override
  Widget build(BuildContext context) {
    final dt = context.dt;
    final status = switch (payment.status) {
      'paid' => ('تایید شده', dt.success),
      'under_review' => ('در حال بررسی', dt.warning),
      'rejected' => ('رد شده', dt.error),
      'failed' => ('ناموفق', dt.error),
      'cancelled' => ('لغو شده', dt.textMuted),
      _ => ('در انتظار', dt.textMuted),
    };
    final method = switch (payment.method) {
      'card_to_card' => 'کارت به کارت',
      'wallet' => 'کیف پول',
      _ => 'درگاه',
    };
    final title = payment.type == 'wallet_topup'
        ? (payment.description.isEmpty ? 'شارژ کیف پول' : payment.description)
        : (payment.description.isEmpty ? '$method · اشتراک' : payment.description);
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w800))),
              const SizedBox(width: 8),
              StatusBadge(label: status.$1, color: status.$2),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _meta(context, 'مبلغ', toman(payment.amount))),
              Expanded(child: _meta(context, 'تاریخ', formatJalali(payment.createdAt, withTime: false))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _meta(BuildContext context, String label, String value) {
    final dt = context.dt;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: dt.textSubtle, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
      ],
    );
  }
}

class _UpgradeSheet extends StatefulWidget {
  const _UpgradeSheet({
    required this.plan,
    required this.interval,
    required this.discount,
    required this.referral,
    required this.walletBalance,
    required this.onGateway,
    required this.onWallet,
    required this.onReceipt,
  });

  final Plan plan;
  final String interval;
  final TextEditingController discount;
  final TextEditingController referral;
  final double? walletBalance;
  final VoidCallback onGateway;
  final VoidCallback onWallet;
  final void Function(String path, String filename) onReceipt;

  @override
  State<_UpgradeSheet> createState() => _UpgradeSheetState();
}

class _UpgradeSheetState extends State<_UpgradeSheet> {
  var _cardStep = false;
  var _loadingCard = false;
  CardInfo? _card;
  String? _cardError;
  var _copied = false;

  double get _price => widget.plan.finalPrice(widget.interval);
  bool get _free => _price <= 0 || widget.plan.tier == 'free';

  Future<void> _openCard() async {
    setState(() {
      _cardStep = true;
      _loadingCard = true;
      _cardError = null;
    });
    final id = context.read<SessionBloc>().workspaceId;
    if (id == null) {
      setState(() => _loadingCard = false);
      return;
    }
    try {
      final card = await context.read<BillingRepository>().cardInfo(id);
      if (mounted) setState(() => _card = card);
    } catch (error) {
      if (mounted) setState(() => _cardError = errorText(error));
    } finally {
      if (mounted) setState(() => _loadingCard = false);
    }
  }

  Future<void> _pickReceipt() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file == null) return;
    widget.onReceipt(file.path, file.name);
  }

  @override
  Widget build(BuildContext context) {
    final dt = context.dt;
    if (_cardStep) return _cardBody(dt);
    final balance = widget.walletBalance;
    final enough = balance != null && balance >= _price;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(_free ? 'انتخاب ${widget.plan.name}' : 'ارتقا به ${widget.plan.name}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Text(
          _free ? 'این طرح بدون پرداخت فعال می‌شود.' : toman(_price),
          style: TextStyle(color: _free ? dt.textMuted : dt.primary, fontWeight: FontWeight.w800, fontSize: _free ? 14 : 22),
        ),
        if (!_free) ...[
          const SizedBox(height: 16),
          TextField(controller: widget.discount, decoration: const InputDecoration(labelText: 'کد تخفیف')),
          const SizedBox(height: 8),
          TextField(controller: widget.referral, decoration: const InputDecoration(labelText: 'کد معرف')),
          const SizedBox(height: 16),
          _PayTile(
            icon: Icons.credit_score_rounded,
            title: 'پرداخت آنلاین',
            subtitle: 'انتقال به درگاه و فعال‌سازی فوری',
            onTap: widget.onGateway,
          ),
          const SizedBox(height: 8),
          _PayTile(
            icon: Icons.account_balance_wallet_outlined,
            title: 'کیف پول',
            subtitle: balance == null
                ? 'کسر از موجودی کیف پول'
                : enough
                    ? 'موجودی ${toman(balance)} — بلافاصله فعال می‌شود'
                    : 'موجودی ${toman(balance)} کافی نیست',
            enabled: balance == null || enough,
            onTap: widget.onWallet,
          ),
          const SizedBox(height: 8),
          _PayTile(
            icon: Icons.receipt_long_outlined,
            title: 'کارت به کارت',
            subtitle: 'واریز مبلغ و ارسال تصویر فیش',
            onTap: _openCard,
          ),
        ] else ...[
          const SizedBox(height: 16),
          FilledButton(onPressed: widget.onGateway, child: const Text('انتخاب')),
        ],
      ],
    );
  }

  Widget _cardBody(DtColors dt) {
    final card = _card;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              tooltip: 'بازگشت',
              visualDensity: VisualDensity.compact,
              onPressed: () => setState(() => _cardStep = false),
              icon: const Icon(Icons.arrow_forward, textDirection: TextDirection.ltr),
            ),
            const SizedBox(width: 4),
            const Expanded(child: Text('کارت به کارت', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
          ],
        ),
        Text('مبلغ دقیق ${toman(_price)} را واریز کنید، سپس تصویر فیش را بفرستید.', style: TextStyle(color: dt.textMuted, height: 1.6)),
        const SizedBox(height: 14),
        if (_loadingCard)
          const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Center(child: CircularProgressIndicator()))
        else if (_cardError != null)
          NoticeBanner(message: _cardError!, error: true)
        else if (card != null)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: dt.primary50, borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (card.bankName.isNotEmpty) Text(card.bankName, style: TextStyle(color: dt.textMuted, fontSize: 12)),
                const SizedBox(height: 6),
                Text(faDigits(card.number), textDirection: TextDirection.ltr, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: 1)),
                if (card.holderName.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(card.holderName, style: TextStyle(color: dt.textMuted)),
                ],
                const SizedBox(height: 8),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: card.number));
                      if (mounted) setState(() => _copied = true);
                    },
                    icon: Icon(_copied ? Icons.check_rounded : Icons.copy_rounded, size: 18),
                    label: Text(_copied ? 'کپی شد' : 'کپی شماره کارت'),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        FilledButton(onPressed: _pickReceipt, child: const Text('بارگذاری فیش')),
      ],
    );
  }
}

class _PayTile extends StatelessWidget {
  const _PayTile({required this.icon, required this.title, required this.subtitle, required this.onTap, this.enabled = true});

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final dt = context.dt;
    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: Material(
        color: dt.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: dt.border)),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(color: dt.primary50, borderRadius: BorderRadius.circular(14)),
                  child: Icon(icon, color: dt.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      Text(subtitle, style: TextStyle(color: dt.textMuted, fontSize: 12, height: 1.4)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_left, color: dt.textSubtle),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.user});
  final AuthUser? user;

  @override
  Widget build(BuildContext context) {
    final dt = context.dt;
    final name = user?.displayName ?? '';
    final letter = name.isEmpty ? 'ک' : name.substring(0, 1);
    final url = user?.avatarUrl ?? '';
    if (url.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          url,
          width: 72,
          height: 72,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _letter(dt, letter),
        ),
      );
    }
    return _letter(dt, letter);
  }

  Widget _letter(DtColors dt, String letter) {
    return CircleAvatar(
      radius: 36,
      backgroundColor: dt.primary50,
      child: Text(letter, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: dt.primary)),
    );
  }
}
