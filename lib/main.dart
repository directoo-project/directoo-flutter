import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'app.dart';
import 'core/di/injection.dart';
import 'core/logging/app_bloc_observer.dart';
import 'presentation/session/session_bloc.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Bloc.observer = AppBlocObserver();
  await configureDependencies();
  final session = sl<SessionBloc>();
  runApp(DirectooApp(session: session, router: sl<GoRouter>()));
  await session.bootstrap();
}
