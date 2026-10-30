import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import 'core/di/injection.dart';
import 'domain/repositories/analytics_repository.dart';
import 'domain/repositories/auth_repository.dart';
import 'domain/repositories/automation_repository.dart';
import 'domain/repositories/billing_repository.dart';
import 'domain/repositories/customers_repository.dart';
import 'domain/repositories/inbox_repository.dart';
import 'domain/repositories/instagram_repository.dart';
import 'domain/repositories/invoices_repository.dart';
import 'domain/repositories/knowledge_repository.dart';
import 'domain/repositories/products_repository.dart';
import 'domain/repositories/tickets_repository.dart';
import 'domain/repositories/tutorials_repository.dart';
import 'domain/repositories/workspace_repository.dart';
import 'presentation/session/session_bloc.dart';
import 'theme/app_theme.dart';

class DirectooApp extends StatelessWidget {
  const DirectooApp({super.key, required this.session, required this.router});

  final SessionBloc session;
  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>.value(value: sl()),
        RepositoryProvider<WorkspaceRepository>.value(value: sl()),
        RepositoryProvider<InstagramRepository>.value(value: sl()),
        RepositoryProvider<KnowledgeRepository>.value(value: sl()),
        RepositoryProvider<CustomersRepository>.value(value: sl()),
        RepositoryProvider<InvoicesRepository>.value(value: sl()),
        RepositoryProvider<ProductsRepository>.value(value: sl()),
        RepositoryProvider<InboxRepository>.value(value: sl()),
        RepositoryProvider<AutomationRepository>.value(value: sl()),
        RepositoryProvider<AnalyticsRepository>.value(value: sl()),
        RepositoryProvider<BillingRepository>.value(value: sl()),
        RepositoryProvider<TicketsRepository>.value(value: sl()),
        RepositoryProvider<TutorialsRepository>.value(value: sl()),
      ],
      child: BlocProvider<SessionBloc>.value(
        value: session,
        child: Builder(
          builder: (context) {
            final dark = context.watch<SessionBloc>().dark;
            return MaterialApp.router(
              title: 'دایرکتو',
              debugShowCheckedModeBanner: false,
              locale: const Locale('fa'),
              supportedLocales: const [Locale('fa'), Locale('en')],
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              theme: buildTheme(isDark: false),
              darkTheme: buildTheme(isDark: true),
              themeMode: dark ? ThemeMode.dark : ThemeMode.light,
              routerConfig: router,
            );
          },
        ),
      ),
    );
  }
}
