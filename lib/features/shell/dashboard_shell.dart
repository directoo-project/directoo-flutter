import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api_exception.dart';
import '../../core/format.dart';
import '../../core/labels.dart';
import '../../data/directoo_api.dart';
import '../../models/models.dart';
import '../../state/session.dart';
import '../../theme/app_theme.dart';
import '../../widgets/brand.dart';

class NavItem {
  const NavItem({required this.path, required this.label, required this.icon, this.exact = false, this.feature});

  final String path;
  final String label;
  final IconData icon;
  final bool exact;
  final String? feature;
}

class NavSection {
  const NavSection({required this.id, this.label, required this.items});

  final String id;
  final String? label;
  final List<NavItem> items;
}

const navSections = [
  NavSection(id: 'overview', items: [
    NavItem(path: '/dashboard', label: 'داشبورد', icon: Icons.space_dashboard_outlined, exact: true),
  ]),
  NavSection(id: 'crm', label: 'مدیریت مشتریان', items: [
    NavItem(path: '/dashboard/customers', label: 'مشتریان', icon: Icons.people_outline, feature: 'customers_enabled'),
    NavItem(path: '/dashboard/invoices', label: 'فاکتورها', icon: Icons.receipt_long_outlined, feature: 'customers_enabled'),
    NavItem(path: '/dashboard/tickets', label: 'تیکت‌ها', icon: Icons.confirmation_number_outlined, feature: 'tickets_enabled'),
    NavItem(path: '/dashboard/products', label: 'محصولات', icon: Icons.inventory_2_outlined, feature: 'products_enabled'),
    NavItem(path: '/dashboard/storefront', label: 'فروشگاه‌ساز', icon: Icons.storefront_outlined),
  ]),
  NavSection(id: 'tools', label: 'ابزارها', items: [
    NavItem(path: '/dashboard/inbox', label: 'صندوق ورودی', icon: Icons.forum_outlined, feature: 'inbox_enabled'),
    NavItem(path: '/dashboard/comments', label: 'صندوق کامنت', icon: Icons.chat_bubble_outline, feature: 'inbox_enabled'),
    NavItem(path: '/dashboard/smart-answering', label: 'پاسخ هوشمند', icon: Icons.bolt_outlined, feature: 'smart_reply_enabled'),
    NavItem(path: '/dashboard/automation', label: 'کامنت هوشمند', icon: Icons.mode_comment_outlined, feature: 'automation_enabled'),
    NavItem(path: '/dashboard/vitrin', label: 'ویترین ساز', icon: Icons.view_carousel_outlined, feature: 'vitrin_enabled'),
    NavItem(path: '/dashboard/follow-up', label: 'پشتیبان هوشمند', icon: Icons.schedule_outlined, feature: 'followup_enabled'),
    NavItem(path: '/dashboard/ice-breakers', label: 'پیام خوش‌آمدگویی', icon: Icons.waving_hand_outlined, feature: 'icebreaker_enabled'),
  ]),
  NavSection(id: 'insights', label: 'گزارش', items: [
    NavItem(path: '/dashboard/analytics', label: 'گزارش‌ها', icon: Icons.insights_outlined, feature: 'analytics_enabled'),
  ]),
  NavSection(id: 'workspace', label: 'فضا و حساب', items: [
    NavItem(path: '/dashboard/knowledge', label: 'پایگاه دانش', icon: Icons.menu_book_outlined, feature: 'knowledge_enabled'),
    NavItem(path: '/dashboard/team', label: 'تیم', icon: Icons.groups_outlined, feature: 'team_enabled'),
    NavItem(path: '/dashboard/wallet', label: 'کیف پول', icon: Icons.account_balance_wallet_outlined),
    NavItem(path: '/dashboard/billing', label: 'اشتراک', icon: Icons.credit_card_outlined),
    NavItem(path: '/dashboard/settings', label: 'تنظیمات', icon: Icons.settings_outlined),
  ]),
];

const mobileNav = [
  NavItem(path: '/dashboard', label: 'داشبورد', icon: Icons.space_dashboard_outlined, exact: true),
  NavItem(path: '/dashboard/customers', label: 'مشتریان', icon: Icons.people_outline, feature: 'customers_enabled'),
  NavItem(path: '/dashboard/invoices', label: 'فاکتورها', icon: Icons.receipt_long_outlined, feature: 'customers_enabled'),
  NavItem(path: '/dashboard/inbox', label: 'صندوق', icon: Icons.forum_outlined, feature: 'inbox_enabled'),
];

const _featurePaths = {
  '/dashboard/inbox': 'inbox_enabled',
  '/dashboard/comments': 'inbox_enabled',
  '/dashboard/customers': 'customers_enabled',
  '/dashboard/invoices': 'customers_enabled',
  '/dashboard/tickets': 'tickets_enabled',
  '/dashboard/products': 'products_enabled',
  '/dashboard/knowledge': 'knowledge_enabled',
  '/dashboard/automation': 'automation_enabled',
  '/dashboard/smart-answering': 'smart_reply_enabled',
  '/dashboard/vitrin': 'vitrin_enabled',
  '/dashboard/follow-up': 'followup_enabled',
  '/dashboard/ice-breakers': 'icebreaker_enabled',
  '/dashboard/analytics': 'analytics_enabled',
  '/dashboard/team': 'team_enabled',
};

const _subscriptionExempt = ['/dashboard/billing', '/dashboard/wallet', '/dashboard/settings'];

bool _active(String location, NavItem item) {
  if (item.exact) return location == item.path;
  return location == item.path || location.startsWith('${item.path}/');
}

String? featureForPath(String location) {
  for (final entry in _featurePaths.entries) {
    if (location == entry.key || location.startsWith('${entry.key}/')) return entry.value;
  }
  return null;
}

bool subscriptionExempt(String location) {
  return _subscriptionExempt.any((prefix) => location == prefix || location.startsWith('$prefix/'));
}

String menuKey(String location) {
  if (location == '/dashboard') return 'dashboard';
  final rest = location.replaceFirst('/dashboard/', '').split('/').first;
  return rest.isEmpty ? 'dashboard' : rest;
}

class DashboardShell extends StatelessWidget {
  const DashboardShell({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 1080;
    return Scaffold(
      drawer: wide ? null : Drawer(child: SafeArea(child: _Sidebar(location: location, onNavigate: () => Navigator.pop(context)))),
      body: Row(
        children: [
          if (wide) SizedBox(width: 280, child: _Sidebar(location: location)),
          Expanded(
            child: Column(
              children: [
                _TopBar(wide: wide),
                Expanded(
                  child: ColoredBox(
                    color: context.dt.bgSubtle,
                    child: _ShellBody(location: location, child: child),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: wide ? null : _BottomNav(location: location),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.location, this.onNavigate});

  final String location;
  final VoidCallback? onNavigate;

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    final features = session.workspace?.features;
    final dt = context.dt;
    return Material(
      color: dt.surface,
      child: Column(
        children: [
          const SizedBox(
            height: 72,
            child: Center(child: BrandLogo(height: 32)),
          ),
          const Divider(height: 1),
          if (session.workspace != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: session.workspaces.length < 2
                    ? null
                    : () async {
                        final picked = await showModalBottomSheet<int>(
                          context: context,
                          useRootNavigator: true,
                          builder: (context) => SafeArea(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                for (final workspace in session.workspaces)
                                  ListTile(
                                    title: Text(workspace.name),
                                    trailing: workspace.id == session.workspaceId ? const Icon(Icons.check) : null,
                                    onTap: () => Navigator.pop(context, workspace.id),
                                  ),
                              ],
                            ),
                          ),
                        );
                        if (picked != null) await session.selectWorkspace(picked);
                      },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: dt.primary, borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      const Icon(Icons.apartment, color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('فضای کاری', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w700)),
                            Text(session.workspace!.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
              children: [
                for (final section in navSections) ...[
                  if (section.label != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 14, 12, 8),
                      child: Text(section.label!, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: dt.textMuted)),
                    ),
                  for (final item in section.items)
                    if (features?.enabled(item.feature) ?? true)
                      _NavTile(item: item, active: _active(location, item), onTap: () {
                        onNavigate?.call();
                        context.go(item.path);
                      }),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({required this.item, required this.active, required this.onTap});

  final NavItem item;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dt = context.dt;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: active ? dt.primary50 : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Row(
              children: [
                Icon(item.icon, size: 20, color: active ? dt.primary : dt.textSubtle),
                const SizedBox(width: 10),
                Expanded(child: Text(item.label, style: TextStyle(fontWeight: FontWeight.w700, color: active ? dt.text : dt.textMuted))),
                if (active) Container(width: 4, height: 22, decoration: BoxDecoration(color: dt.primary, borderRadius: BorderRadius.circular(99))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.wide});

  final bool wide;

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    final dt = context.dt;
    final workspace = session.workspace;
    return Material(
      color: dt.surface,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: dt.border))),
          child: Row(
            children: [
              if (!wide)
                IconButton(onPressed: () => Scaffold.of(context).openDrawer(), icon: const Icon(Icons.menu)),
              if (wide)
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('پنل مشتری', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: dt.textMuted)),
                    Row(
                      children: [
                        Text(workspace?.name ?? 'Directoo', style: const TextStyle(fontWeight: FontWeight.w800)),
                        if (workspace?.role != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: dt.primary50, borderRadius: BorderRadius.circular(99)),
                            child: Text(faLabel(roleLabels, workspace?.role), style: TextStyle(color: dt.primary, fontSize: 11, fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ],
                    ),
                  ],
                )
              else
                const BrandLogo(height: 28),
              const Spacer(),
              if (session.permissions.canReply || (workspace?.features.enabled('tickets_enabled') ?? true))
                IconButton(
                  tooltip: 'تیکت‌ها',
                  onPressed: () => context.go('/dashboard/tickets'),
                  icon: const Icon(Icons.confirmation_number_outlined),
                ),
              if (wide) const _WalletChip(),
              IconButton(
                tooltip: 'حالت تاریک',
                onPressed: session.toggleTheme,
                icon: Icon(session.dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
              ),
              if (wide)
                IconButton(tooltip: 'خروج', onPressed: session.logout, icon: const Icon(Icons.logout)),
            ],
          ),
        ),
      ),
    );
  }
}

class _WalletChip extends StatefulWidget {
  const _WalletChip();

  @override
  State<_WalletChip> createState() => _WalletChipState();
}

class _WalletChipState extends State<_WalletChip> {
  double? _balance;
  int? _loadedFor;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final id = context.read<SessionController>().workspaceId;
    if (id != null && id != _loadedFor) {
      _loadedFor = id;
      context.read<DirectooApi>().wallet(id).then((wallet) {
        if (mounted) setState(() => _balance = wallet.balance);
      }).catchError((_) {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () => context.go('/dashboard/wallet'),
      icon: const Icon(Icons.account_balance_wallet_outlined, size: 18),
      label: Text(_balance == null ? 'کیف پول' : toman(_balance!)),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.location});

  final String location;

  @override
  Widget build(BuildContext context) {
    final features = context.watch<SessionController>().workspace?.features;
    final items = mobileNav.where((item) => features?.enabled(item.feature) ?? true).toList();
    const fallback = [
      NavItem(path: '/dashboard/billing', label: 'اشتراک', icon: Icons.credit_card_outlined),
      NavItem(path: '/dashboard/settings', label: 'تنظیمات', icon: Icons.settings_outlined),
    ];
    for (final item in fallback) {
      if (items.length >= 2) break;
      if (items.every((existing) => existing.path != item.path)) items.add(item);
    }
    if (items.length < 2) return const SizedBox.shrink();
    var index = 0;
    for (var i = 0; i < items.length; i++) {
      if (_active(location, items[i])) index = i;
    }
    final dt = context.dt;
    return Material(
      color: dt.surface,
      child: DecoratedBox(
        decoration: BoxDecoration(border: Border(top: BorderSide(color: dt.border))),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Row(
              children: [
                for (var i = 0; i < items.length; i++)
                  Expanded(
                    child: InkWell(
                      onTap: () => context.go(items[i].path),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            index == i ? _filledIcon(items[i].icon) : items[i].icon,
                            size: 24,
                            color: index == i ? dt.primary : dt.textSubtle,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            items[i].label.split(' ').first,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: index == i ? dt.primary : dt.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

IconData _filledIcon(IconData icon) {
  return switch (icon) {
    Icons.space_dashboard_outlined => Icons.space_dashboard,
    Icons.people_outline => Icons.people,
    Icons.receipt_long_outlined => Icons.receipt_long,
    Icons.forum_outlined => Icons.forum,
    Icons.credit_card_outlined => Icons.credit_card,
    Icons.settings_outlined => Icons.settings,
    _ => icon,
  };
}

class _ShellBody extends StatelessWidget {
  const _ShellBody({required this.location, required this.child});

  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final workspace = context.watch<SessionController>().workspace;
    if (workspace == null) {
      return const Center(child: Text('فضای کاری پیدا نشد. از تنظیمات یکی بسازید.'));
    }
    if (workspace.needsSubscription && !subscriptionExempt(location)) {
      return const _NoSubscription();
    }
    final feature = featureForPath(location);
    if (feature != null && !workspace.features.enabled(feature)) {
      return const _FeatureDisabled();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (location == '/dashboard') const Padding(padding: EdgeInsets.fromLTRB(16, 16, 16, 0), child: _InstagramBanner()),
        const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: _TutorialBanner()),
        Expanded(child: Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), child: child)),
      ],
    );
  }
}

class _NoSubscription extends StatelessWidget {
  const _NoSubscription();

  @override
  Widget build(BuildContext context) {
    final workspace = context.watch<SessionController>().workspace;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('برای استفاده از پنل، اشتراک «${workspace?.name ?? ''}» را فعال کنید.', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text('بعد از پرداخت، ابزارهای پنل برای همین فضای کاری باز می‌شود.', style: TextStyle(color: context.dt.textMuted, height: 1.7)),
        const SizedBox(height: 16),
        FilledButton(onPressed: () => context.go('/dashboard/billing'), child: const Text('مشاهده اشتراک‌ها')),
      ],
    );
  }
}

class _FeatureDisabled extends StatelessWidget {
  const _FeatureDisabled();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('این بخش در طرح فعلی فعال نیست.', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text('با ارتقای اشتراک به این ابزار دسترسی پیدا می‌کنید.', style: TextStyle(color: context.dt.textMuted)),
        const SizedBox(height: 16),
        FilledButton(onPressed: () => context.go('/dashboard/billing'), child: const Text('ارتقای اشتراک')),
      ],
    );
  }
}

class _InstagramBanner extends StatefulWidget {
  const _InstagramBanner();

  @override
  State<_InstagramBanner> createState() => _InstagramBannerState();
}

class _InstagramBannerState extends State<_InstagramBanner> {
  int? _loadedFor;
  var _missing = false;
  InstagramAccessRequest? _request;
  var _connecting = false;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final id = context.read<SessionController>().workspaceId;
    final location = GoRouterState.of(context).uri.path;
    if (id == null || location.startsWith('/dashboard/settings') || id == _loadedFor) return;
    _loadedFor = id;
    final api = context.read<DirectooApi>();
    Future.wait([api.instagramAccounts(id), api.accessRequest(id).then<Object?>((value) => value)]).then((results) {
      if (!mounted) return;
      final accounts = results[0] as List<InstagramAccount>;
      setState(() {
        _request = results[1] as InstagramAccessRequest?;
        _missing = !accounts.any((account) => account.status == 'connected');
      });
    }).catchError((_) {});
  }

  Future<void> _connect() async {
    final session = context.read<SessionController>();
    final id = session.workspaceId;
    if (id == null) return;
    if (_request?.status != 'approved') {
      await session.prefs.setBool('instagram_pending', true);
      session.instagramReviewing = _request?.reviewing ?? false;
      session.gate = AuthGate.instagram;
      session.publish();
      return;
    }
    setState(() => _connecting = true);
    try {
      final url = await context.read<DirectooApi>().startInstagramOAuth(id);
      if (url.isNotEmpty) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      }
    } catch (error) {
      if (mounted) setState(() => _error = errorText(error));
    } finally {
      if (mounted) setState(() => _connecting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_missing) return const SizedBox.shrink();
    final canConnect = context.watch<SessionController>().permissions.canManageInstagram;
    final dt = context.dt;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: dt.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: dt.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: dt.primary50, borderRadius: BorderRadius.circular(12)),
                child: Icon(Icons.camera_alt_outlined, color: dt.coral, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(child: Text('اینستاگرام متصل نیست', style: TextStyle(fontWeight: FontWeight.w800))),
            ],
          ),
          const SizedBox(height: 8),
          Text('برای دریافت دایرکت و پاسخ هوشمند، حساب را وصل کنید.', style: TextStyle(color: dt.textMuted, height: 1.6)),
          const SizedBox(height: 12),
          if (canConnect)
            FilledButton(onPressed: _connecting ? null : _connect, child: Text(_connecting ? 'در حال اتصال...' : 'اتصال به اینستاگرام'))
          else
            Text('برای اتصال، از مدیر فضا بخواهید اینستاگرام را وصل کند.', style: TextStyle(color: dt.textMuted)),
          if (_error != null) Text(_error!, style: TextStyle(color: dt.error)),
        ],
      ),
    );
  }
}

class _TutorialBanner extends StatefulWidget {
  const _TutorialBanner();

  @override
  State<_TutorialBanner> createState() => _TutorialBannerState();
}

class _TutorialBannerState extends State<_TutorialBanner> {
  List<MenuTutorial>? _items;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_items != null) return;
    context.read<DirectooApi>().tutorials().then((items) {
      if (mounted) setState(() => _items = items);
    }).catchError((_) {
      if (mounted) setState(() => _items = const []);
    });
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final key = menuKey(location);
    MenuTutorial? tutorial;
    for (final item in _items ?? const <MenuTutorial>[]) {
      if (item.key == key && item.isActive && item.linkUrl.isNotEmpty) tutorial = item;
    }
    if (tutorial == null) return const SizedBox.shrink();
    final link = tutorial.linkUrl;
    final dt = context.dt;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: dt.primary50, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tutorial.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                if (tutorial.description.isNotEmpty) Text(tutorial.description, style: TextStyle(color: dt.textMuted)),
              ],
            ),
          ),
          TextButton(onPressed: () => launchUrl(Uri.parse(link), mode: LaunchMode.externalApplication), child: Text(tutorial.linkLabel.isEmpty ? 'آموزش' : tutorial.linkLabel)),
        ],
      ),
    );
  }
}
