import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../domain/entities/models.dart';
import '../domain/repositories/billing_repository.dart';

class StoreConfig {
  const StoreConfig({required this.store, required this.rsaKey});

  final String store;
  final String rsaKey;

  bool get isStore => store == 'bazaar' || store == 'myket';

  String get title => switch (store) {
        'bazaar' => 'کافه‌بازار',
        'myket' => 'مایکت',
        _ => 'درگاه',
      };
}

class StoreBillingException implements Exception {
  StoreBillingException(this.message);

  final String message;

  @override
  String toString() => message;
}

class StorePurchaseCancelled implements Exception {}

class _Owned {
  const _Owned({
    required this.sku,
    required this.token,
    required this.orderId,
    this.signedData = '',
    this.signature = '',
  });

  final String sku;
  final String token;
  final String orderId;
  final String signedData;
  final String signature;
}

class StoreBilling {
  StoreBilling._();

  static const _channel = MethodChannel('ir.directoo/store');
  static const _billing = MethodChannel('ir.directoo/billing');
  static StoreConfig? _config;
  static var _connected = false;

  static Future<StoreConfig> config() async {
    final cached = _config;
    if (cached != null) return cached;
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return _config = const StoreConfig(store: '', rsaKey: '');
    }
    try {
      final raw = await _channel.invokeMapMethod<String, dynamic>('config');
      final store = raw?['store']?.toString() ?? '';
      final rsaKey = raw?['rsaKey']?.toString() ?? '';
      return _config = StoreConfig(
        store: store == 'bazaar' || store == 'myket' ? store : '',
        rsaKey: rsaKey,
      );
    } catch (_) {
      return _config = const StoreConfig(store: '', rsaKey: '');
    }
  }

  static String walletSku(String packageId) => 'directoo_wallet_$packageId';

  static String payloadFor(int workspaceId) => 'w$workspaceId';

  static Future<void> buyPlan({
    required BillingRepository api,
    required int workspaceId,
    required Plan plan,
    required String interval,
  }) async {
    final current = await _requireStore();
    final sku = plan.storeSku(current.store, interval);
    if (sku.isEmpty) {
      throw StoreBillingException('توکن محصول ${current.title} برای این پلن در پنل ادمین وارد نشده است.');
    }
    await buySku(api: api, workspaceId: workspaceId, sku: sku);
  }

  static Future<void> buySku({
    required BillingRepository api,
    required int workspaceId,
    required String sku,
  }) async {
    final current = await _requireStore();
    try {
      final bought = await _purchase(sku, payloadFor(workspaceId));
      await _acknowledge(current, api, workspaceId, bought);
    } on StorePurchaseCancelled {
      rethrow;
    } catch (error, stack) {
      final settled = await _settleSku(current, api, workspaceId, sku);
      if (!settled) Error.throwWithStackTrace(error, stack);
    }
  }

  /// Confirms purchases that were paid in the store but not consumed yet.
  static Future<void> recover(BillingRepository api, int workspaceId) async {
    try {
      final current = await config();
      if (!current.isStore || current.rsaKey.isEmpty) return;
      await _connect(current);
      for (final item in await _inventory()) {
        await _acknowledge(current, api, workspaceId, item);
      }
    } catch (_) {}
  }

  static Future<StoreConfig> _requireStore() async {
    final current = await config();
    if (!current.isStore) {
      throw StoreBillingException('این نسخه به فروشگاه وصل نیست.');
    }
    if (current.rsaKey.isEmpty) {
      throw StoreBillingException('کلید عمومی پرداخت در android/store.properties تنظیم نشده است.');
    }
    await _connect(current);
    return current;
  }

  static Future<void> _connect(StoreConfig current) async {
    if (_connected) return;
    try {
      await _billing.invokeMethod<void>('connect', {'rsaKey': current.rsaKey});
    } on PlatformException catch (error) {
      throw StoreBillingException(error.message ?? 'اتصال به ${current.title} برقرار نشد.');
    }
    _connected = true;
  }

  static Future<_Owned> _purchase(String sku, String payload) async {
    try {
      final info = await _billing.invokeMapMethod<String, dynamic>('purchase', {
        'sku': sku,
        'payload': payload,
      });
      final token = info?['purchaseToken']?.toString() ?? '';
      if (info == null || info['purchaseState'] != 'PURCHASED' || token.isEmpty) {
        throw StoreBillingException('خرید در فروشگاه تکمیل نشد.');
      }
      return _Owned(
        sku: info['productId']?.toString() ?? sku,
        token: token,
        orderId: info['orderId']?.toString() ?? '',
        signedData: info['signedData']?.toString() ?? '',
        signature: info['signature']?.toString() ?? '',
      );
    } on PlatformException catch (error) {
      if (error.code == 'PURCHASE_CANCELLED') throw StorePurchaseCancelled();
      throw StoreBillingException(error.message ?? 'خرید ناموفق بود.');
    }
  }

  static Future<bool> _settleSku(StoreConfig current, BillingRepository api, int workspaceId, String sku) async {
    try {
      final match = (await _inventory()).where((item) => item.sku == sku).toList();
      if (match.isEmpty) return false;
      for (final item in match) {
        await _acknowledge(current, api, workspaceId, item);
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<List<_Owned>> _inventory() async {
    final items = await _billing.invokeMethod<List<dynamic>>('purchases') ?? const [];
    return [
      for (final raw in items)
        if (raw is Map && raw['purchaseState'] == 'PURCHASED' && (raw['purchaseToken']?.toString().isNotEmpty ?? false))
          _Owned(
            sku: raw['productId']?.toString() ?? '',
            token: raw['purchaseToken'].toString(),
            orderId: raw['orderId']?.toString() ?? '',
            signedData: raw['signedData']?.toString() ?? '',
            signature: raw['signature']?.toString() ?? '',
          ),
    ];
  }

  static Future<void> _acknowledge(StoreConfig current, BillingRepository api, int workspaceId, _Owned item) async {
    await api.confirmStorePurchase(
      workspaceId,
      store: current.store,
      sku: item.sku,
      purchaseToken: item.token,
      orderId: item.orderId,
      signedData: item.signedData,
      signature: item.signature,
    );
    try {
      await _billing.invokeMethod<void>('consume', {'token': item.token});
    } catch (_) {}
  }
}
