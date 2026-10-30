import 'package:flutter/widgets.dart';

import 'app_log.dart';

class AppNavigatorObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    AppLog.router('push ${_name(route)}');
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    AppLog.router('pop ${_name(route)} → ${_name(previousRoute)}');
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    AppLog.router('replace ${_name(oldRoute)} → ${_name(newRoute)}');
  }

  String _name(Route<dynamic>? route) {
    if (route == null) return '-';
    final name = route.settings.name;
    if (name != null && name.isNotEmpty) return name;
    return route.settings.arguments?.toString() ?? route.runtimeType.toString();
  }
}
