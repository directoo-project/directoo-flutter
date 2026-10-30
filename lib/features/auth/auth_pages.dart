import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api_exception.dart';
import '../../core/format.dart';
import '../../core/labels.dart';
import '../../data/directoo_api.dart';
import '../../models/models.dart';
import '../../state/session.dart';
import '../../theme/app_theme.dart';
import '../../widgets/brand.dart';
import '../../widgets/ui.dart';
import 'auth_scaffold.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _phone = TextEditingController();
  var _loading = false;
  String? _error;

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final phone = normalizePhone(_phone.text);
    if (!isIranMobile(phone)) {
      setState(() => _error = 'شماره موبایل معتبر نیست.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await context.read<SessionController>().sendOtp(phone);
      if (mounted) context.go('/otp');
    } catch (error) {
      if (mounted) setState(() => _error = errorText(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dt = context.dt;
    return AuthScaffold(
      child: AuthCard(
        title: 'ورود',
        titleWidget: Text.rich(
          TextSpan(
            style: TextStyle(fontSize: 30, height: 1.4, fontWeight: FontWeight.w800, color: dt.text),
            children: const [
              TextSpan(text: 'ورود به '),
              TextSpan(text: 'Directoo'),
            ],
          ),
        ),
        description: 'شماره موبایل خود را وارد کنید',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AuthLabel('شماره موبایل'),
            AuthField(
              controller: _phone,
              hint: '۰۹۱۲۱۲۳۴۵۶۷',
              icon: Icons.smartphone_outlined,
              keyboardType: TextInputType.phone,
              textDirection: TextDirection.ltr,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+]'))],
            ),
            const SizedBox(height: 8),
            Text('برای ورود یا ساخت حساب، کد تأیید به این شماره پیامک می‌شود.', style: TextStyle(color: dt.textMuted, fontSize: 13, height: 1.6)),
            if (_error != null) ...[
              const SizedBox(height: 16),
              AuthError(_error!),
            ],
            const SizedBox(height: 20),
            AuthPrimaryButton(onPressed: _loading ? null : _submit, label: _loading ? 'در حال ارسال...' : 'دریافت کد تأیید'),
          ],
        ),
      ),
    );
  }
}

class OtpPage extends StatefulWidget {
  const OtpPage({super.key});

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  final _otp = TextEditingController();
  Timer? _timer;
  var _left = 120;
  var _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _left = context.read<SessionController>().otpExpiresIn;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_left > 0) setState(() => _left -= 1);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otp.dispose();
    super.dispose();
  }

  Future<void> _verify(String code) async {
    if (_loading || code.length != 6) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await context.read<SessionController>().verifyOtp(code);
    } catch (error) {
      if (mounted) setState(() => _error = errorText(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    final session = context.read<SessionController>();
    final phone = session.pendingPhone;
    if (phone == null || _left > 0) return;
    try {
      await session.sendOtp(phone);
      if (mounted) setState(() => _left = session.otpExpiresIn);
    } catch (error) {
      if (mounted) setState(() => _error = errorText(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    if (session.pendingPhone == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/login');
      });
    }
    final minutes = (_left ~/ 60).toString().padLeft(2, '0');
    final seconds = (_left % 60).toString().padLeft(2, '0');
    final masked = session.maskedPhone ?? session.pendingPhone ?? '';
    return AuthScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: () => context.go('/login'),
              style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 0)),
              icon: const Icon(Icons.arrow_forward, size: 18),
              label: const Text('تغییر شماره موبایل'),
            ),
          ),
          AuthCard(
        title: 'کد تأیید را وارد کنید',
        description: 'کد تأیید به شماره $masked ارسال شد و تا ۲ دقیقه معتبر است.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _OtpBoxes(
              value: _otp.text,
              onChanged: (value) {
                _otp.text = value;
                if (value.length == 6) _verify(value);
                setState(() {});
              },
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              AuthError(_error!),
            ],
            const SizedBox(height: 20),
            AuthPrimaryButton(
              onPressed: _loading || _otp.text.length != 6 ? null : () => _verify(_otp.text),
              label: _loading ? 'در حال تأیید...' : 'تأیید و ورود',
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: Text('ارسال مجدد تا ${faDigits('$minutes:$seconds')}', style: TextStyle(color: context.dt.textMuted, fontSize: 14))),
                TextButton(onPressed: _left == 0 ? _resend : null, child: const Text('ارسال مجدد کد')),
              ],
            ),
          ],
        ),
          ),
        ],
      ),
    );
  }
}

class ProfileSetupPage extends StatefulWidget {
  const ProfileSetupPage({super.key});

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  late final TextEditingController _first;
  late final TextEditingController _last;
  late final TextEditingController _email;
  var _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final user = context.read<SessionController>().user;
    _first = TextEditingController(text: user?.firstName ?? '');
    _last = TextEditingController(text: user?.lastName ?? '');
    _email = TextEditingController(text: user?.email ?? '');
  }

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_first.text.trim().isEmpty || _last.text.trim().isEmpty) {
      setState(() => _error = 'لطفاً نام و نام خانوادگی را وارد کنید.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await context.read<SessionController>().completeProfile(
            firstName: _first.text.trim(),
            lastName: _last.text.trim(),
            email: _email.text.trim(),
          );
    } catch (error) {
      if (mounted) setState(() => _error = errorText(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final phone = context.watch<SessionController>().user?.phoneNumber ?? '';
    return AuthScaffold(
      child: AuthCard(
        title: 'تکمیل پروفایل',
        description: 'برای شروع، اطلاعات حساب خود را وارد کنید. می‌توانید این مرحله را رد کنید.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(controller: _first, decoration: const InputDecoration(labelText: 'نام')),
            const SizedBox(height: 12),
            TextField(controller: _last, decoration: const InputDecoration(labelText: 'نام خانوادگی')),
            const SizedBox(height: 12),
            TextField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'ایمیل (اختیاری)')),
            const SizedBox(height: 12),
            InputDecorator(
              decoration: const InputDecoration(labelText: 'شماره موبایل'),
              child: Text(phone, textDirection: TextDirection.ltr),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: context.dt.error)),
            ],
            const SizedBox(height: 16),
            FilledButton(onPressed: _loading ? null : _save, child: Text(_loading ? 'در حال ذخیره...' : 'ادامه')),
            TextButton(
              onPressed: _loading ? null : () => context.read<SessionController>().skipProfile(),
              child: const Text('بعداً'),
            ),
          ],
        ),
      ),
    );
  }
}

class KnowledgeSetupPage extends StatefulWidget {
  const KnowledgeSetupPage({super.key});

  @override
  State<KnowledgeSetupPage> createState() => _KnowledgeSetupPageState();
}

class _KnowledgeSetupPageState extends State<KnowledgeSetupPage> {
  final _name = TextEditingController();
  final _about = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _hours = TextEditingController();
  final _allowed = TextEditingController();
  final _forbidden = TextEditingController();
  String _industry = '';
  var _step = 0;
  var _loading = true;
  var _saving = false;
  String? _error;
  int? _workspaceId;
  List<Faq> _faqs = const [];

  static const _titles = ['هویت کسب‌وکار', 'درباره و تماس', 'آدرس و ساعات', 'قوانین هوشمند', 'سؤالات متداول'];
  static const _descriptions = [
    'نام و حوزه فعالیت را مشخص کنید.',
    'معرفی کوتاه و شماره تماس.',
    'محل و زمان پاسخ‌گویی.',
    'موضوعات مجاز و ممنوع برای پاسخ‌گویی.',
    'چند سؤال پرتکرار اضافه کنید (اختیاری).',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final controller in [_name, _about, _phone, _address, _hours, _allowed, _forbidden]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final session = context.read<SessionController>();
    final id = session.workspace?.id;
    if (id == null) {
      setState(() {
        _loading = false;
        _error = 'فضای کاری یافت نشد.';
      });
      return;
    }
    final api = context.read<DirectooApi>();
    try {
      final business = await api.business(id);
      final rules = await api.rules(id);
      final faqs = await api.faqs(id);
      if (!mounted) return;
      _workspaceId = id;
      _name.text = business.businessName;
      _industry = business.industry;
      _about.text = business.about;
      _phone.text = business.phone;
      _address.text = business.address;
      _hours.text = business.workingHours;
      _allowed.text = rules.allowedTopics;
      _forbidden.text = rules.forbiddenTopics;
      _faqs = faqs;
    } catch (error) {
      _error = errorText(error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<bool> _persist() async {
    final id = _workspaceId;
    if (id == null) return false;
    final api = context.read<DirectooApi>();
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      if (_step <= 2) {
        await api.updateBusiness(id, {
          'business_name': _name.text.trim(),
          'industry': _industry,
          'about': _about.text.trim(),
          'phone': _phone.text.trim(),
          'address': _address.text.trim(),
          'working_hours': _hours.text.trim(),
        });
      } else if (_step == 3) {
        await api.updateRules(id, {
          'allowed_topics': _allowed.text.trim(),
          'forbidden_topics': _forbidden.text.trim(),
        });
      }
      return true;
    } catch (error) {
      if (mounted) setState(() => _error = errorText(error));
      return false;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _next() async {
    if (_step == 0) {
      if (_name.text.trim().isEmpty) {
        setState(() => _error = 'نام کسب‌وکار را وارد کنید.');
        return;
      }
      if (_industry.isEmpty) {
        setState(() => _error = 'حوزه فعالیت را انتخاب کنید.');
        return;
      }
    }
    final ok = await _persist();
    if (!ok || !mounted) return;
    if (_step == _titles.length - 1) {
      await context.read<SessionController>().finishKnowledge();
      return;
    }
    setState(() => _step += 1);
  }

  Future<void> _addFaq() async {
    final id = _workspaceId;
    if (id == null) return;
    final question = TextEditingController();
    final answer = TextEditingController();
    final ok = await showFormSheet<bool>(
      context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PageHeader(title: 'سؤال متداول', description: 'سؤال و پاسخ را بنویسید'),
          TextField(controller: question, decoration: const InputDecoration(labelText: 'سؤال')),
          const SizedBox(height: 12),
          TextField(controller: answer, minLines: 3, maxLines: 5, decoration: const InputDecoration(labelText: 'پاسخ')),
          const SizedBox(height: 16),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('افزودن')),
        ],
      ),
    );
    final q = question.text.trim();
    final a = answer.text.trim();
    question.dispose();
    answer.dispose();
    if (ok != true || !mounted || q.isEmpty || a.isEmpty) return;
    setState(() => _saving = true);
    try {
      final created = await context.read<DirectooApi>().saveFaq(id, question: q, answer: a);
      _faqs = [..._faqs, created];
    } catch (error) {
      _error = errorText(error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const AuthScaffold(child: Center(child: CircularProgressIndicator()));
    }
    return AuthScaffold(
      child: AuthCard(
        title: _titles[_step],
        description: 'مرحله ${faDigits('${_step + 1}')} از ${faDigits('${_titles.length}')} · ${_descriptions[_step]}',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_step == 0) ...[
              TextField(controller: _name, decoration: const InputDecoration(labelText: 'نام کسب‌وکار')),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _industry.isEmpty ? null : _industry,
                decoration: const InputDecoration(labelText: 'حوزه فعالیت'),
                items: [for (final entry in industryLabels.entries) DropdownMenuItem(value: entry.key, child: Text(entry.value))],
                onChanged: (value) => setState(() => _industry = value ?? ''),
              ),
            ],
            if (_step == 1) ...[
              TextField(controller: _about, minLines: 3, maxLines: 5, decoration: const InputDecoration(labelText: 'درباره کسب‌وکار')),
              const SizedBox(height: 12),
              TextField(controller: _phone, decoration: const InputDecoration(labelText: 'تلفن')),
            ],
            if (_step == 2) ...[
              TextField(controller: _address, decoration: const InputDecoration(labelText: 'آدرس')),
              const SizedBox(height: 12),
              TextField(controller: _hours, decoration: const InputDecoration(labelText: 'ساعات پاسخ‌گویی')),
            ],
            if (_step == 3) ...[
              TextField(controller: _allowed, minLines: 2, maxLines: 4, decoration: const InputDecoration(labelText: 'موضوعات مجاز')),
              const SizedBox(height: 12),
              TextField(controller: _forbidden, minLines: 2, maxLines: 4, decoration: const InputDecoration(labelText: 'موضوعات ممنوع')),
            ],
            if (_step == 4) ...[
              for (final faq in _faqs)
                ListTile(contentPadding: EdgeInsets.zero, title: Text(faq.question), subtitle: Text(faq.answer)),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: OutlinedButton.icon(onPressed: _saving ? null : _addFaq, icon: const Icon(Icons.add), label: const Text('افزودن سؤال')),
              ),
            ],
            if (_error != null) Text(_error!, style: TextStyle(color: context.dt.error)),
            const SizedBox(height: 12),
            FilledButton(onPressed: _saving ? null : _next, child: Text(_saving ? 'در حال ذخیره...' : (_step == 4 ? 'پایان و ادامه' : 'بعدی'))),
            TextButton(onPressed: _saving ? null : () => context.read<SessionController>().skipKnowledge(), child: const Text('رد کردن')),
          ],
        ),
      ),
    );
  }
}

class InstagramSetupPage extends StatefulWidget {
  const InstagramSetupPage({super.key});

  @override
  State<InstagramSetupPage> createState() => _InstagramSetupPageState();
}

class _InstagramSetupPageState extends State<InstagramSetupPage> {
  final _username = TextEditingController();
  var _loading = true;
  var _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _username.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final session = context.read<SessionController>();
    final id = session.workspace?.id;
    if (id == null) {
      setState(() {
        _loading = false;
        _error = 'فضای کاری یافت نشد.';
      });
      return;
    }
    try {
      final existing = await context.read<DirectooApi>().accessRequest(id);
      if (!mounted) return;
      if (existing?.status == 'approved') {
        await session.clearInstagramPending();
        return;
      }
      if (existing != null && existing.reviewing) {
        session.instagramReviewing = true;
        session.publish();
        return;
      }
      if (existing != null) _username.text = existing.username;
    } catch (error) {
      _error = errorText(error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    final id = context.read<SessionController>().workspace?.id;
    if (id == null) return;
    final username = normalizeInstagramUsername(_username.text);
    if (!isValidInstagramUsername(username)) {
      setState(() => _error = 'یوزرنیم اینستاگرام را درست وارد کنید.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await context.read<DirectooApi>().submitAccessRequest(id, username);
      if (mounted) await context.read<SessionController>().clearInstagramPending();
    } catch (error) {
      if (mounted) setState(() => _error = errorText(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const AuthScaffold(child: Center(child: CircularProgressIndicator()));
    return AuthScaffold(
      child: AuthCard(
        title: 'یوزرنیم اینستاگرام',
        description: 'یوزرنیم پیج فروشگاه را وارد کنید تا بتوانید اینستاگرام را وصل کنید.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _username,
              textDirection: TextDirection.ltr,
              decoration: const InputDecoration(labelText: 'نام کاربری اینستاگرام', prefixText: '@'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: TextStyle(color: context.dt.error)),
            ],
            const SizedBox(height: 16),
            FilledButton(onPressed: _saving ? null : _submit, child: Text(_saving ? 'در حال ثبت...' : 'ثبت و ادامه')),
            TextButton(onPressed: _saving ? null : () => context.read<SessionController>().clearInstagramPending(), child: const Text('بعداً')),
          ],
        ),
      ),
    );
  }
}

class InstagramPendingPage extends StatefulWidget {
  const InstagramPendingPage({super.key});

  @override
  State<InstagramPendingPage> createState() => _InstagramPendingPageState();
}

class _InstagramPendingPageState extends State<InstagramPendingPage> {
  InstagramAccessRequest? _request;
  var _loading = true;
  var _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final id = context.read<SessionController>().workspace?.id;
    if (id == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      _request = await context.read<DirectooApi>().accessRequest(id);
    } catch (error) {
      _error = errorText(error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _confirm() async {
    final id = context.read<SessionController>().workspace?.id;
    if (id == null) return;
    setState(() => _saving = true);
    try {
      await context.read<DirectooApi>().confirmFacebook(id);
      if (mounted) await context.read<SessionController>().clearInstagramPending();
    } catch (error) {
      if (mounted) setState(() => _error = errorText(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const AuthScaffold(child: Center(child: CircularProgressIndicator()));
    final awaiting = _request?.status == 'awaiting_facebook';
    final link = _request?.facebookLink ?? '';
    return AuthScaffold(
      child: AuthCard(
        title: awaiting ? 'منتظر تایید شما در فیسبوک' : 'در حال بررسی',
        description: awaiting ? 'وارد لینک شوید و در تب آخر دایرکتو را تأیید کنید.' : 'درخواست اتصال اینستاگرام شما ثبت شد.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if ((_request?.username ?? '').isNotEmpty)
              Text('@${_request!.username}', textAlign: TextAlign.center, textDirection: TextDirection.ltr, style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            if (awaiting) ...[
              const Text('روی «وارد شود» بزنید و در تب آخر دایرکتو را تأیید کنید. بعد از آن «تایید کردم» را بزنید.'),
              const SizedBox(height: 12),
              if (link.isEmpty)
                const Text('لینک فیسبوک هنوز ثبت نشده است. کمی بعد دوباره این صفحه را باز کنید.')
              else
                FilledButton(
                  onPressed: () => launchUrl(Uri.parse(link), mode: LaunchMode.externalApplication),
                  child: const Text('وارد شود'),
                ),
              const SizedBox(height: 8),
              OutlinedButton(onPressed: _saving || link.isEmpty ? null : _confirm, child: Text(_saving ? 'در حال ثبت...' : 'تایید کردم')),
            ] else
              const Text('یوزرنیم اینستاگرام شما دریافت شد و کمتر از ۱۰ دقیقه بررسی می‌شود.'),
            if (_error != null) Text(_error!, style: TextStyle(color: context.dt.error)),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => context.read<SessionController>().clearInstagramPending(),
              child: const Text('ورود به داشبورد'),
            ),
          ],
        ),
      ),
    );
  }
}

class _OtpBoxes extends StatefulWidget {
  const _OtpBoxes({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  State<_OtpBoxes> createState() => _OtpBoxesState();
}

class _OtpBoxesState extends State<_OtpBoxes> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller.text = widget.value;
  }

  @override
  void didUpdateWidget(covariant _OtpBoxes oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _controller.text) _controller.text = widget.value;
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dt = context.dt;
    final value = widget.value;
    return SizedBox(
      height: 64,
      child: Stack(
        children: [
          Row(
            textDirection: TextDirection.ltr,
            children: [
              for (var i = 0; i < 6; i++)
                Expanded(
                  child: Container(
                    margin: EdgeInsets.only(left: i == 0 ? 0 : 8),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: dt.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: i == value.length ? dt.primary : const Color(0xFFCDD2E2), width: i == value.length ? 1.5 : 1),
                    ),
                    child: Text(i < value.length ? faDigits(value[i]) : '', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: dt.text)),
                  ),
                ),
            ],
          ),
          Positioned.fill(
            child: TextField(
              controller: _controller,
              focusNode: _focus,
              autofocus: true,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textDirection: TextDirection.ltr,
              style: const TextStyle(color: Colors.transparent),
              cursorColor: Colors.transparent,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(counterText: '', border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none),
              onChanged: widget.onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class BootPage extends StatelessWidget {
  const BootPage({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    final dt = context.dt;
    return Scaffold(
      backgroundColor: dt.surface,
      body: SafeArea(
        child: session.bootError == null
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    BrandLogo(height: 52),
                    SizedBox(height: 28),
                    SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2.4)),
                  ],
                ),
              )
            : Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const BrandLogo(height: 44),
                      const SizedBox(height: 24),
                      Text(session.bootError!, textAlign: TextAlign.center, style: TextStyle(color: dt.textMuted, height: 1.7)),
                      const SizedBox(height: 16),
                      FilledButton(onPressed: session.bootstrap, child: const Text('تلاش مجدد')),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
