import 'package:flutter/foundation.dart';

class AppLog {
  static void dio(Object? message) => _write('DIO', message);

  static void router(Object? message) => _write('ROUTER', message);

  static void bloc(Object? message) => _write('BLOC', message);

  static void di(Object? message) => _write('DI', message);

  static void _write(String tag, Object? message) {
    debugPrint('[$tag] $message');
  }
}
