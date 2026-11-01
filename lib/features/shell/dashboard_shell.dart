import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api_exception.dart';
import '../../core/format.dart';
import '../../core/labels.dart';
import '../../domain/repositories/billing_repository.dart';
import '../../domain/repositories/instagram_repository.dart';
import '../../domain/repositories/tutorials_repository.dart';
import '../../domain/entities/models.dart';
import '../../presentation/session/session_bloc.dart';
import '../../theme/app_theme.dart';
import '../../widgets/brand.dart';

class NavItem {
  const NavItem({
    required this.path,
    required this.label,
    required this.icon,
    this.exact = false,
    this.feature,
  });

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
  NavSection(
    id: 'overview',
    items: [
      NavItem(
        path: '/dashboard',
        label: 'داشبورد',
        icon: Icons.space_dashboard_outlined,
        exact: true,
      ),
    ],
  ),
  NavSection(
    id: 'crm',
    label: 'مدیریت مشتریان',
    items: [
      NavItem(
        path: '/dashboard/customers',
        label: 'مشتریان',
        icon: Icons.people_outline,
        feature: 'customers_enabled',
      ),
      NavItem(
        path: '/dashboard/invoices',
        label: 'فاکتورها',
        icon: Icons.receipt_long_outlined,
        feature: 'customers_enabled',
      ),
      NavItem(
        path: '/dashboard/tickets',
        label: 'تیکت‌ها',
        icon: Icons.support_agent_outlined,
        feature: 'tickets_enabled',
      ),
      NavItem(
        path: '/dashboard/products',
        label: 'محصولات',
        icon: Icons.inventory_2_outlined,
        feature: 'products_enabled',
      ),
      NavItem(
        path: '/dashboard/storefront',
        label: 'فروشگاه‌ساز',
        icon: Icons.storefront_outlined,
        feature: 'storefront_enabled',
      ),
    ],
  ),
  NavSection(
    id: 'tools',
    label: 'ابزارها',
    items: [
      NavItem(
        path: '/dashboard/inbox',
        label: 'صندوق ورودی',
        icon: Icons.forum_outlined,
        feature: 'inbox_enabled',
      ),
      NavItem(
        path: '/dashboard/comments',
        label: 'صندوق کامنت',
        icon: Icons.chat_bubble_outline,
        feature: 'inbox_enabled',
      ),
      NavItem(
        path: '/dashboard/smart-answering',
        label: 'پاسخ هوشمند',
        icon: Icons.bolt_outlined,
        feature: 'smart_reply_enabled',
      ),
      NavItem(
        path: '/dashboard/automation',
        label: 'کامنت هوشمند',
        icon: Icons.mode_comment_outlined,
        feature: 'automation_enabled',
      ),
      NavItem(
        path: '/dashboard/vitrin',
        label: 'ویترین ساز',
        icon: Icons.view_carousel_outlined,
        feature: 'vitrin_enabled',
      ),
      NavItem(
        path: '/dashboard/follow-up',
        label: 'پشتیبان هوشمند',
        icon: Icons.schedule_outlined,
        feature: 'followup_enabled',
      ),
      NavItem(
        path: '/dashboard/ice-breakers',
        label: 'پیام خوش‌آمدگویی',
        icon: Icons.waving_hand_outlined,
        feature: 'icebreaker_enabled',
      ),
    ],
  ),
  NavSection(
    id: 'insights',
    label: 'گزارش',
    items: [
      NavItem(
        path: '/dashboard/analytics',
        label: 'گزارش‌ها',
        icon: Icons.insights_outlined,
        feature: 'analytics_enabled',
      ),
    ],
  ),
  NavSection(
    id: 'workspace',
    label: 'فضا و حساب',
    items: [
      NavItem(
        path: '/dashboard/knowledge',
        label: 'پایگاه دانش',
        icon: Icons.menu_book_outlined,
        feature: 'knowledge_enabled',
      ),
      NavItem(
        path: '/dashboard/team',
        label: 'تیم',
        icon: Icons.groups_outlined,
        feature: 'team_enabled',
      ),
      NavItem(
        path: '/dashboard/wallet',
        label: 'کیف پول',
        icon: Icons.account_balance_wallet_outlined,
      ),
      NavItem(
        path: '/dashboard/billing',
        label: 'اشتراک',
        icon: Icons.credit_card_outlined,
      ),
      NavItem(
        path: '/dashboard/settings',
        label: 'تنظیمات',
        icon: Icons.settings_outlined,
      ),
    ],
  ),
];

const _featurePaths = {
  '/dashboard/inbox': 'inbox_enabled',
  '/dashboard/comments': 'inbox_enabled',
  '/dashboard/customers': 'customers_enabled',
  '/dashboard/invoices': 'customers_enabled',
  '/dashboard/tickets': 'tickets_enabled',
  '/dashboard/products': 'products_enabled',
  '/dashboard/storefront': 'storefront_enabled',
  '/dashboard/knowledge': 'knowledge_enabled',
  '/dashboard/automation': 'automation_enabled',
  '/dashboard/smart-answering': 'smart_reply_enabled',
  '/dashboard/vitrin': 'vitrin_enabled',
  '/dashboard/follow-up': 'followup_enabled',
  '/dashboard/ice-breakers': 'icebreaker_enabled',
  '/dashboard/analytics': 'analytics_enabled',
  '/dashboard/team': 'team_enabled',
};

const _subscriptionExempt = [
  '/dashboard/billing',
  '/dashboard/wallet',
  '/dashboard/settings',
  '/dashboard/tickets',
];

bool _active(String location, NavItem item) {
  if (item.exact) return location == item.path;
  return location == item.path || location.startsWith('${item.path}/');
}

String? featureForPath(String location) {
  for (final entry in _featurePaths.entries) {
    if (location == entry.key || location.startsWith('${entry.key}/'))
      return entry.value;
  }
  return null;
}

bool subscriptionExempt(String location) {
  return _subscriptionExempt.any(
    (prefix) => location == prefix || location.startsWith('$prefix/'),
  );
}

String menuKey(String location) {
  if (location == '/dashboard') return 'dashboard';
  final rest = location.replaceFirst('/dashboard/', '').split('/').first;
  return rest.isEmpty ? 'dashboard' : rest;
}

void openDashboardRoute(BuildContext context, String path) {
  final current = GoRouterState.of(context).uri.path;
  if (path == '/dashboard') {
    if (current != '/dashboard') context.go('/dashboard');
    return;
  }
  if (current == path) return;
  context.push(path);
}

class DashboardPageFrame extends StatelessWidget {
  const DashboardPageFrame({
    super.key,
    required this.location,
    required this.child,
  });

  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.dt.bgSubtle,
      body: SafeArea(
        bottom: false,
        child: _ShellBody(location: location, child: child),
      ),
    );
  }
}

class DashboardShell extends StatelessWidget {
  const DashboardShell({
    super.key,
    required this.location,
    required this.child,
  });

  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 1080;
    return Scaffold(
      drawer: wide
          ? null
          : Drawer(
              child: SafeArea(
                child: _Sidebar(
                  location: location,
                  onNavigate: () => Navigator.pop(context),
                ),
              ),
            ),
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
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.location, this.onNavigate});

  final String location;
  final VoidCallback? onNavigate;

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionBloc>();
    final features = session.workspace?.features;
    final subscriptionLocked = session.workspace?.needsSubscription ?? false;
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
                          backgroundColor: dt.surface,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(24),
                            ),
                          ),
                          builder: (context) => SafeArea(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(height: 10),
                                Container(
                                  width: 40,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: dt.border,
                                    borderRadius: BorderRadius.circular(99),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                for (final workspace in session.workspaces)
                                  ListTile(
                                    leading: Icon(
                                      Icons.check,
                                      color: workspace.id == session.workspaceId
                                          ? dt.primary
                                          : Colors.transparent,
                                    ),
                                    title: Text(
                                      workspace.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    onTap: () =>
                                        Navigator.pop(context, workspace.id),
                                  ),
                              ],
                            ),
                          ),
                        );
                        if (picked != null)
                          await session.selectWorkspace(picked);
                      },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: dt.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.apartment,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'فضای کاری',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              session.workspace!.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
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
                      child: Text(
                        section.label!,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: dt.textMuted,
                        ),
                      ),
                    ),
                  for (final item in section.items)
                    _NavTile(
                      item: item,
                      locked: subscriptionLocked
                          ? !subscriptionExempt(item.path)
                          : !(features?.enabled(item.feature) ?? true),
                      active: _active(location, item),
                      onTap: () {
                        final router = GoRouter.of(context);
                        onNavigate?.call();
                        if (item.path == '/dashboard') {
                          if (location != '/dashboard') {
                            router.go('/dashboard');
                          }
                          return;
                        }
                        if (location == item.path) return;
                        router.push(item.path);
                      },
                    ),
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
  const _NavTile({
    required this.item,
    required this.active,
    required this.onTap,
    this.locked = false,
  });

  final NavItem item;
  final bool active;
  final VoidCallback onTap;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final dt = context.dt;
    final selected = active && !locked;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: selected ? dt.primary50 : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Row(
              children: [
                Icon(
                  item.icon,
                  size: 20,
                  color: locked
                      ? dt.textSubtle
                      : selected
                      ? dt.primary
                      : dt.textSubtle,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.label,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: locked
                          ? dt.textSubtle
                          : selected
                          ? dt.text
                          : dt.textMuted,
                    ),
                  ),
                ),
                if (locked)
                  Icon(Icons.lock_outline, size: 16, color: dt.textSubtle),
                if (selected)
                  Container(
                    width: 4,
                    height: 22,
                    decoration: BoxDecoration(
                      color: dt.primary,
                      borderRadius: BorderRadius.circular(99),
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

class _TopBar extends StatelessWidget {
  const _TopBar({required this.wide});

  final bool wide;

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionBloc>();
    final dt = context.dt;
    final workspace = session.workspace;
    return Material(
      color: dt.surface,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: dt.border)),
          ),
          child: Row(
            children: [
              if (!wide)
                IconButton(
                  onPressed: () => Scaffold.of(context).openDrawer(),
                  icon: const Icon(Icons.menu),
                ),
              if (wide)
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'پنل مشتری',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: dt.textMuted,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          workspace?.name ?? 'Directoo',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        if (workspace?.role != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: dt.primary50,
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              faLabel(roleLabels, workspace?.role),
                              style: TextStyle(
                                color: dt.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                )
              else
                const BrandLogo(height: 28),
              const Spacer(),
              if ((workspace?.needsSubscription ?? false) ||
                  session.permissions.canReply ||
                  (workspace?.features.enabled('tickets_enabled') ?? true))
                IconButton(
                  tooltip: 'تیکت‌ها',
                  onPressed: () =>
                      openDashboardRoute(context, '/dashboard/tickets'),
                  icon: const Icon(Icons.support_agent_outlined),
                ),
              IconButton(
                tooltip: 'تنظیمات',
                onPressed: () =>
                    openDashboardRoute(context, '/dashboard/settings'),
                icon: const Icon(Icons.settings_outlined),
              ),
              if (wide) const _WalletChip(),
              IconButton(
                tooltip: 'حالت تاریک',
                onPressed: session.toggleTheme,
                icon: Icon(
                  session.dark
                      ? Icons.light_mode_outlined
                      : Icons.dark_mode_outlined,
                ),
              ),
              if (wide)
                IconButton(
                  tooltip: 'خروج',
                  onPressed: session.logout,
                  icon: const Icon(Icons.logout),
                ),
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
    final id = context.read<SessionBloc>().workspaceId;
    if (id != null && id != _loadedFor) {
      _loadedFor = id;
      context
          .read<BillingRepository>()
          .wallet(id)
          .then((wallet) {
            if (mounted) setState(() => _balance = wallet.balance);
          })
          .catchError((_) {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () => openDashboardRoute(context, '/dashboard/wallet'),
      icon: const Icon(Icons.account_balance_wallet_outlined, size: 18),
      label: Text(_balance == null ? 'کیف پول' : toman(_balance!)),
    );
  }
}

class _ShellBody extends StatelessWidget {
  const _ShellBody({required this.location, required this.child});

  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final workspace = context.watch<SessionBloc>().workspace;
    if (workspace == null) {
      return const _CenteredNotice(
        title: 'فضای کاری',
        description: 'فضای کاری پیدا نشد. از تنظیمات یکی بسازید.',
      );
    }
    if (workspace.needsSubscription && !subscriptionExempt(location)) {
      return const _NoSubscription();
    }
    final feature = featureForPath(location);
    final openedWhileUnsubscribed =
        workspace.needsSubscription && subscriptionExempt(location);
    if (feature != null &&
        !workspace.features.enabled(feature) &&
        !openedWhileUnsubscribed) {
      return const _FeatureDisabled();
    }
    final home = location == '/dashboard';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!home)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: _TutorialBanner(),
          ),
        Expanded(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, home ? 4 : 0, 16, 16),
            child: child,
          ),
        ),
      ],
    );
  }
}

class _NoSubscription extends StatelessWidget {
  const _NoSubscription();

  @override
  Widget build(BuildContext context) {
    final workspace = context.watch<SessionBloc>().workspace;
    final name = workspace?.name ?? '';
    final planName = workspace?.planName ?? '';
    final status = workspace?.subscriptionStatus;
    final named = name.isEmpty ? null : 'فضای کاری $name';
    final isFree = planName.isEmpty || planName == 'رایگان';
    final String title;
    final String description;
    if (status == 'cancelled') {
      title = named == null
          ? 'اشتراک این فضای کاری لغو شده است'
          : '$named اشتراکش لغو شده';
      description =
          'با فعال‌سازی مجدد اشتراک، همهٔ ابزارهای پنل دوباره در دسترس قرار می‌گیرند.';
    } else if (status == 'past_due') {
      title = named == null
          ? 'پرداخت اشتراک معوق مانده است'
          : 'پرداخت اشتراک $named معوق است';
      description =
          'پس از تکمیل پرداخت، دسترسی کامل پنل برای همین فضای کاری باز می‌شود.';
    } else if (!isFree && status != 'active') {
      title = named == null
          ? 'طرح «$planName» دیگر فعال نیست'
          : '$named طرح «$planName» فعال ندارد';
      description = 'یک اشتراک جدید انتخاب کنید تا ابزارهای پنل دوباره فعال شوند.';
    } else {
      title = named == null
          ? 'پنل دایرکتو با اشتراک فعال می‌شود'
          : '$named را با یک اشتراک قدرتمند کامل کنید';
      description =
          'پاسخ هوشمند، کامنت هوشمند، مدیریت مشتریان و بقیهٔ ابزارها با انتخاب اشتراک در دسترس شماست.';
    }
    return _CenteredNotice(
      kicker: 'دسترسی اشتراک',
      title: title,
      description: description,
      action: FilledButton(
        onPressed: () => openDashboardRoute(context, '/dashboard/billing'),
        child: const Text('مشاهده و فعال‌سازی اشتراک'),
      ),
    );
  }
}

class _FeatureDisabled extends StatelessWidget {
  const _FeatureDisabled();

  @override
  Widget build(BuildContext context) {
    return _CenteredNotice(
      title: 'این بخش در طرح فعلی فعال نیست.',
      description: 'با ارتقای اشتراک به این ابزار دسترسی پیدا می‌کنید.',
      action: FilledButton(
        onPressed: () => openDashboardRoute(context, '/dashboard/billing'),
        child: const Text('ارتقای اشتراک'),
      ),
    );
  }
}

class _CenteredNotice extends StatelessWidget {
  const _CenteredNotice({
    required this.title,
    required this.description,
    this.kicker,
    this.action,
  });

  final String title;
  final String description;
  final String? kicker;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final dt = context.dt;
    final showBack = GoRouter.of(context).canPop();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showBack)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: IconButton(
              tooltip: 'بازگشت',
              onPressed: () => context.pop(),
              icon: const Icon(
                Icons.arrow_forward,
                textDirection: TextDirection.ltr,
              ),
            ),
          ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (kicker != null) ...[
                  Text(
                    kicker!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: dt.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: dt.text,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: dt.textMuted, height: 1.7),
                ),
                if (action != null) ...[const SizedBox(height: 20), action!],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class DashboardHomeBanners extends StatelessWidget {
  const DashboardHomeBanners({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [_InstagramBanner(), _TutorialBanner()],
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
    final id = context.read<SessionBloc>().workspaceId;
    final location = GoRouterState.of(context).uri.path;
    if (id == null ||
        location.startsWith('/dashboard/settings') ||
        id == _loadedFor)
      return;
    _loadedFor = id;
    final api = context.read<InstagramRepository>();
    Future.wait([
          api.instagramAccounts(id),
          api.accessRequest(id).then<Object?>((value) => value),
        ])
        .then((results) {
          if (!mounted) return;
          final accounts = results[0] as List<InstagramAccount>;
          setState(() {
            _request = results[1] as InstagramAccessRequest?;
            _missing = !accounts.any(
              (account) => account.status == 'connected',
            );
          });
        })
        .catchError((_) {});
  }

  Future<void> _connect() async {
    final session = context.read<SessionBloc>();
    final id = session.workspaceId;
    if (id == null) return;
    if (_request?.status != 'approved') {
      await session.openInstagramSetup(reviewing: _request?.reviewing ?? false);
      return;
    }
    setState(() => _connecting = true);
    try {
      final url = await context.read<InstagramRepository>().startInstagramOAuth(
        id,
      );
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
    final canConnect = context
        .watch<SessionBloc>()
        .permissions
        .canManageInstagram;
    final dt = context.dt;

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: dt.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: dt.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: dt.primary50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.camera_alt_outlined,
                  color: dt.coral,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'اینستاگرام متصل نیست',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'برای دریافت دایرکت و پاسخ هوشمند، حساب را وصل کنید.',
            style: TextStyle(color: dt.textMuted, height: 1.6),
          ),
          const SizedBox(height: 12),
          if (canConnect)
            FilledButton(
              onPressed: _connecting ? null : _connect,
              child: Text(
                _connecting ? 'در حال اتصال...' : 'اتصال به اینستاگرام',
              ),
            )
          else
            Text(
              'برای اتصال، از مدیر فضا بخواهید اینستاگرام را وصل کند.',
              style: TextStyle(color: dt.textMuted),
            ),
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
    context
        .read<TutorialsRepository>()
        .tutorials()
        .then((items) {
          if (mounted) setState(() => _items = items);
        })
        .catchError((_) {
          if (mounted) setState(() => _items = const []);
        });
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final key = menuKey(location);
    MenuTutorial? tutorial;
    for (final item in _items ?? const <MenuTutorial>[]) {
      if (item.key == key && item.isActive && item.linkUrl.isNotEmpty)
        tutorial = item;
    }
    if (tutorial == null) return const SizedBox.shrink();
    final link = tutorial.linkUrl;
    final dt = context.dt;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: dt.primary50,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tutorial.title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                if (tutorial.description.isNotEmpty)
                  Text(
                    tutorial.description,
                    style: TextStyle(color: dt.textMuted),
                  ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => launchUrl(
              Uri.parse(link),
              mode: LaunchMode.externalApplication,
            ),
            child: Text(
              tutorial.linkLabel.isEmpty ? 'آموزش' : tutorial.linkLabel,
            ),
          ),
        ],
      ),
    );
  }
}
