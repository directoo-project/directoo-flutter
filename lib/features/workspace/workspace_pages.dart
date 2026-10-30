import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api_exception.dart';
import '../../core/format.dart';
import '../../core/labels.dart';
import '../../core/permissions.dart';
import '../../data/directoo_api.dart';
import '../../models/models.dart';
import '../../state/session.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ui.dart';
import '../home/home_page.dart';

class AnalyticsPage extends StatelessWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(title: 'گزارش‌ها', description: 'آمار ۱۴ روز گذشته فضای کاری'),
        Expanded(child: HomePage()),
      ],
    );
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
    final id = context.read<SessionController>().workspaceId;
    if (id == null) return;
    final api = context.read<DirectooApi>();
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
    final id = context.read<SessionController>().workspaceId;
    final api = context.read<DirectooApi>();
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
    final id = context.read<SessionController>().workspaceId;
    if (id == null) return;
    final created = await context.read<DirectooApi>().saveFaq(id, question: question.text.trim(), answer: answer.text.trim());
    setState(() => _faqs = [..._faqs, created]);
  }

  Future<void> _deleteFaq(Faq faq) async {
    final id = context.read<SessionController>().workspaceId;
    if (id == null) return;
    await context.read<DirectooApi>().deleteFaq(id, faq.id);
    setState(() => _faqs = _faqs.where((item) => item.id != faq.id).toList());
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingView();
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
    final id = context.read<SessionController>().workspaceId;
    if (id == null) return;
    setState(() => _loading = true);
    try {
      final items = await context.read<DirectooApi>().members(id);
      if (mounted) setState(() => _items = items);
    } catch (error) {
      if (mounted) setState(() => _error = errorText(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _invite() async {
    final phone = TextEditingController();
    final roles = assignableRoles(context.read<SessionController>().workspace?.role);
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
    final id = context.read<SessionController>().workspaceId;
    if (id == null) return;
    try {
      await context.read<DirectooApi>().addMember(id, normalizePhone(phone.text), role);
      await _load();
    } catch (error) {
      if (mounted) setState(() => _error = errorText(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final canInvite = context.watch<SessionController>().permissions.canManageTeam;
    if (_loading) return const LoadingView();
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
    final id = context.read<SessionController>().workspaceId;
    if (id == null) return;
    setState(() => _loading = true);
    try {
      final api = context.read<DirectooApi>();
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
    final id = context.read<SessionController>().workspaceId;
    final payload = _payload();
    if (id == null || payload == null) {
      setState(() => _error = 'یک بسته یا مبلغ سفارشی انتخاب کنید.');
      return;
    }
    setState(() => _submitting = true);
    try {
      final url = await context.read<DirectooApi>().topUp(id, packageId: payload.packageId, amount: payload.amount);
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (error) {
      if (mounted) setState(() => _error = errorText(error));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _card() async {
    final id = context.read<SessionController>().workspaceId;
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
      final message = await context.read<DirectooApi>().topUpCard(
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
    if (_loading) return const LoadingView();
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
    final id = context.read<SessionController>().workspaceId;
    if (id == null) return;
    setState(() => _loading = true);
    try {
      final api = context.read<DirectooApi>();
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
      });
    } catch (error) {
      if (mounted) setState(() => _error = errorText(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _upgrade(Plan plan, String method) async {
    final session = context.read<SessionController>();
    final api = context.read<DirectooApi>();
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

  Future<void> _card(Plan plan) async {
    final id = context.read<SessionController>().workspaceId;
    if (id == null) return;
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file == null || !mounted) return;
    setState(() => _busy = plan.id);
    try {
      final message = await context.read<DirectooApi>().upgradeCardToCard(
            id,
            planId: plan.id,
            interval: _interval,
            receiptPath: file.path,
            filename: file.name,
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
    final price = plan.finalPrice(_interval);
    final free = price <= 0 || plan.tier == 'free';
    await showFormSheet<void>(
      context,
      builder: (sheetContext) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PageHeader(
            title: free ? 'انتخاب ${plan.name}' : 'ارتقا به ${plan.name}',
            description: free ? 'این طرح بدون پرداخت فعال می‌شود.' : toman(price),
          ),
          TextField(controller: _discount, decoration: const InputDecoration(labelText: 'کد تخفیف')),
          const SizedBox(height: 8),
          TextField(controller: _referral, decoration: const InputDecoration(labelText: 'کد معرف')),
          if (_wallet != null) ...[
            const SizedBox(height: 12),
            Text('موجودی کیف پول: ${toman(_wallet!.balance)}', style: TextStyle(color: sheetContext.dt.textMuted)),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () {
              Navigator.pop(sheetContext);
              _upgrade(plan, 'gateway');
            },
            child: Text(free ? 'انتخاب' : 'پرداخت آنلاین'),
          ),
          if (!free) ...[
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () {
                Navigator.pop(sheetContext);
                _upgrade(plan, 'wallet');
              },
              child: const Text('کسر از کیف پول'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () {
                Navigator.pop(sheetContext);
                _card(plan);
              },
              child: const Text('کارت به کارت'),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingView();
    final dt = context.dt;
    final current = _subscription;
    final canBill = context.watch<SessionController>().permissions.canManageBilling;
    final period = current == null ? null : _period(current);
    return ListView(
      children: [
        const PageHeader(title: 'اشتراک', description: 'طرح، مصرف و پرداخت از درگاه، کیف پول یا کارت به کارت'),
        if (_message != null) NoticeBanner(message: _message!),
        if (_error != null) NoticeBanner(message: _error!, error: true),
        if (current != null)
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(child: Text('طرح فعلی', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
                    if (current.billingInterval.isNotEmpty)
                      StatusBadge(label: current.billingInterval == 'yearly' ? 'پرداخت سالانه' : 'پرداخت ماهانه', color: dt.textMuted),
                    const SizedBox(width: 6),
                    StatusBadge(label: _subscriptionStatus(current.status), color: current.status == 'active' ? dt.success : dt.warning),
                  ],
                ),
                const SizedBox(height: 14),
                Text(current.plan.name, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, height: 1.2)),
                if (period != null) ...[
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(value: period.percent, minHeight: 8, backgroundColor: dt.surfaceMuted, color: dt.primary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'گذشته از دوره ${faInt(period.elapsed)} / ${faInt(period.total)} روز · باقی‌مانده ${faInt(period.remaining)} روز',
                    style: TextStyle(color: dt.textMuted, fontSize: 12, height: 1.6),
                  ),
                ],
                if (current.plan.maxConversations > 0) ...[
                  const SizedBox(height: 6),
                  Text(
                    'مصرف گفتگو ${faInt(current.usageConversations)} از ${faInt(current.plan.maxConversations)}',
                    style: TextStyle(color: dt.textMuted, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        const SizedBox(height: 20),
        Row(
          children: [
            const Expanded(child: Text('طرح‌ها', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
            _IntervalChip(label: 'ماهانه', selected: _interval == 'monthly', onTap: () => setState(() => _interval = 'monthly')),
            const SizedBox(width: 8),
            _IntervalChip(label: 'سالانه', selected: _interval == 'yearly', onTap: () => setState(() => _interval = 'yearly')),
          ],
        ),
        const SizedBox(height: 12),
        for (final plan in _plans) ...[
          _PlanCard(
            plan: plan,
            interval: _interval,
            current: current != null && current.plan.id == plan.id && current.status == 'active',
            busy: _busy == plan.id,
            enabled: canBill,
            onSelect: () => _openPayment(plan),
          ),
          const SizedBox(height: 12),
        ],
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton(onPressed: () => context.go('/dashboard/wallet'), child: const Text('شارژ کیف پول')),
        ),
        if (_payments.isNotEmpty) ...[
          const SizedBox(height: 8),
          const Text('تاریخچه پرداخت', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 10),
          for (final payment in _payments) ...[
            _PaymentRow(payment: payment),
            const SizedBox(height: 8),
          ],
        ],
      ],
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
    final session = context.read<SessionController>();
    final api = context.read<DirectooApi>();
    try {
      _user = await api.me();
      _first.text = _user?.firstName ?? '';
      _last.text = _user?.lastName ?? '';
      _email.text = _user?.email ?? '';
      _workspaceName.text = session.workspace?.name ?? '';
      _timezone.text = session.workspace?.timezone ?? '';
      final id = session.workspaceId;
      if (id != null) {
        try {
          _accounts = await api.instagramAccounts(id);
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
      _user = await context.read<DirectooApi>().updateProfile(firstName: _first.text.trim(), lastName: _last.text.trim(), email: _email.text.trim());
      if (mounted) setState(() => _message = 'پروفایل ذخیره شد.');
    } catch (error) {
      if (mounted) setState(() => _error = errorText(error));
    }
  }

  Future<void> _avatar() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file == null || !mounted) return;
    try {
      _user = await context.read<DirectooApi>().uploadAvatar(file.path, file.name);
      if (mounted) setState(() => _message = 'تصویر پروفایل ذخیره شد.');
    } catch (error) {
      if (mounted) setState(() => _error = errorText(error));
    }
  }

  Future<void> _saveWorkspace() async {
    final session = context.read<SessionController>();
    final workspace = session.workspace;
    if (workspace == null) return;
    try {
      await context.read<DirectooApi>().updateWorkspace(workspace.id, {
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
    final session = context.read<SessionController>();
    final api = context.read<DirectooApi>();
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
    final id = context.read<SessionController>().workspaceId;
    final api = context.read<DirectooApi>();
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
    if (_loading) return const LoadingView();
    final session = context.watch<SessionController>();
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

class _IntervalChip extends StatelessWidget {
  const _IntervalChip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dt = context.dt;
    return Material(
      color: selected ? dt.surface : dt.surfaceMuted,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
        side: BorderSide(color: selected ? dt.border : Colors.transparent),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(label, style: TextStyle(fontWeight: FontWeight.w700, color: selected ? dt.text : dt.textMuted)),
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
    final free = price <= 0 || plan.tier == 'free';
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(plan.name, style: TextStyle(color: dt.textMuted, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(free ? 'رایگان' : toman(price), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
          if (interval == 'yearly' && !free)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('پرداخت سالانه', style: TextStyle(color: dt.textMuted, fontSize: 12)),
            ),
          if (plan.features.isNotEmpty) ...[
            const SizedBox(height: 12),
            for (final feature in plan.features)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check, size: 16, color: dt.primary),
                    const SizedBox(width: 6),
                    Expanded(child: Text(feature, style: TextStyle(color: dt.textMuted, height: 1.5))),
                  ],
                ),
              ),
          ],
          const SizedBox(height: 12),
          if (current)
            const Align(alignment: AlignmentDirectional.centerStart, child: StatusBadge(label: 'فعال', color: Color(0xFF16A34A)))
          else if (enabled)
            FilledButton(onPressed: busy ? null : onSelect, child: Text(busy ? 'در حال پردازش...' : (free ? 'انتخاب' : 'پرداخت و ارتقا'))),
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
    final kind = payment.type == 'wallet_topup' ? 'شارژ کیف پول' : 'اشتراک';
    return SurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(payment.description.isEmpty ? kind : payment.description, style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text('$method · $kind', style: TextStyle(color: dt.textMuted, fontSize: 12)),
                Text(formatJalali(payment.createdAt), style: TextStyle(color: dt.textSubtle, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              StatusBadge(label: status.$1, color: status.$2),
              const SizedBox(height: 6),
              Text(toman(payment.amount), style: const TextStyle(fontWeight: FontWeight.w800)),
            ],
          ),
        ],
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
