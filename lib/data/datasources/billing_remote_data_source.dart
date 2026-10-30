import 'package:dio/dio.dart';
import '../../core/api_client.dart';
import '../../core/api_exception.dart';
import '../../core/json.dart';
import '../../domain/entities/models.dart';
import 'api_paths.dart';

abstract class BillingRemoteDataSource {
  Future<List<Plan>> plans();
  Future<Subscription?> subscription(int id);
  Future<UpgradePreview> previewUpgrade(int id, {required int planId, required String interval, String discount = '', String referral = ''});
  Future<String?> upgradePlan( int id, { required int planId, required String interval, required String paymentMethod, String discount = '', String referral = '', });
  Future<void> confirmStorePurchase(int id, {required String store, required String sku, required String purchaseToken, String orderId = '', String signedData = '', String signature = ''});
  Future<CardInfo> cardInfo(int id);
  Future<String> upgradeCardToCard( int id, { required int planId, required String interval, required String receiptPath, required String filename, String discount = '', String referral = '', });
  Future<List<PaymentRecord>> payments(int id);
  Future<WalletInfo> wallet(int id);
  Future<List<WalletTx>> walletTransactions(int id);
  Future<List<WalletPackage>> walletPackages(int id);
  Future<String> topUp(int id, {String? packageId, int? amount});
  Future<String> topUpCard( int id, { String? packageId, int? amount, required String receiptPath, required String filename, });
}

class BillingRemoteDataSourceImpl implements BillingRemoteDataSource {
  BillingRemoteDataSourceImpl(this._client);

  final ApiClient _client;

  @override
  Future<List<Plan>> plans() {
      return _client.get('/api/v1/plans/', parse: (data) => [for (final item in asJsonList(data)) Plan.fromJson(item)]);
    }

  @override
  Future<Subscription?> subscription(int id) async {
      try {
        return await _client.get(workspacePath(id, 'billing/subscription/'), auth: true, parse: (data) => Subscription.fromJson(asJson(data)));
      } on ApiException catch (error) {
        if (error.status == 404) return null;
        rethrow;
      }
    }

  @override
  Future<UpgradePreview> previewUpgrade(int id, {required int planId, required String interval, String discount = '', String referral = ''}) {
      return _client.post(
        workspacePath(id, 'billing/preview-upgrade/'),
        auth: true,
        data: {
          'plan_id': planId,
          'billing_interval': interval,
          'discount_code': discount,
          'referral_code': referral,
        },
        parse: (data) => UpgradePreview.fromJson(asJson(data)),
      );
    }

  @override
  Future<String?> upgradePlan(
      int id, {
      required int planId,
      required String interval,
      required String paymentMethod,
      String discount = '',
      String referral = '',
    }) async {
      final data = await _client.post<Json>(
        workspacePath(id, 'billing/upgrade/'),
        auth: true,
        data: {
          'plan_id': planId,
          'billing_interval': interval,
          'payment_method': paymentMethod,
          'discount_code': discount,
          'referral_code': referral,
        },
        parse: asJson,
      );
      final url = asString(data['payment_url']);
      return url.isEmpty ? null : url;
    }

  @override
  Future<void> confirmStorePurchase(
    int id, {
    required String store,
    required String sku,
    required String purchaseToken,
    String orderId = '',
    String signedData = '',
    String signature = '',
  }) {
    return _client.post<void>(
      workspacePath(id, 'billing/store-purchase/'),
      auth: true,
      data: {
        'store': store,
        'sku': sku,
        'purchase_token': purchaseToken,
        'order_id': orderId,
        'signed_data': signedData,
        'signature': signature,
      },
      parse: (_) {},
    );
  }

  @override
  Future<CardInfo> cardInfo(int id) {
      return _client.get(workspacePath(id, 'billing/card-to-card/'), auth: true, parse: (data) => CardInfo.fromJson(asJson(data)));
    }

  @override
  Future<String> upgradeCardToCard(
      int id, {
      required int planId,
      required String interval,
      required String receiptPath,
      required String filename,
      String discount = '',
      String referral = '',
    }) async {
      final form = FormData.fromMap({
        'plan_id': '$planId',
        'billing_interval': interval,
        'payment_method': 'card_to_card',
        if (discount.isNotEmpty) 'discount_code': discount,
        if (referral.isNotEmpty) 'referral_code': referral,
        'receipt': await MultipartFile.fromFile(receiptPath, filename: filename),
      });
      final data = await _client.post<Json>(workspacePath(id, 'billing/upgrade/'), auth: true, data: form, parse: asJson);
      return asString(data['message']).isEmpty ? 'فیش شما دریافت شد و در حال بررسی است.' : asString(data['message']);
    }

  @override
  Future<List<PaymentRecord>> payments(int id) {
      return _client.get(
        workspacePath(id, 'billing/payments/'),
        auth: true,
        parse: (data) => [for (final item in asJsonList(data)) PaymentRecord.fromJson(item)],
      );
    }

  @override
  Future<WalletInfo> wallet(int id) {
      return _client.get(workspacePath(id, 'billing/wallet/'), auth: true, parse: (data) => WalletInfo.fromJson(asJson(data)));
    }

  @override
  Future<List<WalletTx>> walletTransactions(int id) {
      return _client.get(
        workspacePath(id, 'billing/wallet/transactions/'),
        auth: true,
        parse: (data) => [for (final item in asJsonList(data)) WalletTx.fromJson(item)],
      );
    }

  @override
  Future<List<WalletPackage>> walletPackages(int id) {
      return _client.get(
        workspacePath(id, 'billing/wallet/packages/'),
        auth: true,
        parse: (data) => [for (final item in asJsonList(data)) WalletPackage.fromJson(item)],
      );
    }

  @override
  Future<String> topUp(int id, {String? packageId, int? amount}) async {
      final data = await _client.post<Json>(
        workspacePath(id, 'billing/wallet/top-up/'),
        auth: true,
        data: {
          'payment_method': 'gateway',
          'package_id': ?packageId,
          'amount': ?amount,
        },
        parse: asJson,
      );
      final url = asString(data['payment_url']);
      if (url.isEmpty) throw const ApiException('آدرس درگاه پرداخت دریافت نشد.');
      return url;
    }

  @override
  Future<String> topUpCard(
      int id, {
      String? packageId,
      int? amount,
      required String receiptPath,
      required String filename,
    }) async {
      final form = FormData.fromMap({
        'payment_method': 'card_to_card',
        'package_id': ?packageId,
        'amount': ?amount?.toString(),
        'receipt': await MultipartFile.fromFile(receiptPath, filename: filename),
      });
      final data = await _client.post<Json>(workspacePath(id, 'billing/wallet/top-up/'), auth: true, data: form, parse: asJson);
      return asString(data['message']).isEmpty ? 'فیش شما دریافت شد و در حال بررسی است.' : asString(data['message']);
    }
}
