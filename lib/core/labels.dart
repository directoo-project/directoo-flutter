const customerStatusLabels = {
  'all': 'همه',
  'hot': 'داغ',
  'warm': 'گرم',
  'cold': 'سرد',
  'vip': 'ویژه',
  'purchased': 'خریدار',
};

const invoiceStatusLabels = {
  'all': 'همه',
  'draft': 'پیش‌نویس',
  'issued': 'صادر شده',
  'paid': 'پرداخت شده',
  'cancelled': 'لغو شده',
};

const paymentMethodLabels = {
  'cash': 'نقدی',
  'card': 'کارت',
  'transfer': 'کارت به کارت / پایا',
  'online': 'آنلاین',
  'other': 'سایر',
};

const automationStatusLabels = {
  'active': 'فعال',
  'inactive': 'غیرفعال',
  'draft': 'پیش‌نویس',
};

const productStatusLabels = {
  'active': 'فعال',
  'inactive': 'غیرفعال',
  'out_of_stock': 'ناموجود',
};

const roleLabels = {
  'owner': 'مالک',
  'admin': 'مدیر',
  'manager': 'سرپرست',
  'agent': 'اپراتور',
  'viewer': 'بیننده',
};

const ticketStatusLabels = {
  'all': 'همه',
  'open': 'باز',
  'in_progress': 'در حال بررسی',
  'resolved': 'حل‌شده',
  'closed': 'بسته',
};

const ticketPriorityLabels = {
  'all': 'همه',
  'low': 'کم',
  'medium': 'متوسط',
  'high': 'بالا',
  'urgent': 'فوری',
};

const inboxCategoryLabels = {
  'all': 'همه',
  'unread': 'خوانده نشده',
  'lead': 'لید',
  'vip': 'ویژه',
};

const industryLabels = {
  'fashion': 'پوشاک و مد',
  'beauty': 'زیبایی و آرایشی',
  'food': 'غذا و رستوران',
  'ecommerce': 'فروشگاه آنلاین',
  'education': 'آموزش',
  'health': 'سلامت و پزشکی',
  'real_estate': 'املاک',
  'services': 'خدمات',
  'technology': 'فناوری',
  'sports': 'ورزش و تناسب‌اندام',
  'jewelry': 'طلا و جواهر',
  'home': 'منزل و دکوراسیون',
  'automotive': 'خودرو',
  'travel': 'گردشگری',
  'finance': 'مالی و بیمه',
  'other': 'سایر',
};

const walletTxTypeLabels = {
  'deposit': 'شارژ',
  'withdraw': 'برداشت',
  'usage': 'مصرف',
  'refund': 'بازگشت',
  'bonus': 'بونوس',
};

const walletTxStatusLabels = {
  'pending': 'در انتظار',
  'completed': 'انجام شده',
  'failed': 'ناموفق',
  'cancelled': 'لغو شده',
};

const commentMatchLabels = {
  'equals': 'برابر',
  'contains': 'شامل',
  'starts_with': 'شروع با',
  'any': 'هر کامنت',
};

const commentSourceLabels = {
  'post': 'پست',
  'story': 'استوری',
  'live': 'لایو',
};

const replyChannelLabels = {
  'direct': 'دایرکت',
  'comment': 'کامنت',
  'both': 'دایرکت و کامنت',
};

String faLabel(Map<String, String> labels, String? key) {
  if (key == null || key.isEmpty) return '—';
  return labels[key] ?? key;
}
