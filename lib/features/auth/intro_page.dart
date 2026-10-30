import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../presentation/session/session_bloc.dart';
import '../../theme/app_theme.dart';
import '../../widgets/brand.dart';

class IntroPage extends StatefulWidget {
  const IntroPage({super.key});

  @override
  State<IntroPage> createState() => _IntroPageState();
}

class _IntroPageState extends State<IntroPage> {
  final _controller = PageController();
  var _index = 0;

  static const _slides = [
    _Slide(
      icon: Icons.near_me_rounded,
      title: 'هر دایرکت،\nیک فرصت فروش',
      body: 'گفتگو، مشتری و فروش اینستاگرام را در یک پنل ببینید.',
    ),
    _Slide(
      icon: Icons.bolt_rounded,
      title: 'پاسخ هوشمند',
      body: 'کلمه کلیدی را تعریف کنید تا دایرکت، خودکار و به‌موقع جواب بگیرد.',
    ),
    _Slide(
      icon: Icons.view_carousel_outlined,
      title: 'ویترین و کامنت',
      body: 'کارت محصول بفرستید و کامنت را به یک گفتگوی فروش تبدیل کنید.',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await context.read<SessionBloc>().completeIntro();
    if (mounted) context.go('/login');
  }

  void _next() {
    if (_index >= _slides.length - 1) {
      _finish();
      return;
    }
    _controller.nextPage(duration: const Duration(milliseconds: 280), curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    final dt = context.dt;
    final last = _index == _slides.length - 1;
    return Scaffold(
      backgroundColor: dt.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const BrandLogo(height: 32),
                  const Spacer(),
                  TextButton(onPressed: _finish, child: const Text('رد کردن')),
                ],
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _slides.length,
                  onPageChanged: (value) => setState(() => _index = value),
                  itemBuilder: (context, index) => _SlideView(slide: _slides[index]),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < _slides.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: i == _index ? 22 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == _index ? dt.primary : dt.border,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              FilledButton(onPressed: _next, child: Text(last ? 'شروع' : 'بعدی')),
            ],
          ),
        ),
      ),
    );
  }
}

class _Slide {
  const _Slide({required this.icon, required this.title, required this.body});
  final IconData icon;
  final String title;
  final String body;
}

class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide});
  final _Slide slide;

  @override
  Widget build(BuildContext context) {
    final dt = context.dt;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(color: dt.primary50, borderRadius: BorderRadius.circular(28)),
          child: Icon(slide.icon, size: 42, color: dt.primary),
        ),
        const SizedBox(height: 28),
        Text(slide.title, textAlign: TextAlign.center, style: TextStyle(fontSize: 32, height: 1.35, fontWeight: FontWeight.w800, color: dt.text)),
        const SizedBox(height: 12),
        Text(slide.body, textAlign: TextAlign.center, style: TextStyle(fontSize: 16, height: 1.8, color: dt.textMuted)),
      ],
    );
  }
}
