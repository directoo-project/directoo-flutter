import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api_exception.dart';
import '../../core/format.dart';
import '../../core/labels.dart';
import '../../domain/repositories/instagram_repository.dart';
import '../../domain/repositories/knowledge_repository.dart';
import '../../domain/entities/models.dart';
import '../../presentation/session/session_bloc.dart';
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
      await context.read<SessionBloc>().sendOtp(phone);
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
          textAlign: TextAlign.center,
          TextSpan(
            style: TextStyle(fontSize: 28, height: 1.4, fontWeight: FontWeight.w800, color: dt.text),
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
              hasError: _error != null,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+]'))],
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
            ),
            const SizedBox(height: 8),
            Text(
              'برای ورود یا ساخت حساب، کد تأیید به این شماره پیامک می‌شود.',
              textAlign: TextAlign.center,
              style: TextStyle(color: dt.textMuted, fontSize: 13, height: 1.7),
            ),
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
    _left = context.read<SessionBloc>().otpExpiresIn;
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
      await context.read<SessionBloc>().verifyOtp(code);
    } catch (error) {
      if (mounted) setState(() => _error = errorText(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    final session = context.read<SessionBloc>();
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
    final session = context.watch<SessionBloc>();
    if (session.pendingPhone == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/login');
      });
    }
    final minutes = (_left ~/ 60).toString().padLeft(2, '0');
    final seconds = (_left % 60).toString().padLeft(2, '0');
    final masked = session.maskedPhone ?? session.pendingPhone ?? '';
    final dt = context.dt;
    return AuthScaffold(
      child: AuthCard(
        title: 'کد تأیید را وارد کنید',
        description: 'کد تأیید به شماره $masked ارسال شد و تا ۲ دقیقه معتبر است.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _OtpBoxes(
              value: _otp.text,
              hasError: _error != null,
              onChanged: (value) {
                _otp.text = value;
                if (_error != null) _error = null;
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
            const SizedBox(height: 16),
            Text('ارسال مجدد تا ${faDigits('$minutes:$seconds')}', textAlign: TextAlign.center, style: TextStyle(color: dt.textMuted, fontSize: 14)),
            Center(
              child: TextButton(
                onPressed: _left == 0 ? _resend : null,
                child: const Text('ارسال مجدد کد'),
              ),
            ),
            Center(
              child: TextButton(
                onPressed: () => context.go('/login'),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('تغییر شماره موبایل'),
                    SizedBox(width: 6),
                    Icon(Icons.edit_outlined, size: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
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
    final user = context.read<SessionBloc>().user;
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
      await context.read<SessionBloc>().completeProfile(
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
    final dt = context.dt;
    final phone = context.watch<SessionBloc>().user?.phoneNumber ?? '';
    final missing = _error != null;
    return AuthScaffold(
      child: AuthCard(
        title: 'تکمیل پروفایل',
        description: 'برای شروع، اطلاعات حساب خود را وارد کنید. می‌توانید این مرحله را رد کنید.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AuthLabel('نام'),
            AuthField(controller: _first, hint: 'کاربر', hasError: missing && _first.text.trim().isEmpty),
            const SizedBox(height: 14),
            const AuthLabel('نام خانوادگی'),
            AuthField(controller: _last, hint: 'نمونه', hasError: missing && _last.text.trim().isEmpty),
            const SizedBox(height: 14),
            const AuthLabel('ایمیل (اختیاری)'),
            AuthField(
              controller: _email,
              hint: 'user@example.com',
              keyboardType: TextInputType.emailAddress,
              textDirection: TextDirection.ltr,
            ),
            const SizedBox(height: 14),
            const AuthLabel('شماره موبایل'),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              decoration: BoxDecoration(
                color: dt.surfaceMuted,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: dt.border),
              ),
              child: Text(
                phone.isEmpty ? '—' : faDigits(phone),
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.left,
                style: TextStyle(color: dt.textMuted, fontWeight: FontWeight.w600, fontSize: 16),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: dt.error, fontWeight: FontWeight.w600)),
            ],
            const SizedBox(height: 16),
            AuthPrimaryButton(onPressed: _loading ? null : _save, label: _loading ? 'در حال ذخیره...' : 'ادامه'),
            Center(
              child: TextButton(
                onPressed: () {
                  if (_loading) return;
                  context.read<SessionBloc>().skipProfile();
                },
                child: const Text('بعداً'),
              ),
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
    final session = context.read<SessionBloc>();
    final id = session.workspace?.id;
    if (id == null) {
      setState(() {
        _loading = false;
        _error = 'فضای کاری یافت نشد.';
      });
      return;
    }
    final api = context.read<KnowledgeRepository>();
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
    final api = context.read<KnowledgeRepository>();
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
      await context.read<SessionBloc>().finishKnowledge();
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
          const AuthLabel('سؤال'),
          AuthField(controller: question, hint: 'سؤال'),
          const SizedBox(height: 12),
          const AuthLabel('پاسخ'),
          AuthField(controller: answer, hint: 'پاسخ', minLines: 3, maxLines: 5),
          const SizedBox(height: 16),
          AuthPrimaryButton(onPressed: () => Navigator.pop(context, true), label: 'افزودن'),
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
      final created = await context.read<KnowledgeRepository>().saveFaq(id, question: q, answer: a);
      _faqs = [..._faqs, created];
    } catch (error) {
      _error = errorText(error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const AuthScaffold(child: _SetupSkeleton());
    final dt = context.dt;
    final nameInvalid = _error == 'نام کسب‌وکار را وارد کنید.';
    return AuthScaffold(
      child: AuthCard(
        title: _titles[_step],
        description: 'مرحله ${faDigits('${_step + 1}')} از ${faDigits('${_titles.length}')} · ${_descriptions[_step]}',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _StepBars(step: _step, total: _titles.length),
            const SizedBox(height: 18),
            if (_step == 0) ...[
              const AuthLabel('نام کسب‌وکار'),
              AuthField(controller: _name, hint: 'نام کسب‌وکار', hasError: nameInvalid),
              const SizedBox(height: 14),
              const AuthLabel('حوزه فعالیت'),
              DropdownButtonFormField<String>(
                initialValue: _industry.isEmpty ? null : _industry,
                hint: const Text('انتخاب کنید'),
                decoration: const InputDecoration(),
                items: [for (final entry in industryLabels.entries) DropdownMenuItem(value: entry.key, child: Text(entry.value))],
                onChanged: _saving ? null : (value) => setState(() => _industry = value ?? ''),
              ),
            ],
            if (_step == 1) ...[
              const AuthLabel('درباره کسب‌وکار'),
              AuthField(controller: _about, hint: 'درباره کسب‌وکار', minLines: 3, maxLines: 5),
              const SizedBox(height: 14),
              const AuthLabel('تلفن'),
              AuthField(controller: _phone, hint: 'تلفن'),
            ],
            if (_step == 2) ...[
              const AuthLabel('آدرس'),
              AuthField(controller: _address, hint: 'آدرس'),
              const SizedBox(height: 14),
              const AuthLabel('ساعات پاسخ‌گویی'),
              AuthField(controller: _hours, hint: 'ساعات پاسخ‌گویی'),
            ],
            if (_step == 3) ...[
              const AuthLabel('موضوعات مجاز'),
              AuthField(controller: _allowed, hint: 'موضوعات مجاز', minLines: 3, maxLines: 5),
              const SizedBox(height: 14),
              const AuthLabel('موضوعات ممنوع'),
              AuthField(controller: _forbidden, hint: 'موضوعات ممنوع', minLines: 3, maxLines: 5),
            ],
            if (_step == 4) ...[
              for (final faq in _faqs) ...[
                SurfaceCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(faq.question, style: const TextStyle(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text(faq.answer, style: TextStyle(color: dt.textMuted)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: OutlinedButton(
                  onPressed: _addFaq,
                  style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44), padding: const EdgeInsets.symmetric(horizontal: 16)),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('افزودن سؤال'),
                      SizedBox(width: 6),
                      Icon(Icons.add, size: 18),
                    ],
                  ),
                ),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: dt.error, fontWeight: FontWeight.w600)),
            ],
            const SizedBox(height: 16),
            AuthPrimaryButton(
              onPressed: _saving ? null : _next,
              label: _saving ? 'در حال ذخیره...' : (_step == 4 ? 'پایان و ادامه' : 'بعدی'),
            ),
            Center(
              child: TextButton(
                onPressed: () {
                  if (_saving) return;
                  context.read<SessionBloc>().skipKnowledge();
                },
                child: const Text('رد کردن'),
              ),
            ),
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
    final session = context.read<SessionBloc>();
    final id = session.workspace?.id;
    if (id == null) {
      setState(() {
        _loading = false;
        _error = 'فضای کاری یافت نشد.';
      });
      return;
    }
    try {
      final existing = await context.read<InstagramRepository>().accessRequest(id);
      if (!mounted) return;
      if (existing?.status == 'approved') {
        await session.clearInstagramPending();
        return;
      }
      if (existing != null && existing.reviewing) {
        await session.markInstagramReviewing();
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
    final id = context.read<SessionBloc>().workspace?.id;
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
      await context.read<InstagramRepository>().submitAccessRequest(id, username);
      if (mounted) await context.read<SessionBloc>().clearInstagramPending();
    } catch (error) {
      if (mounted) setState(() => _error = errorText(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const AuthScaffold(child: _SetupSkeleton(compact: true));
    final dt = context.dt;
    final invalid = _error == 'یوزرنیم اینستاگرام را درست وارد کنید.';
    return AuthScaffold(
      child: AuthCard(
        title: 'یوزرنیم اینستاگرام',
        description: 'یوزرنیم پیج فروشگاه را وارد کنید تا بتوانید اینستاگرام را وصل کنید.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AuthLabel('نام کاربری اینستاگرام'),
            AuthField(
              controller: _username,
              hint: 'username',
              prefixText: '@',
              textDirection: TextDirection.ltr,
              hasError: invalid,
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: dt.error, fontWeight: FontWeight.w600)),
            ],
            const SizedBox(height: 16),
            AuthPrimaryButton(onPressed: _saving ? null : _submit, label: _saving ? 'در حال ثبت...' : 'ثبت و ادامه'),
            Center(
              child: TextButton(
                onPressed: () {
                  if (_saving) return;
                  context.read<SessionBloc>().clearInstagramPending();
                },
                child: const Text('بعداً'),
              ),
            ),
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
    final id = context.read<SessionBloc>().workspace?.id;
    if (id == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      _request = await context.read<InstagramRepository>().accessRequest(id);
    } catch (error) {
      _error = errorText(error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _confirm() async {
    final id = context.read<SessionBloc>().workspace?.id;
    if (id == null) return;
    setState(() => _saving = true);
    try {
      await context.read<InstagramRepository>().confirmFacebook(id);
      if (mounted) await context.read<SessionBloc>().clearInstagramPending();
    } catch (error) {
      if (mounted) setState(() => _error = errorText(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const AuthScaffold(child: _SetupSkeleton(compact: true));
    final dt = context.dt;
    final approved = _request?.status == 'approved';
    final awaiting = _request?.status == 'awaiting_facebook';
    final link = _request?.facebookLink ?? '';
    final username = _request?.username ?? '';
    return AuthScaffold(
      child: AuthCard(
        title: approved ? 'اینستاگرام وصل شد' : (awaiting ? 'منتظر تأیید شما در فیسبوک' : 'در حال بررسی'),
        description: approved
            ? 'درخواست اتصال اینستاگرام شما تأیید شد.'
            : (awaiting ? 'وارد لینک شوید و در تب آخر دایرکتو را تأیید کنید.' : 'درخواست اتصال اینستاگرام شما ثبت شد.'),
        eyebrow: approved
            ? Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(color: dt.success.withValues(alpha: 0.12), shape: BoxShape.circle),
                  child: Icon(Icons.check_rounded, color: dt.success, size: 32),
                ),
              )
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (username.isNotEmpty)
              Text('@$username', textAlign: TextAlign.center, textDirection: TextDirection.ltr, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            const SizedBox(height: 12),
            Text(
              approved
                  ? 'حالا می‌توانید دایرکت‌ها را از داشبورد مدیریت کنید.'
                  : (awaiting
                      ? 'روی «وارد شود» بزنید و در تب آخر دایرکتو را تأیید کنید. بعد از آن «تایید کردم» را بزنید.'
                      : 'یوزرنیم اینستاگرام شما دریافت شد و کمتر از ۱۰ دقیقه بررسی می‌شود.'),
              textAlign: TextAlign.center,
              style: TextStyle(color: dt.textMuted, height: 1.7),
            ),
            if (awaiting) ...[
              const SizedBox(height: 16),
              if (link.isEmpty)
                Text('لینک فیسبوک هنوز ثبت نشده است. کمی بعد دوباره این صفحه را باز کنید.', textAlign: TextAlign.center, style: TextStyle(color: dt.textMuted))
              else
                AuthPrimaryButton(
                  onPressed: () => launchUrl(Uri.parse(link), mode: LaunchMode.externalApplication),
                  label: 'وارد شود',
                ),
              const SizedBox(height: 8),
              OutlinedButton(onPressed: _saving || link.isEmpty ? null : _confirm, child: Text(_saving ? 'در حال ثبت...' : 'تایید کردم')),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: dt.error, fontWeight: FontWeight.w600)),
            ],
            const SizedBox(height: 16),
            AuthPrimaryButton(
              onPressed: () => context.read<SessionBloc>().clearInstagramPending(),
              label: 'ورود به داشبورد',
            ),
          ],
        ),
      ),
    );
  }
}

class _OtpBoxes extends StatefulWidget {
  const _OtpBoxes({required this.value, required this.onChanged, this.hasError = false});

  final String value;
  final ValueChanged<String> onChanged;
  final bool hasError;

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
      height: 56,
      child: Stack(
        children: [
          Row(
            textDirection: TextDirection.ltr,
            children: [
              for (var i = 0; i < 6; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: dt.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: widget.hasError ? dt.error : (i == value.length ? dt.primary : const Color(0xFFCDD2E2)),
                        width: widget.hasError || i == value.length ? 1.5 : 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        i < value.length ? faDigits(value[i]) : '',
                        style: TextStyle(fontSize: 22, height: 1, fontWeight: FontWeight.w800, color: dt.text),
                      ),
                    ),
                  ),
                ),
              ],
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
              textAlignVertical: TextAlignVertical.center,
              style: const TextStyle(color: Colors.transparent, fontSize: 22, height: 1),
              cursorColor: Colors.transparent,
              cursorWidth: 0,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                counterText: '',
                filled: false,
                isCollapsed: true,
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
              ),
              onChanged: widget.onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _StepBars extends StatelessWidget {
  const _StepBars({required this.step, required this.total});

  final int step;
  final int total;

  @override
  Widget build(BuildContext context) {
    final dt = context.dt;
    return Row(
      children: [
        for (var i = 0; i < total; i++)
          Expanded(
            child: Container(
              height: 4,
              margin: EdgeInsetsDirectional.only(start: i == 0 ? 0 : 6),
              decoration: BoxDecoration(
                color: i <= step ? dt.primary : dt.border,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
      ],
    );
  }
}

class _SetupSkeleton extends StatelessWidget {
  const _SetupSkeleton({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(child: SkeletonBox(width: 180, height: 28, radius: 10)),
        const SizedBox(height: 12),
        const Center(child: SkeletonBox(width: 240, height: 14, radius: 8)),
        const SizedBox(height: 28),
        const Align(alignment: AlignmentDirectional.centerStart, child: SkeletonBox(width: 96, height: 12, radius: 8)),
        const SizedBox(height: 8),
        const SkeletonBox(height: 52, radius: 14),
        if (!compact) ...[
          const SizedBox(height: 16),
          const Align(alignment: AlignmentDirectional.centerStart, child: SkeletonBox(width: 80, height: 12, radius: 8)),
          const SizedBox(height: 8),
          const SkeletonBox(height: 52, radius: 14),
        ],
        const SizedBox(height: 20),
        const SkeletonBox(height: 52, radius: 14),
        const SizedBox(height: 16),
        const Center(child: SkeletonBox(width: 72, height: 16, radius: 8)),
      ],
    );
  }
}

class BootPage extends StatelessWidget {
  const BootPage({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionBloc>();
    final dt = context.dt;
    return Scaffold(
      backgroundColor: dt.bgSubtle,
      body: SafeArea(
        child: session.bootError == null
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    BrandSymbol(size: 56),
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
                      const BrandSymbol(size: 56),
                      const SizedBox(height: 20),
                      Text(
                        session.bootError!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: dt.error, fontWeight: FontWeight.w700, height: 1.7),
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 48),
                          padding: const EdgeInsets.symmetric(horizontal: 22),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: session.bootstrap,
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('تلاش مجدد'),
                            SizedBox(width: 8),
                            Icon(Icons.refresh, size: 18),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
