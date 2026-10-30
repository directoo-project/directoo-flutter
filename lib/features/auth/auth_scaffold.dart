import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_theme.dart';
import '../../widgets/brand.dart';

class AuthScaffold extends StatelessWidget {
  const AuthScaffold({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dt = context.dt;
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final form = ColoredBox(
      color: dt.surface,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(wide ? 48 : 20, wide ? 32 : 24, wide ? 48 : 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: wide ? AlignmentDirectional.centerStart : Alignment.center,
                child: const BrandLogo(height: 36),
              ),
              SizedBox(height: wide ? 48 : 32),
              Expanded(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: SingleChildScrollView(child: child),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('قوانین و مقررات', style: TextStyle(color: dt.textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 16),
                  Text('حریم خصوصی', style: TextStyle(color: dt.textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    return Scaffold(
      backgroundColor: dt.surface,
      body: wide
          ? Row(
              children: [
                Expanded(child: form),
                const Expanded(child: _BrandPanel()),
              ],
            )
          : form,
    );
  }
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFF0B1024), Color(0xFF121A3A), Color(0xFF0E1430)],
        ),
      ),
      child: Stack(
        children: [
          const Positioned.fill(child: CustomPaint(painter: _ChevronPattern())),
          const Padding(
            padding: EdgeInsets.fromLTRB(48, 48, 48, 36),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BrandLogo(onDark: true, height: 36),
                SizedBox(height: 36),
                Text('هر دایرکت،', style: TextStyle(color: Colors.white, fontSize: 40, height: 1.25, fontWeight: FontWeight.w900)),
                Text('یک فرصت فروش', style: TextStyle(color: Color(0xFFFF5C39), fontSize: 40, height: 1.25, fontWeight: FontWeight.w900)),
                SizedBox(height: 32),
                _BrandPoint(icon: Icons.bolt_outlined, title: 'پاسخ هوشمند', body: 'کلمه کلیدی را تعریف کنید تا پاسخ دایرکت خودکار ارسال شود.'),
                _BrandPoint(icon: Icons.chat_bubble_outline, title: 'کامنت هوشمند', body: 'کامنت‌ها را خودکار به دایرکت تبدیل کنید.'),
                _BrandPoint(icon: Icons.view_carousel_outlined, title: 'ویترین‌ساز', body: 'کارت محصول را در دایرکت ارسال کنید.'),
                Spacer(),
                _ChatPreview(),
                SizedBox(height: 28),
                Wrap(
                  spacing: 20,
                  runSpacing: 8,
                  children: [
                    _Check(label: 'بدون نیاز به کارت اعتباری'),
                    _Check(label: 'راه‌اندازی در ۵ دقیقه'),
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

class _ChevronPattern extends CustomPainter {
  const _ChevronPattern();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x14FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    const step = 36.0;
    for (var y = -step; y < size.height + step; y += step) {
      for (var x = -step; x < size.width + step; x += step) {
        final path = Path()
          ..moveTo(x, y + 6)
          ..lineTo(x + 7, y + 13)
          ..lineTo(x, y + 20);
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ChatPreview extends StatelessWidget {
  const _ChatPreview();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: _Bubble(text: 'سلام، قیمت این مدل چنده؟', incoming: true),
        ),
        SizedBox(height: 8),
        _Bubble(text: 'کارت محصول را برایتان فرستادم.', incoming: false),
        SizedBox(height: 6),
        Row(
          children: [
            BrandSymbol(size: 22),
            SizedBox(width: 8),
            Text('پاسخ هوشمند', style: TextStyle(color: Color(0xFFFF7A5C), fontSize: 12, fontWeight: FontWeight.w700)),
          ],
        ),
      ],
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.text, required this.incoming});

  final String text;
  final bool incoming;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: incoming ? const Color(0xFF1C2748) : const Color(0xFF2D4BFF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
    );
  }
}

class _BrandPoint extends StatelessWidget {
  const _BrandPoint({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0x1F8B9BFF),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0x2E8B9BFF)),
            ),
            child: Icon(icon, size: 16, color: const Color(0xFF8B9BFF)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 2),
                Text(body, style: const TextStyle(color: Color(0xFFAEB6CE), fontSize: 13, height: 1.7)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Check extends StatelessWidget {
  const _Check({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.check_circle_outline, size: 16, color: Color(0xFF4ADE80)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: Color(0xFFCDD2E2), fontSize: 13)),
      ],
    );
  }
}

class AuthCard extends StatelessWidget {
  const AuthCard({super.key, required this.title, this.titleWidget, this.description, this.eyebrow, required this.child});

  final String title;
  final Widget? titleWidget;
  final String? description;
  final Widget? eyebrow;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dt = context.dt;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (eyebrow != null) ...[eyebrow!, const SizedBox(height: 16)],
        titleWidget ?? Text(title, textAlign: TextAlign.center, style: TextStyle(fontSize: 28, height: 1.4, fontWeight: FontWeight.w800, color: dt.text)),
        if (description != null) ...[
          const SizedBox(height: 8),
          Text(description!, textAlign: TextAlign.center, style: TextStyle(color: dt.textMuted, height: 1.8, fontSize: 15)),
        ],
        const SizedBox(height: 28),
        child,
      ],
    );
  }
}

class AuthLabel extends StatelessWidget {
  const AuthLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: TextStyle(fontWeight: FontWeight.w700, color: context.dt.text, fontSize: 14)),
    );
  }
}

class AuthField extends StatelessWidget {
  const AuthField({
    super.key,
    required this.controller,
    this.hint,
    this.icon,
    this.keyboardType,
    this.inputFormatters,
    this.textDirection,
    this.onChanged,
    this.hasError = false,
    this.readOnly = false,
    this.fillColor,
    this.minLines = 1,
    this.maxLines = 1,
    this.prefixText,
  });

  final TextEditingController controller;
  final String? hint;
  final IconData? icon;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextDirection? textDirection;
  final ValueChanged<String>? onChanged;
  final bool hasError;
  final bool readOnly;
  final Color? fillColor;
  final int minLines;
  final int maxLines;
  final String? prefixText;

  @override
  Widget build(BuildContext context) {
    final dt = context.dt;
    final borderColor = hasError ? dt.error : const Color(0xFFCDD2E2);
    final radius = BorderRadius.circular(14);
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      textDirection: textDirection,
      onChanged: onChanged,
      readOnly: readOnly,
      minLines: minLines,
      maxLines: maxLines,
      style: TextStyle(fontSize: 16, color: readOnly ? dt.textMuted : dt.text, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        hintText: hint,
        prefixText: prefixText,
        prefixIcon: icon == null ? null : Icon(icon, color: dt.textSubtle, size: 20),
        filled: true,
        fillColor: fillColor ?? dt.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        hintStyle: TextStyle(color: dt.textSubtle, fontWeight: FontWeight.w500, fontSize: 16),
        prefixStyle: TextStyle(color: dt.text, fontWeight: FontWeight.w600, fontSize: 16),
        enabledBorder: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide(color: borderColor)),
        focusedBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: hasError ? dt.error : dt.primary, width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide(color: borderColor)),
      ),
    );
  }
}

class AuthError extends StatelessWidget {
  const AuthError(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFDECEC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.cancel_outlined, color: Color(0xFFE5484D), size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: const TextStyle(color: Color(0xFFE5484D), height: 1.6, fontSize: 14, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}

class AuthPrimaryButton extends StatelessWidget {
  const AuthPrimaryButton({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52), textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      child: Text(label),
    );
  }
}
