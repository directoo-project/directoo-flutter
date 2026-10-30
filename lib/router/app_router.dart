import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../core/logging/router_logger.dart';

import '../features/auth/auth_pages.dart';
import '../features/auth/intro_page.dart';
import '../features/automation/automation_pages.dart';
import '../features/catalog/products_page.dart';
import '../features/crm/customers_page.dart';
import '../features/crm/invoices_page.dart';
import '../features/crm/tickets_page.dart';
import '../features/home/home_page.dart';
import '../features/inbox/inbox_page.dart';
import '../features/shell/dashboard_shell.dart';
import '../features/workspace/workspace_pages.dart';
import '../presentation/session/session_bloc.dart';

Widget _page(GoRouterState state, Widget child) {
  return DashboardPageFrame(location: state.uri.path, child: child);
}

GoRouter buildRouter(SessionBloc session) {
  return GoRouter(
    initialLocation: '/boot',
    debugLogDiagnostics: true,
    refreshListenable: _RouterRefresh(session.stream),
    observers: [AppNavigatorObserver()],
    redirect: (context, state) {
      final loc = state.matchedLocation;
      if (session.booting || session.bootError != null) {
        return loc == '/boot' ? null : '/boot';
      }
      switch (session.gate) {
        case AuthGate.unauthenticated:
          if (!session.introSeen) return loc == '/intro' ? null : '/intro';
          if (loc == '/intro') return '/login';
          return loc == '/login' || loc == '/otp' ? null : '/login';
        case AuthGate.profile:
          return loc == '/setup' ? null : '/setup';
        case AuthGate.knowledge:
          return loc == '/setup/knowledge' ? null : '/setup/knowledge';
        case AuthGate.instagram:
          final target = session.instagramReviewing ? '/setup/instagram/pending' : '/setup/instagram';
          return loc == target ? null : target;
        case AuthGate.ready:
          if (loc == '/login' || loc == '/otp' || loc == '/boot' || loc == '/intro' || loc == '/') return '/dashboard';
          if (loc == '/setup' && session.user?.profileIncomplete != true) return '/dashboard';
          return null;
      }
    },
    routes: [
      GoRoute(path: '/boot', builder: (_, _) => const BootPage()),
      GoRoute(path: '/intro', builder: (_, _) => const IntroPage()),
      GoRoute(path: '/login', builder: (_, _) => const LoginPage()),
      GoRoute(path: '/otp', builder: (_, _) => const OtpPage()),
      GoRoute(path: '/setup', builder: (_, _) => const ProfileSetupPage()),
      GoRoute(path: '/setup/knowledge', builder: (_, _) => const KnowledgeSetupPage()),
      GoRoute(path: '/setup/instagram', builder: (_, _) => const InstagramSetupPage()),
      GoRoute(path: '/setup/instagram/pending', builder: (_, _) => const InstagramPendingPage()),
      ShellRoute(
        builder: (context, state, child) => DashboardShell(location: state.uri.path, child: child),
        routes: [
          GoRoute(path: '/dashboard', builder: (_, _) => const HomePage()),
        ],
      ),
      GoRoute(path: '/dashboard/customers', builder: (context, state) => _page(state, const CustomersPage())),
      GoRoute(path: '/dashboard/customers/new', builder: (context, state) => _page(state, const CustomerFormPage())),
      GoRoute(
        path: '/dashboard/customers/:id/edit',
        builder: (context, state) => _page(state, CustomerFormPage(customerId: int.parse(state.pathParameters['id']!))),
      ),
      GoRoute(
        path: '/dashboard/customers/:id',
        builder: (context, state) => _page(state, CustomerDetailPage(id: int.parse(state.pathParameters['id']!))),
      ),
      GoRoute(path: '/dashboard/invoices', builder: (context, state) => _page(state, const InvoicesPage())),
      GoRoute(path: '/dashboard/invoices/new', builder: (context, state) => _page(state, const InvoiceFormPage())),
      GoRoute(
        path: '/dashboard/invoices/:id',
        builder: (context, state) => _page(state, InvoiceDetailPage(id: int.parse(state.pathParameters['id']!))),
      ),
      GoRoute(path: '/dashboard/tickets', builder: (context, state) => _page(state, const TicketsPage())),
      GoRoute(
        path: '/dashboard/tickets/:id',
        builder: (context, state) => _page(state, TicketDetailPage(id: int.parse(state.pathParameters['id']!))),
      ),
      GoRoute(path: '/dashboard/products', builder: (context, state) => _page(state, const ProductsPage())),
      GoRoute(path: '/dashboard/storefront', builder: (context, state) => _page(state, const StorefrontPage())),
      GoRoute(path: '/dashboard/inbox', builder: (context, state) => _page(state, const InboxPage())),
      GoRoute(
        path: '/dashboard/inbox/chat',
        builder: (context, state) => _page(state, InboxThreadPage(chatId: state.uri.queryParameters['id'] ?? '')),
      ),
      GoRoute(path: '/dashboard/comments', builder: (context, state) => _page(state, const CommentsPage())),
      GoRoute(
        path: '/dashboard/smart-answering',
        builder: (context, state) => _page(
          state,
          const AutomationListPage(
            title: 'پاسخ هوشمند',
            description: 'پاسخ خودکار دایرکت با کلمه کلیدی',
            triggerType: 'smart_reply',
          ),
        ),
      ),
      GoRoute(
        path: '/dashboard/smart-answering/edit',
        builder: (context, state) => _page(state, AutomationEditorPage(triggerType: 'smart_reply', flowId: int.tryParse(state.uri.queryParameters['id'] ?? ''))),
      ),
      GoRoute(
        path: '/dashboard/automation',
        builder: (context, state) => _page(
          state,
          const AutomationListPage(
            title: 'کامنت هوشمند',
            description: 'پاسخ خودکار به کامنت و انتقال به دایرکت',
            triggerType: 'comment',
          ),
        ),
      ),
      GoRoute(
        path: '/dashboard/automation/edit',
        builder: (context, state) => _page(state, AutomationEditorPage(triggerType: 'comment', flowId: int.tryParse(state.uri.queryParameters['id'] ?? ''))),
      ),
      GoRoute(
        path: '/dashboard/vitrin',
        builder: (context, state) => _page(
          state,
          const AutomationListPage(
            title: 'ویترین ساز',
            description: 'کارت محصول در پاسخ به کلمه کلیدی دایرکت',
            triggerType: 'vitrin',
          ),
        ),
      ),
      GoRoute(
        path: '/dashboard/vitrin/edit',
        builder: (context, state) => _page(state, AutomationEditorPage(triggerType: 'vitrin', flowId: int.tryParse(state.uri.queryParameters['id'] ?? ''))),
      ),
      GoRoute(
        path: '/dashboard/follow-up',
        builder: (context, state) => _page(
          state,
          const AutomationListPage(
            title: 'پشتیبان هوشمند',
            description: 'پیگیری زمان‌بندی‌شده مشتری در دایرکت',
            triggerType: 'follow_up',
          ),
        ),
      ),
      GoRoute(
        path: '/dashboard/follow-up/edit',
        builder: (context, state) => _page(state, AutomationEditorPage(triggerType: 'follow_up', flowId: int.tryParse(state.uri.queryParameters['id'] ?? ''))),
      ),
      GoRoute(path: '/dashboard/ice-breakers', builder: (context, state) => _page(state, const IceBreakersPage())),
      GoRoute(path: '/dashboard/analytics', builder: (context, state) => _page(state, const AnalyticsPage())),
      GoRoute(path: '/dashboard/knowledge', builder: (context, state) => _page(state, const KnowledgePage())),
      GoRoute(path: '/dashboard/team', builder: (context, state) => _page(state, const TeamPage())),
      GoRoute(path: '/dashboard/wallet', builder: (context, state) => _page(state, const WalletPage())),
      GoRoute(path: '/dashboard/billing', builder: (context, state) => _page(state, const BillingPage())),
      GoRoute(path: '/dashboard/settings', builder: (context, state) => _page(state, const SettingsPage())),
    ],
  );
}

class _RouterRefresh extends ChangeNotifier {
  _RouterRefresh(Stream<dynamic> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
