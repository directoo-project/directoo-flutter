import '../entities/models.dart';

abstract class BillingRepository {
  Future<List<Plan>> plans();
  Future<Subscription?> subscription(int id);
  Future<UpgradePreview> previewUpgrade(int id, {required int planId, required String interval, String discount = '', String referral = ''});
  Future<String?> upgradePlan( int id, { required int planId, required String interval, required String paymentMethod, String discount = '', String referral = '', });
  Future<void> confirmStorePurchase(int id, {required String store, required String sku, required String purchaseToken, String orderId = '', String signedData = '', String signature = '', int? amount, String packageId = ''});
  Future<CardInfo> cardInfo(int id);
  Future<String> upgradeCardToCard( int id, { required int planId, required String interval, required String receiptPath, required String filename, String discount = '', String referral = '', });
  Future<List<PaymentRecord>> payments(int id);
  Future<WalletInfo> wallet(int id);
  Future<List<WalletTx>> walletTransactions(int id);
  Future<List<WalletPackage>> walletPackages(int id);
  Future<String> topUp(int id, {String? packageId, int? amount});
  Future<String> topUpCard( int id, { String? packageId, int? amount, required String receiptPath, required String filename, });
}
