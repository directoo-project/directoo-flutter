import 'package:dio/dio.dart';

import '../core/api_client.dart';
import '../core/api_exception.dart';
import '../core/json.dart';
import '../models/models.dart';

class DirectooApi {
  DirectooApi(this.client);

  final ApiClient client;

  void Function()? get onUnauthorized => client.onUnauthorized;
  set onUnauthorized(void Function()? value) => client.onUnauthorized = value;

  String _ws(int id, String path) => '/api/v1/workspaces/$id/$path';

  Future<SendOtpResult> sendOtp(String phone) {
    return client.post('/api/v1/auth/send-otp/', data: {'phone': phone}, parse: (data) => SendOtpResult.fromJson(asJson(data)));
  }

  Future<AuthUser> verifyOtp(String phone, String otp) async {
    final data = await client.post<Json>('/api/v1/auth/verify-otp/', data: {'phone': phone, 'otp': otp}, parse: asJson);
    final access = asString(data['access']);
    final refresh = asString(data['refresh']);
    await client.tokens.save(access, refresh);
    return AuthUser.fromJson(asJson(data['user']));
  }

  Future<void> logout() async {
    final refresh = client.tokens.refresh;
    try {
      if (refresh != null && refresh.isNotEmpty) {
        await client.post('/api/v1/auth/logout/', auth: true, data: {'refresh': refresh});
      }
    } finally {
      await client.tokens.clear();
    }
  }

  Future<AuthUser> me() => client.get('/api/v1/auth/me/', auth: true, parse: (data) => AuthUser.fromJson(asJson(data)));

  Future<AuthUser> updateProfile({required String firstName, required String lastName, required String email}) {
    return client.patch(
      '/api/v1/auth/profile/',
      auth: true,
      data: {'first_name': firstName, 'last_name': lastName, 'email': email},
      parse: (data) => AuthUser.fromJson(asJson(data)),
    );
  }

  Future<AuthUser> uploadAvatar(String path, String filename) async {
    final form = FormData.fromMap({
      'avatar': await MultipartFile.fromFile(path, filename: filename),
    });
    final data = await client.post<Json>('/api/v1/auth/profile/avatar/', auth: true, data: form, parse: asJson);
    return AuthUser.fromJson(asJson(data['user']));
  }

  Future<List<Workspace>> workspaces() {
    return client.get('/api/v1/workspaces/', auth: true, parse: (data) => [for (final item in asJsonList(data)) Workspace.fromJson(item)]);
  }

  Future<Workspace> createWorkspace(String name) {
    return client.post('/api/v1/workspaces/', auth: true, data: {'name': name}, parse: (data) => Workspace.fromJson(asJson(data)));
  }

  Future<Workspace> updateWorkspace(int id, Json data) {
    return client.patch('/api/v1/workspaces/$id/', auth: true, data: data, parse: (body) => Workspace.fromJson(asJson(body)));
  }

  Future<List<WorkspaceMember>> members(int id) {
    return client.get(_ws(id, 'members/'), auth: true, parse: (data) => [for (final item in asJsonList(data)) WorkspaceMember.fromJson(item)]);
  }

  Future<WorkspaceMember> addMember(int id, String phone, String role) {
    return client.post(
      _ws(id, 'members/'),
      auth: true,
      data: {'phone_number': phone, 'role': role},
      parse: (data) => WorkspaceMember.fromJson(asJson(data)),
    );
  }

  Future<void> deleteInstagramAccount(int id, int accountId) {
    return client.delete(_ws(id, 'instagram/accounts/$accountId/'), auth: true);
  }

  Future<List<InstagramAccount>> instagramAccounts(int id) {
    return client.get(
      _ws(id, 'instagram/accounts/'),
      auth: true,
      parse: (data) => [for (final item in asJsonList(data)) InstagramAccount.fromJson(item)],
    );
  }

  Future<String> startInstagramOAuth(int id) async {
    final data = await client.post<Json>(_ws(id, 'instagram/oauth/start/'), auth: true, parse: asJson);
    return asString(data['authorization_url']);
  }

  Future<InstagramAccessRequest?> accessRequest(int id) async {
    try {
      return await client.get(
        _ws(id, 'instagram/access-request/'),
        auth: true,
        parse: (data) => InstagramAccessRequest.fromJson(asJson(data)),
      );
    } on ApiException catch (error) {
      if (error.status == 404) return null;
      rethrow;
    }
  }

  Future<InstagramAccessRequest> submitAccessRequest(int id, String username) {
    return client.post(
      _ws(id, 'instagram/access-request/'),
      auth: true,
      data: {'username': username},
      parse: (data) => InstagramAccessRequest.fromJson(asJson(data)),
    );
  }

  Future<InstagramAccessRequest> confirmFacebook(int id) {
    return client.post(
      _ws(id, 'instagram/access-request/confirm-facebook/'),
      auth: true,
      parse: (data) => InstagramAccessRequest.fromJson(asJson(data)),
    );
  }

  Future<BusinessInfo> business(int id) {
    return client.get(_ws(id, 'knowledge/business/'), auth: true, parse: (data) => BusinessInfo.fromJson(asJson(data)));
  }

  Future<BusinessInfo> updateBusiness(int id, Json data) {
    return client.patch(_ws(id, 'knowledge/business/'), auth: true, data: data, parse: (body) => BusinessInfo.fromJson(asJson(body)));
  }

  Future<AiRules> rules(int id) {
    return client.get(_ws(id, 'knowledge/rules/'), auth: true, parse: (data) => AiRules.fromJson(asJson(data)));
  }

  Future<AiRules> updateRules(int id, Json data) {
    return client.patch(_ws(id, 'knowledge/rules/'), auth: true, data: data, parse: (body) => AiRules.fromJson(asJson(body)));
  }

  Future<List<Faq>> faqs(int id) {
    return client.get(_ws(id, 'faqs/'), auth: true, parse: (data) => [for (final item in asJsonList(data)) Faq.fromJson(item)]);
  }

  Future<Faq> saveFaq(int id, {int? faqId, required String question, required String answer}) {
    final path = faqId == null ? _ws(id, 'faqs/') : _ws(id, 'faqs/$faqId/');
    final payload = {'question': question, 'answer': answer};
    if (faqId == null) {
      return client.post(path, auth: true, data: payload, parse: (data) => Faq.fromJson(asJson(data)));
    }
    return client.patch(path, auth: true, data: payload, parse: (data) => Faq.fromJson(asJson(data)));
  }

  Future<void> deleteFaq(int id, int faqId) => client.delete(_ws(id, 'faqs/$faqId/'), auth: true);

  Future<List<Customer>> customers(int id, {String? status, String? search}) {
    final query = <String, String>{
      if (status != null && status.isNotEmpty && status != 'all') 'status': status,
      if (search != null && search.isNotEmpty) 'search': search,
    };
    return client.get(
      Uri(path: _ws(id, 'customers/'), queryParameters: query).toString(),
      auth: true,
      parse: (data) => [for (final item in asJsonList(data)) Customer.fromJson(item)],
    );
  }

  Future<Customer> customer(int id, int customerId) {
    return client.get(_ws(id, 'customers/$customerId/'), auth: true, parse: (data) => Customer.fromJson(asJson(data)));
  }

  Future<Customer> saveCustomer(int id, Json data, {int? customerId}) {
    final path = customerId == null ? _ws(id, 'customers/') : _ws(id, 'customers/$customerId/');
    if (customerId == null) {
      return client.post(path, auth: true, data: data, parse: (body) => Customer.fromJson(asJson(body)));
    }
    return client.patch(path, auth: true, data: data, parse: (body) => Customer.fromJson(asJson(body)));
  }

  Future<void> deleteCustomer(int id, int customerId) => client.delete(_ws(id, 'customers/$customerId/'), auth: true);

  Future<List<SalesInvoice>> invoices(int id, {String? status, String? search}) {
    final query = <String, String>{
      if (status != null && status.isNotEmpty && status != 'all') 'status': status,
      if (search != null && search.isNotEmpty) 'search': search,
    };
    return client.get(
      Uri(path: _ws(id, 'invoices/'), queryParameters: query).toString(),
      auth: true,
      parse: (data) => [for (final item in asJsonList(data)) SalesInvoice.fromJson(item)],
    );
  }

  Future<SalesInvoiceSummary> invoiceSummary(int id) {
    return client.get(_ws(id, 'invoices/summary/'), auth: true, parse: (data) => SalesInvoiceSummary.fromJson(asJson(data)));
  }

  Future<SalesInvoice> invoice(int id, int invoiceId) {
    return client.get(_ws(id, 'invoices/$invoiceId/'), auth: true, parse: (data) => SalesInvoice.fromJson(asJson(data)));
  }

  Future<SalesInvoice> saveInvoice(int id, Json data, {int? invoiceId}) {
    final path = invoiceId == null ? _ws(id, 'invoices/') : _ws(id, 'invoices/$invoiceId/');
    if (invoiceId == null) {
      return client.post(path, auth: true, data: data, parse: (body) => SalesInvoice.fromJson(asJson(body)));
    }
    return client.patch(path, auth: true, data: data, parse: (body) => SalesInvoice.fromJson(asJson(body)));
  }

  Future<void> deleteInvoice(int id, int invoiceId) => client.delete(_ws(id, 'invoices/$invoiceId/'), auth: true);

  Future<SalesInvoice> issueInvoice(int id, int invoiceId) {
    return client.post(_ws(id, 'invoices/$invoiceId/issue/'), auth: true, parse: (data) => SalesInvoice.fromJson(asJson(data)));
  }

  Future<SalesInvoice> payInvoice(int id, int invoiceId, String method) {
    return client.post(
      _ws(id, 'invoices/$invoiceId/pay/'),
      auth: true,
      data: {'payment_method': method},
      parse: (data) => SalesInvoice.fromJson(asJson(data)),
    );
  }

  Future<SalesInvoice> cancelInvoice(int id, int invoiceId) {
    return client.post(_ws(id, 'invoices/$invoiceId/cancel/'), auth: true, parse: (data) => SalesInvoice.fromJson(asJson(data)));
  }

  Future<List<Product>> products(int id, {String? search}) {
    final query = <String, String>{if (search != null && search.isNotEmpty) 'search': search};
    return client.get(
      Uri(path: _ws(id, 'products/'), queryParameters: query).toString(),
      auth: true,
      parse: (data) => [for (final item in asJsonList(data)) Product.fromJson(item)],
    );
  }

  Future<Product> saveProduct(int id, Json data, {int? productId}) {
    final path = productId == null ? _ws(id, 'products/') : _ws(id, 'products/$productId/');
    if (productId == null) {
      return client.post(path, auth: true, data: data, parse: (body) => Product.fromJson(asJson(body)));
    }
    return client.patch(path, auth: true, data: data, parse: (body) => Product.fromJson(asJson(body)));
  }

  Future<void> deleteProduct(int id, int productId) => client.delete(_ws(id, 'products/$productId/'), auth: true);

  Future<PageResult<DirectChat>> directChats(int id, {int page = 1}) {
    return client.get(
      _ws(id, 'instagram/directs/chats/?page=$page&page_size=30'),
      auth: true,
      parse: (data) => PageResult.parse(data, DirectChat.fromJson),
    );
  }

  Future<PageResult<DirectMessage>> directMessages(int id, String chatId, {int page = 1}) {
    final encoded = Uri.encodeComponent(chatId);
    return client.get(
      _ws(id, 'instagram/directs/chats/$encoded/messages/?page=$page&page_size=50&order=asc'),
      auth: true,
      parse: (data) => PageResult.parse(data, DirectMessage.fromJson),
    );
  }

  Future<void> sendDirect(int id, String chatId, String text) async {
    await client.post(_ws(id, 'instagram/directs/send/'), auth: true, data: {'chat_id': chatId, 'text': text});
  }

  Future<PageResult<IgComment>> comments(int id, {int page = 1}) {
    return client.get(
      _ws(id, 'instagram/comments/?page=$page&page_size=30'),
      auth: true,
      parse: (data) => PageResult.parse(data, IgComment.fromJson),
    );
  }

  Future<void> replyComment(int id, {required String commentId, required String text, String? mediaId}) async {
    await client.post(
      _ws(id, 'instagram/comments/reply/'),
      auth: true,
      data: {
        'comment_id': commentId,
        'text': text,
        if (mediaId != null && mediaId.isNotEmpty) 'media_id': mediaId,
      },
    );
  }

  Future<List<AutomationFlow>> automations(int id, String triggerType) {
    return client.get(
      _ws(id, 'automations/?trigger_type=$triggerType'),
      auth: true,
      parse: (data) => [for (final item in asJsonList(data)) AutomationFlow.fromJson(item)],
    );
  }

  Future<AutomationFlow> saveAutomation(int id, Json data, {int? flowId}) {
    final path = flowId == null ? _ws(id, 'automations/') : _ws(id, 'automations/$flowId/');
    if (flowId == null) {
      return client.post(path, auth: true, data: data, parse: (body) => AutomationFlow.fromJson(asJson(body)));
    }
    return client.patch(path, auth: true, data: data, parse: (body) => AutomationFlow.fromJson(asJson(body)));
  }

  Future<void> deleteAutomation(int id, int flowId) => client.delete(_ws(id, 'automations/$flowId/'), auth: true);

  Future<AnalyticsOverview> analytics(int id) {
    return client.get(_ws(id, 'analytics/overview/'), auth: true, parse: (data) => AnalyticsOverview.fromJson(asJson(data)));
  }

  Future<List<Plan>> plans() {
    return client.get('/api/v1/plans/', parse: (data) => [for (final item in asJsonList(data)) Plan.fromJson(item)]);
  }

  Future<Subscription?> subscription(int id) async {
    try {
      return await client.get(_ws(id, 'billing/subscription/'), auth: true, parse: (data) => Subscription.fromJson(asJson(data)));
    } on ApiException catch (error) {
      if (error.status == 404) return null;
      rethrow;
    }
  }

  Future<UpgradePreview> previewUpgrade(int id, {required int planId, required String interval, String discount = '', String referral = ''}) {
    return client.post(
      _ws(id, 'billing/preview-upgrade/'),
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

  Future<String?> upgradePlan(
    int id, {
    required int planId,
    required String interval,
    required String paymentMethod,
    String discount = '',
    String referral = '',
  }) async {
    final data = await client.post<Json>(
      _ws(id, 'billing/upgrade/'),
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

  Future<CardInfo> cardInfo(int id) {
    return client.get(_ws(id, 'billing/card-to-card/'), auth: true, parse: (data) => CardInfo.fromJson(asJson(data)));
  }

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
    final data = await client.post<Json>(_ws(id, 'billing/upgrade/'), auth: true, data: form, parse: asJson);
    return asString(data['message']).isEmpty ? 'فیش شما دریافت شد و در حال بررسی است.' : asString(data['message']);
  }

  Future<List<PaymentRecord>> payments(int id) {
    return client.get(
      _ws(id, 'billing/payments/'),
      auth: true,
      parse: (data) => [for (final item in asJsonList(data)) PaymentRecord.fromJson(item)],
    );
  }

  Future<WalletInfo> wallet(int id) {
    return client.get(_ws(id, 'billing/wallet/'), auth: true, parse: (data) => WalletInfo.fromJson(asJson(data)));
  }

  Future<List<WalletTx>> walletTransactions(int id) {
    return client.get(
      _ws(id, 'billing/wallet/transactions/'),
      auth: true,
      parse: (data) => [for (final item in asJsonList(data)) WalletTx.fromJson(item)],
    );
  }

  Future<List<WalletPackage>> walletPackages(int id) {
    return client.get(
      _ws(id, 'billing/wallet/packages/'),
      auth: true,
      parse: (data) => [for (final item in asJsonList(data)) WalletPackage.fromJson(item)],
    );
  }

  Future<String> topUp(int id, {String? packageId, int? amount}) async {
    final data = await client.post<Json>(
      _ws(id, 'billing/wallet/top-up/'),
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
    final data = await client.post<Json>(_ws(id, 'billing/wallet/top-up/'), auth: true, data: form, parse: asJson);
    return asString(data['message']).isEmpty ? 'فیش شما دریافت شد و در حال بررسی است.' : asString(data['message']);
  }

  Future<List<Ticket>> tickets(int id, {String? status, String? priority, String? search}) {
    final query = <String, String>{
      if (status != null && status.isNotEmpty && status != 'all') 'status': status,
      if (priority != null && priority.isNotEmpty && priority != 'all') 'priority': priority,
      if (search != null && search.isNotEmpty) 'search': search,
    };
    return client.get(
      Uri(path: _ws(id, 'tickets/'), queryParameters: query).toString(),
      auth: true,
      parse: (data) => [for (final item in asJsonList(data)) Ticket.fromJson(item)],
    );
  }

  Future<Ticket> ticket(int id, int ticketId) {
    return client.get(_ws(id, 'tickets/$ticketId/'), auth: true, parse: (data) => Ticket.fromJson(asJson(data)));
  }

  Future<Ticket> saveTicket(int id, Json data, {int? ticketId}) {
    final path = ticketId == null ? _ws(id, 'tickets/') : _ws(id, 'tickets/$ticketId/');
    if (ticketId == null) {
      return client.post(path, auth: true, data: data, parse: (body) => Ticket.fromJson(asJson(body)));
    }
    return client.patch(path, auth: true, data: data, parse: (body) => Ticket.fromJson(asJson(body)));
  }

  Future<void> deleteTicket(int id, int ticketId) => client.delete(_ws(id, 'tickets/$ticketId/'), auth: true);

  Future<void> addTicketComment(int id, int ticketId, String content) async {
    await client.post(_ws(id, 'tickets/$ticketId/comments/'), auth: true, data: {'content': content});
  }

  Future<List<MenuTutorial>> tutorials() {
    return client.get(
      '/api/v1/menu-tutorials/',
      auth: true,
      parse: (data) => [for (final item in asJsonList(data)) MenuTutorial.fromJson(item)],
    );
  }
}
