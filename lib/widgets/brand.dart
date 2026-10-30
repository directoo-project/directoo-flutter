import 'package:flutter/material.dart';

class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.height = 32, this.onDark = false});

  final double height;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final dark = onDark || Theme.of(context).brightness == Brightness.dark;
    return Image.asset(
      dark ? 'assets/brand/logo-fa-light.png' : 'assets/brand/logo-fa-color.png',
      height: height,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
    );
  }
}

class BrandSymbol extends StatelessWidget {
  const BrandSymbol({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/brand/symbol.png',
      width: size,
      height: size,
      filterQuality: FilterQuality.high,
    );
  }
}
