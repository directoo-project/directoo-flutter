import '../../core/json.dart';

class AuthUser {
  const AuthUser({
    required this.id,
    required this.phoneNumber,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.avatarUrl,
    required this.profileIncomplete,
  });

  final int id;
  final String phoneNumber;
  final String firstName;
  final String lastName;
  final String email;
  final String avatarUrl;
  final bool profileIncomplete;

  String get displayName {
    final name = '$firstName $lastName'.trim();
    return name.isEmpty ? phoneNumber : name;
  }

  factory AuthUser.fromJson(Json json) => AuthUser(
        id: asInt(json['id']),
        phoneNumber: asString(json['phone_number']),
        firstName: asString(json['first_name']),
        lastName: asString(json['last_name']),
        email: asString(json['email']),
        avatarUrl: asString(json['avatar_url']),
        profileIncomplete: asBool(json['profile_incomplete']),
      );
}

class SendOtpResult {
  const SendOtpResult({required this.maskedPhone, required this.expiresIn, required this.message});
  final String maskedPhone;
  final int expiresIn;
  final String message;

  factory SendOtpResult.fromJson(Json json) => SendOtpResult(
        maskedPhone: asString(json['masked_phone']),
        expiresIn: asInt(json['expires_in'], fallback: 120),
        message: asString(json['message']),
      );
}

class WorkspaceFeatures {
  const WorkspaceFeatures(this.flags);

  final Map<String, bool> flags;

  bool enabled(String? key) {
    if (key == null) return true;
    return flags[key] != false;
  }

  factory WorkspaceFeatures.fromJson(dynamic value) {
    const keys = [
      'inbox_enabled',
      'customers_enabled',
      'tickets_enabled',
      'products_enabled',
      'storefront_enabled',
      'knowledge_enabled',
      'automation_enabled',
      'smart_reply_enabled',
      'vitrin_enabled',
      'followup_enabled',
      'icebreaker_enabled',
      'analytics_enabled',
      'team_enabled',
    ];
    final json = asJson(value);
    return WorkspaceFeatures({
      for (final key in keys) key: json.containsKey(key) ? json[key] != false : true,
    });
  }
}

class Workspace {
  const Workspace({
    required this.id,
    required this.name,
    required this.slug,
    required this.timezone,
    required this.language,
    required this.storefrontActive,
    required this.role,
    required this.features,
    required this.planTier,
    required this.planName,
    required this.subscriptionStatus,
    required this.hasPaidSubscription,
  });

  final int id;
  final String name;
  final String slug;
  final String timezone;
  final String language;
  final bool storefrontActive;
  final String? role;
  final WorkspaceFeatures features;
  final String planTier;
  final String planName;
  final String? subscriptionStatus;
  final bool? hasPaidSubscription;

  bool get needsSubscription {
    if (hasPaidSubscription == null) return false;
    if (hasPaidSubscription == true) return false;
    if (planTier == 'free' && subscriptionStatus == 'active') return false;
    return true;
  }

  factory Workspace.fromJson(Json json) => Workspace(
        id: asInt(json['id']),
        name: asString(json['name']),
        slug: asString(json['slug']),
        timezone: asString(json['timezone']),
        language: asString(json['language']),
        storefrontActive: json['storefront_active'] != false,
        role: json['role'] == null ? null : asString(json['role']),
        features: WorkspaceFeatures.fromJson(json['features']),
        planTier: asString(json['plan_tier']),
        planName: asString(json['plan_name']),
        subscriptionStatus: json['subscription_status'] == null ? null : asString(json['subscription_status']),
        hasPaidSubscription: json.containsKey('has_paid_subscription') ? asBool(json['has_paid_subscription']) : null,
      );
}

class WorkspaceMember {
  const WorkspaceMember({
    required this.id,
    required this.userName,
    required this.userPhone,
    required this.role,
    required this.joinedAt,
  });

  final int id;
  final String userName;
  final String userPhone;
  final String role;
  final String? joinedAt;

  factory WorkspaceMember.fromJson(Json json) => WorkspaceMember(
        id: asInt(json['id']),
        userName: asString(json['user_name']),
        userPhone: asString(json['user_phone']),
        role: asString(json['role']),
        joinedAt: json['joined_at'] == null ? null : asString(json['joined_at']),
      );
}

class InstagramAccount {
  const InstagramAccount({required this.id, required this.username, required this.name, required this.status});
  final int id;
  final String username;
  final String name;
  final String status;

  factory InstagramAccount.fromJson(Json json) => InstagramAccount(
        id: asInt(json['id']),
        username: asString(json['username']),
        name: asString(json['name']),
        status: asString(json['status']),
      );
}

class InstagramAccessRequest {
  const InstagramAccessRequest({
    required this.id,
    required this.username,
    required this.status,
    required this.facebookLink,
  });

  final int id;
  final String username;
  final String status;
  final String facebookLink;

  bool get reviewing => status == 'pending' || status == 'awaiting_facebook';

  factory InstagramAccessRequest.fromJson(Json json) => InstagramAccessRequest(
        id: asInt(json['id']),
        username: asString(json['username']),
        status: asString(json['status']),
        facebookLink: asString(json['facebook_link']),
      );
}

class BusinessInfo {
  const BusinessInfo({
    required this.businessName,
    required this.industry,
    required this.about,
    required this.phone,
    required this.address,
    required this.workingHours,
  });

  final String businessName;
  final String industry;
  final String about;
  final String phone;
  final String address;
  final String workingHours;

  factory BusinessInfo.fromJson(Json json) => BusinessInfo(
        businessName: asString(json['business_name']),
        industry: asString(json['industry']),
        about: asString(json['about']),
        phone: asString(json['phone']),
        address: asString(json['address']),
        workingHours: asString(json['working_hours']),
      );

  Json toJson() => {
        'business_name': businessName,
        'industry': industry,
        'about': about,
        'phone': phone,
        'address': address,
        'working_hours': workingHours,
      };
}

class AiRules {
  const AiRules({required this.allowedTopics, required this.forbiddenTopics});
  final String allowedTopics;
  final String forbiddenTopics;

  factory AiRules.fromJson(Json json) => AiRules(
        allowedTopics: asString(json['allowed_topics']),
        forbiddenTopics: asString(json['forbidden_topics']),
      );
}

class Faq {
  const Faq({required this.id, required this.question, required this.answer});
  final int id;
  final String question;
  final String answer;

  factory Faq.fromJson(Json json) => Faq(
        id: asInt(json['id']),
        question: asString(json['question']),
        answer: asString(json['answer']),
      );
}

class Customer {
  const Customer({
    required this.id,
    required this.name,
    required this.phone,
    required this.instagramUsername,
    required this.email,
    required this.status,
    required this.leadScore,
    required this.tags,
    required this.notes,
    required this.lastInteractionAt,
    required this.invoiceCount,
    required this.unpaidTotal,
    required this.createdAt,
  });

  final int id;
  final String name;
  final String phone;
  final String instagramUsername;
  final String email;
  final String status;
  final int leadScore;
  final List<String> tags;
  final String notes;
  final String? lastInteractionAt;
  final int invoiceCount;
  final double unpaidTotal;
  final String createdAt;

  factory Customer.fromJson(Json json) => Customer(
        id: asInt(json['id']),
        name: asString(json['name']),
        phone: asString(json['phone']),
        instagramUsername: asString(json['instagram_username']),
        email: asString(json['email']),
        status: asString(json['status']),
        leadScore: asInt(json['lead_score']),
        tags: asStringList(json['tags']),
        notes: asString(json['notes']),
        lastInteractionAt: json['last_interaction_at'] == null ? null : asString(json['last_interaction_at']),
        invoiceCount: asInt(json['invoice_count']),
        unpaidTotal: asDouble(json['unpaid_total']),
        createdAt: asString(json['created_at']),
      );
}

class SalesInvoiceLine {
  const SalesInvoiceLine({
    required this.productName,
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
  });

  final String productName;
  final String description;
  final int quantity;
  final double unitPrice;
  final double lineTotal;

  factory SalesInvoiceLine.fromJson(Json json) => SalesInvoiceLine(
        productName: asString(json['product_name']),
        description: asString(json['description']),
        quantity: asInt(json['quantity']),
        unitPrice: asDouble(json['unit_price']),
        lineTotal: asDouble(json['line_total']),
      );
}

class SalesInvoice {
  const SalesInvoice({
    required this.id,
    required this.number,
    required this.status,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.issueDate,
    required this.dueDate,
    required this.notes,
    required this.subtotal,
    required this.discountAmount,
    required this.taxPercent,
    required this.taxAmount,
    required this.total,
    required this.paymentMethod,
    required this.itemCount,
    required this.items,
    required this.createdAt,
  });

  final int id;
  final String number;
  final String status;
  final int? customerId;
  final String customerName;
  final String customerPhone;
  final String? issueDate;
  final String? dueDate;
  final String notes;
  final double subtotal;
  final double discountAmount;
  final double taxPercent;
  final double taxAmount;
  final double total;
  final String paymentMethod;
  final int itemCount;
  final List<SalesInvoiceLine> items;
  final String createdAt;

  factory SalesInvoice.fromJson(Json json) => SalesInvoice(
        id: asInt(json['id']),
        number: asString(json['number']),
        status: asString(json['status']),
        customerId: json['customer'] == null ? null : asInt(json['customer']),
        customerName: () {
          final display = asString(json['display_customer_name']);
          return display.isEmpty ? asString(json['customer_name']) : display;
        }(),
        customerPhone: asString(json['customer_phone']),
        issueDate: json['issue_date'] == null ? null : asString(json['issue_date']),
        dueDate: json['due_date'] == null ? null : asString(json['due_date']),
        notes: asString(json['notes']),
        subtotal: asDouble(json['subtotal']),
        discountAmount: asDouble(json['discount_amount']),
        taxPercent: asDouble(json['tax_percent']),
        taxAmount: asDouble(json['tax_amount']),
        total: asDouble(json['total']),
        paymentMethod: asString(json['payment_method']),
        itemCount: asInt(json['item_count']),
        items: [for (final item in asJsonList(json['items'])) SalesInvoiceLine.fromJson(item)],
        createdAt: asString(json['created_at']),
      );
}

class SalesInvoiceSummary {
  const SalesInvoiceSummary({
    required this.count,
    required this.draftCount,
    required this.issuedCount,
    required this.paidCount,
    required this.paidTotal,
    required this.unpaidTotal,
  });

  final int count;
  final int draftCount;
  final int issuedCount;
  final int paidCount;
  final double paidTotal;
  final double unpaidTotal;

  factory SalesInvoiceSummary.fromJson(Json json) => SalesInvoiceSummary(
        count: asInt(json['count']),
        draftCount: asInt(json['draft_count']),
        issuedCount: asInt(json['issued_count']),
        paidCount: asInt(json['paid_count']),
        paidTotal: asDouble(json['paid_total']),
        unpaidTotal: asDouble(json['unpaid_total']),
      );
}

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.discount,
    required this.finalPrice,
    required this.imageUrl,
    required this.sku,
    required this.inventory,
    required this.productUrl,
    required this.status,
  });

  final int id;
  final String name;
  final String description;
  final double price;
  final double discount;
  final double finalPrice;
  final String imageUrl;
  final String sku;
  final int inventory;
  final String productUrl;
  final String status;

  factory Product.fromJson(Json json) => Product(
        id: asInt(json['id']),
        name: asString(json['name']),
        description: asString(json['description']),
        price: asDouble(json['price']),
        discount: asDouble(json['discount']),
        finalPrice: asDouble(json['final_price']),
        imageUrl: asString(json['image_url']),
        sku: asString(json['sku']),
        inventory: asInt(json['inventory']),
        productUrl: asString(json['product_url']),
        status: asString(json['status']),
      );
}

class TicketComment {
  const TicketComment({required this.id, required this.authorName, required this.content, required this.createdAt});
  final int id;
  final String authorName;
  final String content;
  final String createdAt;

  factory TicketComment.fromJson(Json json) => TicketComment(
        id: asInt(json['id']),
        authorName: asString(json['author_name']),
        content: asString(json['content']),
        createdAt: asString(json['created_at']),
      );
}

class Ticket {
  const Ticket({
    required this.id,
    required this.subject,
    required this.description,
    required this.status,
    required this.priority,
    required this.customerName,
    required this.assigneeName,
    required this.commentCount,
    required this.comments,
    required this.updatedAt,
  });

  final int id;
  final String subject;
  final String description;
  final String status;
  final String priority;
  final String customerName;
  final String assigneeName;
  final int commentCount;
  final List<TicketComment> comments;
  final String updatedAt;

  factory Ticket.fromJson(Json json) => Ticket(
        id: asInt(json['id']),
        subject: asString(json['subject']),
        description: asString(json['description']),
        status: asString(json['status']),
        priority: asString(json['priority']),
        customerName: asString(json['customer_name']),
        assigneeName: asString(json['assignee_name']),
        commentCount: asInt(json['comment_count']),
        comments: [for (final item in asJsonList(json['comments'])) TicketComment.fromJson(item)],
        updatedAt: asString(json['updated_at']),
      );
}

class DirectChat {
  const DirectChat({required this.chatId, required this.title, required this.username, required this.preview, required this.time});
  final String chatId;
  final String title;
  final String username;
  final String preview;
  final String time;

  factory DirectChat.fromJson(Json json) {
    final peer = asJson(json['peer']);
    final last = asJson(json['last_message']);
    final name = asString(peer['name']);
    final username = asString(peer['username']);
    return DirectChat(
      chatId: asString(json['chat_id']),
      title: name.isNotEmpty ? name : (username.isNotEmpty ? '@$username' : 'گفتگو'),
      username: username,
      preview: asString(last['text']).isEmpty ? 'پیام رسانه‌ای' : asString(last['text']),
      time: asString(last['datetime'].toString().isEmpty ? last['date'] : last['datetime']),
    );
  }
}

class DirectMessage {
  const DirectMessage({
    required this.id,
    required this.direction,
    required this.text,
    required this.imageUrl,
    required this.createdAt,
  });

  final int id;
  final String direction;
  final String text;
  final String imageUrl;
  final String createdAt;

  bool get outbound => direction == 'outbound' || direction == 'echo';

  factory DirectMessage.fromJson(Json json) => DirectMessage(
        id: asInt(json['id']),
        direction: asString(json['direction']),
        text: asString(json['text']),
        imageUrl: asString(json['image_url']),
        createdAt: asString(json['datetime'].toString().isEmpty ? json['created_at'] : json['datetime']),
      );
}

class IgComment {
  const IgComment({
    required this.commentId,
    required this.username,
    required this.text,
    required this.mediaId,
    required this.createdAt,
    required this.direction,
  });

  final String commentId;
  final String username;
  final String text;
  final String mediaId;
  final String createdAt;
  final String direction;

  factory IgComment.fromJson(Json json) => IgComment(
        commentId: asString(json['comment_id'].toString().isEmpty ? json['id'] : json['comment_id']),
        username: asString(json['username']),
        text: asString(json['text']),
        mediaId: asString(json['media_id']),
        createdAt: asString(json['datetime'].toString().isEmpty ? json['created_at'] : json['datetime']),
        direction: asString(json['direction']),
      );
}

class PageResult<T> {
  const PageResult({required this.items, required this.page, required this.total, required this.hasNext});
  final List<T> items;
  final int page;
  final int total;
  final bool hasNext;

  factory PageResult.parse(dynamic data, T Function(Json json) parse) {
    if (data is List) {
      final items = [for (final item in data) parse(asJson(item))];
      return PageResult(items: items, page: 1, total: items.length, hasNext: false);
    }
    final json = asJson(data);
    final raw = json['items'] ?? json['results'] ?? const [];
    final items = raw is List ? [for (final item in raw) parse(asJson(item))] : <T>[];
    return PageResult(
      items: items,
      page: asInt(json['page'], fallback: 1),
      total: asInt(json['total'], fallback: items.length),
      hasNext: asBool(json['has_next']),
    );
  }
}

class AutomationFlow {
  const AutomationFlow({
    required this.id,
    required this.name,
    required this.description,
    required this.status,
    required this.trigger,
    required this.steps,
  });

  final int id;
  final String name;
  final String description;
  final String status;
  final Json trigger;
  final List<Json> steps;

  factory AutomationFlow.fromJson(Json json) => AutomationFlow(
        id: asInt(json['id']),
        name: asString(json['name']),
        description: asString(json['description']),
        status: asString(json['status']),
        trigger: asJson(json['trigger']),
        steps: [for (final step in asJsonList(json['steps'])) step],
      );
}

class ChartPoint {
  const ChartPoint({required this.label, required this.value});
  final String label;
  final int value;
}

class AnalyticsOverview {
  const AnalyticsOverview({
    required this.conversations,
    required this.leads,
    required this.sales,
    required this.revenue,
    required this.conversionRate,
    required this.aiResolutionRate,
    required this.activeProducts,
    required this.conversationsWeekChange,
    required this.leadsWeekChange,
    required this.conversationGrowth,
    required this.customerByStatus,
    required this.messagesBySender,
  });

  final int conversations;
  final int leads;
  final int sales;
  final double revenue;
  final double conversionRate;
  final double aiResolutionRate;
  final int activeProducts;
  final int? conversationsWeekChange;
  final int? leadsWeekChange;
  final List<ChartPoint> conversationGrowth;
  final List<ChartPoint> customerByStatus;
  final List<ChartPoint> messagesBySender;

  factory AnalyticsOverview.fromJson(Json json) {
    final overview = asJson(json['overview']);
    final charts = asJson(json['charts']);
    return AnalyticsOverview(
      conversations: asInt(overview['conversations']),
      leads: asInt(overview['leads']),
      sales: asInt(overview['sales']),
      revenue: asDouble(overview['revenue']),
      conversionRate: asDouble(overview['conversion_rate']),
      aiResolutionRate: asDouble(overview['ai_resolution_rate']),
      activeProducts: asInt(overview['active_products']),
      conversationsWeekChange: overview['conversations_week_change'] == null ? null : asInt(overview['conversations_week_change']),
      leadsWeekChange: overview['leads_week_change'] == null ? null : asInt(overview['leads_week_change']),
      conversationGrowth: [
        for (final row in asJsonList(charts['conversation_growth']))
          ChartPoint(label: asString(row['date']), value: asInt(row['count'])),
      ],
      customerByStatus: [
        for (final row in asJsonList(charts['customer_by_status']))
          ChartPoint(label: asString(row['status']), value: asInt(row['count'])),
      ],
      messagesBySender: [
        for (final row in asJsonList(charts['messages_by_sender']))
          ChartPoint(label: asString(row['sender']), value: asInt(row['count'])),
      ],
    );
  }
}

class Plan {
  const Plan({
    required this.id,
    required this.tier,
    required this.name,
    required this.priceMonthly,
    required this.priceYearly,
    required this.discountMonthly,
    required this.discountYearly,
    required this.durationDaysMonthly,
    required this.durationDaysYearly,
    required this.maxConversations,
    required this.features,
  });

  final int id;
  final String tier;
  final String name;
  final double priceMonthly;
  final double priceYearly;
  final double discountMonthly;
  final double discountYearly;
  final int durationDaysMonthly;
  final int? durationDaysYearly;
  final int maxConversations;
  final List<String> features;

  double listPrice(String interval) => interval == 'yearly' ? priceYearly : priceMonthly;

  double discountPercent(String interval) => interval == 'yearly' ? discountYearly : discountMonthly;

  double finalPrice(String interval) {
    final price = listPrice(interval);
    final discount = discountPercent(interval);
    if (discount <= 0) return price;
    return (price * (100 - discount) / 100).roundToDouble();
  }

  int periodDays(String interval) {
    if (interval == 'yearly') return durationDaysYearly ?? 0;
    return durationDaysMonthly > 0 ? durationDaysMonthly : 30;
  }

  bool offersInterval(String interval) => periodDays(interval) > 0;

  factory Plan.fromJson(Json json) => Plan(
        id: asInt(json['id']),
        tier: asString(json['tier']),
        name: asString(json['name']),
        priceMonthly: asDouble(json['price_monthly']),
        priceYearly: asDouble(json['price_yearly']),
        discountMonthly: asDouble(json['discount_percent_monthly']),
        discountYearly: asDouble(json['discount_percent_yearly']),
        durationDaysMonthly: asInt(json['duration_days_monthly'], fallback: 30),
        durationDaysYearly: json['duration_days_yearly'] == null ? null : asInt(json['duration_days_yearly']),
        maxConversations: asInt(json['max_conversations']),
        features: asStringList(json['features']),
      );
}

class Subscription {
  const Subscription({
    required this.id,
    required this.plan,
    required this.status,
    required this.billingInterval,
    required this.periodStart,
    required this.periodEnd,
    required this.usageConversations,
  });

  final int id;
  final Plan plan;
  final String status;
  final String billingInterval;
  final String? periodStart;
  final String? periodEnd;
  final int usageConversations;

  factory Subscription.fromJson(Json json) => Subscription(
        id: asInt(json['id']),
        plan: Plan.fromJson(asJson(json['plan'])),
        status: asString(json['status']),
        billingInterval: asString(json['billing_interval']).isEmpty ? 'monthly' : asString(json['billing_interval']),
        periodStart: json['current_period_start'] == null ? null : asString(json['current_period_start']),
        periodEnd: json['current_period_end'] == null ? null : asString(json['current_period_end']),
        usageConversations: asInt(json['usage_conversations']),
      );
}

class UpgradePreview {
  const UpgradePreview({required this.finalAmount, required this.discountAmount, required this.listAmount});
  final double finalAmount;
  final double discountAmount;
  final double listAmount;

  factory UpgradePreview.fromJson(Json json) => UpgradePreview(
        finalAmount: asDouble(json['final_amount']),
        discountAmount: asDouble(json['discount_amount']),
        listAmount: asDouble(json['list_amount']),
      );
}

class CardInfo {
  const CardInfo({required this.number, required this.holderName, required this.bankName});
  final String number;
  final String holderName;
  final String bankName;

  factory CardInfo.fromJson(Json json) => CardInfo(
        number: asString(json['number']),
        holderName: asString(json['holder_name']),
        bankName: asString(json['bank_name']),
      );
}

class PaymentRecord {
  const PaymentRecord({
    required this.id,
    required this.type,
    required this.method,
    required this.status,
    required this.amount,
    required this.description,
    required this.createdAt,
  });

  final int id;
  final String type;
  final String method;
  final String status;
  final double amount;
  final String description;
  final String createdAt;

  factory PaymentRecord.fromJson(Json json) => PaymentRecord(
        id: asInt(json['id']),
        type: asString(json['type']),
        method: asString(json['method']),
        status: asString(json['status']),
        amount: asDouble(json['amount']),
        description: asString(json['description']),
        createdAt: asString(json['created_at']),
      );
}

class WalletInfo {
  const WalletInfo({required this.balance, required this.updatedAt});
  final double balance;
  final String updatedAt;

  factory WalletInfo.fromJson(Json json) => WalletInfo(
        balance: asDouble(json['balance']),
        updatedAt: asString(json['updated_at']),
      );
}

class WalletTx {
  const WalletTx({
    required this.id,
    required this.type,
    required this.status,
    required this.amount,
    required this.balanceAfter,
    required this.description,
    required this.createdAt,
  });

  final int id;
  final String type;
  final String status;
  final double amount;
  final double balanceAfter;
  final String description;
  final String createdAt;

  factory WalletTx.fromJson(Json json) => WalletTx(
        id: asInt(json['id']),
        type: asString(json['type']),
        status: asString(json['status']),
        amount: asDouble(json['amount']),
        balanceAfter: asDouble(json['balance_after']),
        description: asString(json['description']),
        createdAt: asString(json['created_at']),
      );
}

class WalletPackage {
  const WalletPackage({required this.id, required this.amount, required this.bonus, required this.label});
  final String id;
  final double amount;
  final double bonus;
  final String label;

  factory WalletPackage.fromJson(Json json) => WalletPackage(
        id: asString(json['id']),
        amount: asDouble(json['amount']),
        bonus: asDouble(json['bonus']),
        label: asString(json['label']),
      );
}

class MenuTutorial {
  const MenuTutorial({
    required this.key,
    required this.title,
    required this.description,
    required this.linkUrl,
    required this.linkLabel,
    required this.isActive,
  });

  final String key;
  final String title;
  final String description;
  final String linkUrl;
  final String linkLabel;
  final bool isActive;

  factory MenuTutorial.fromJson(Json json) => MenuTutorial(
        key: asString(json['key']),
        title: asString(json['title']),
        description: asString(json['description']),
        linkUrl: asString(json['link_url']),
        linkLabel: asString(json['link_label']),
        isActive: json['is_active'] != false,
      );
}
