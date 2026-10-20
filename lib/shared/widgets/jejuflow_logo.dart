import 'package:flutter/material.dart';

/// The shared brand image; hide its semantics beside an equivalent wordmark.
class JejuFlowLogo extends StatelessWidget {
  const JejuFlowLogo({
    super.key,
    this.size = 48,
    this.decorative = false,
  });

  static const assetPath = 'assets/branding/jejuflow-logo.png';

  final double size;
  final bool decorative;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      semanticLabel: decorative ? null : 'JEJUFLOW',
      excludeFromSemantics: decorative,
    );
  }
}
