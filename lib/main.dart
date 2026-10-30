import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/api_client.dart';
import 'core/token_store.dart';
import 'data/directoo_api.dart';
import 'router/app_router.dart';
import 'state/session.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final tokens = TokenStore();
  await tokens.load();
  final api = DirectooApi(ApiClient(tokens));
  final session = SessionController(api: api, prefs: prefs, tokens: tokens);
  api.onUnauthorized = () {
    session.onUnauthorized();
  };
  runApp(DirectooApp(session: session, api: api, router: buildRouter(session)));
  await session.bootstrap();
}
