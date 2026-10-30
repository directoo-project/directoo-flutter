import 'package:go_router/go_router.dart';

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
import '../state/session.dart';

GoRouter buildRouter(SessionController session) {
  return GoRouter(
    initialLocation: '/boot',
    refreshListenable: session,
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
          GoRoute(path: '/dashboard/customers', builder: (_, _) => const CustomersPage()),
          GoRoute(path: '/dashboard/customers/new', builder: (_, _) => const CustomerFormPage()),
          GoRoute(
            path: '/dashboard/customers/:id/edit',
            builder: (_, state) => CustomerFormPage(customerId: int.parse(state.pathParameters['id']!)),
          ),
          GoRoute(
            path: '/dashboard/customers/:id',
            builder: (_, state) => CustomerDetailPage(id: int.parse(state.pathParameters['id']!)),
          ),
          GoRoute(path: '/dashboard/invoices', builder: (_, _) => const InvoicesPage()),
          GoRoute(path: '/dashboard/invoices/new', builder: (_, _) => const InvoiceFormPage()),
          GoRoute(
            path: '/dashboard/invoices/:id',
            builder: (_, state) => InvoiceDetailPage(id: int.parse(state.pathParameters['id']!)),
          ),
          GoRoute(path: '/dashboard/tickets', builder: (_, _) => const TicketsPage()),
          GoRoute(
            path: '/dashboard/tickets/:id',
            builder: (_, state) => TicketDetailPage(id: int.parse(state.pathParameters['id']!)),
          ),
          GoRoute(path: '/dashboard/products', builder: (_, _) => const ProductsPage()),
          GoRoute(path: '/dashboard/storefront', builder: (_, _) => const StorefrontPage()),
          GoRoute(path: '/dashboard/inbox', builder: (_, _) => const InboxPage()),
          GoRoute(
            path: '/dashboard/inbox/chat',
            builder: (_, state) => InboxThreadPage(chatId: state.uri.queryParameters['id'] ?? ''),
          ),
          GoRoute(path: '/dashboard/comments', builder: (_, _) => const CommentsPage()),
          GoRoute(
            path: '/dashboard/smart-answering',
            builder: (_, _) => const AutomationListPage(
              title: 'پاسخ هوشمند',
              description: 'پاسخ خودکار دایرکت با کلمه کلیدی',
              triggerType: 'smart_reply',
            ),
          ),
          GoRoute(
            path: '/dashboard/smart-answering/edit',
            builder: (_, state) => AutomationEditorPage(triggerType: 'smart_reply', flowId: int.tryParse(state.uri.queryParameters['id'] ?? '')),
          ),
          GoRoute(
            path: '/dashboard/automation',
            builder: (_, _) => const AutomationListPage(
              title: 'کامنت هوشمند',
              description: 'پاسخ خودکار به کامنت و انتقال به دایرکت',
              triggerType: 'comment',
            ),
          ),
          GoRoute(
            path: '/dashboard/automation/edit',
            builder: (_, state) => AutomationEditorPage(triggerType: 'comment', flowId: int.tryParse(state.uri.queryParameters['id'] ?? '')),
          ),
          GoRoute(
            path: '/dashboard/vitrin',
            builder: (_, _) => const AutomationListPage(
              title: 'ویترین ساز',
              description: 'کارت محصول در پاسخ به کلمه کلیدی دایرکت',
              triggerType: 'vitrin',
            ),
          ),
          GoRoute(
            path: '/dashboard/vitrin/edit',
            builder: (_, state) => AutomationEditorPage(triggerType: 'vitrin', flowId: int.tryParse(state.uri.queryParameters['id'] ?? '')),
          ),
          GoRoute(
            path: '/dashboard/follow-up',
            builder: (_, _) => const AutomationListPage(
              title: 'پشتیبان هوشمند',
              description: 'پیگیری زمان‌بندی‌شده مشتری در دایرکت',
              triggerType: 'follow_up',
            ),
          ),
          GoRoute(
            path: '/dashboard/follow-up/edit',
            builder: (_, state) => AutomationEditorPage(triggerType: 'follow_up', flowId: int.tryParse(state.uri.queryParameters['id'] ?? '')),
          ),
          GoRoute(path: '/dashboard/ice-breakers', builder: (_, _) => const IceBreakersPage()),
          GoRoute(path: '/dashboard/analytics', builder: (_, _) => const AnalyticsPage()),
          GoRoute(path: '/dashboard/knowledge', builder: (_, _) => const KnowledgePage()),
          GoRoute(path: '/dashboard/team', builder: (_, _) => const TeamPage()),
          GoRoute(path: '/dashboard/wallet', builder: (_, _) => const WalletPage()),
          GoRoute(path: '/dashboard/billing', builder: (_, _) => const BillingPage()),
          GoRoute(path: '/dashboard/settings', builder: (_, _) => const SettingsPage()),
        ],
      ),
    ],
  );
}
