import '../../domain/entities/models.dart';
import '../../domain/repositories/billing_repository.dart';
import '../datasources/billing_remote_data_source.dart';

class BillingRepositoryImpl implements BillingRepository {
  BillingRepositoryImpl(this._remote);

  final BillingRemoteDataSource _remote;

  @override
  Future<List<Plan>> plans() => _remote.plans();

  @override
  Future<Subscription?> subscription(int id) => _remote.subscription(id);

  @override
  Future<UpgradePreview> previewUpgrade(int id, {required int planId, required String interval, String discount = '', String referral = ''}) => _remote.previewUpgrade(id, planId: planId, interval: interval, discount: discount, referral: referral);

  @override
  Future<String?> upgradePlan( int id, { required int planId, required String interval, required String paymentMethod, String discount = '', String referral = '', }) => _remote.upgradePlan(id, planId: planId, interval: interval, paymentMethod: paymentMethod, discount: discount, referral: referral);

  @override
  Future<CardInfo> cardInfo(int id) => _remote.cardInfo(id);

  @override
  Future<String> upgradeCardToCard( int id, { required int planId, required String interval, required String receiptPath, required String filename, String discount = '', String referral = '', }) => _remote.upgradeCardToCard(id, planId: planId, interval: interval, receiptPath: receiptPath, filename: filename, discount: discount, referral: referral);

  @override
  Future<List<PaymentRecord>> payments(int id) => _remote.payments(id);

  @override
  Future<WalletInfo> wallet(int id) => _remote.wallet(id);

  @override
  Future<List<WalletTx>> walletTransactions(int id) => _remote.walletTransactions(id);

  @override
  Future<List<WalletPackage>> walletPackages(int id) => _remote.walletPackages(id);

  @override
  Future<String> topUp(int id, {String? packageId, int? amount}) => _remote.topUp(id, packageId: packageId, amount: amount);

  @override
  Future<String> topUpCard( int id, { String? packageId, int? amount, required String receiptPath, required String filename, }) => _remote.topUpCard(id, packageId: packageId, amount: amount, receiptPath: receiptPath, filename: filename);
}
