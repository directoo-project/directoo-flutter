import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'data/directoo_api.dart';
import 'state/session.dart';
import 'theme/app_theme.dart';

class DirectooApp extends StatelessWidget {
  const DirectooApp({super.key, required this.session, required this.api, required this.router});

  final SessionController session;
  final DirectooApi api;
  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<DirectooApi>.value(value: api),
        ChangeNotifierProvider<SessionController>.value(value: session),
      ],
      child: Builder(
        builder: (context) {
          final dark = context.watch<SessionController>().dark;
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
    );
  }
}
