import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class OmaniRialIcon extends StatelessWidget {
  const OmaniRialIcon({super.key, this.size = 24, this.color});

  final double size;

  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor =
        color ?? theme.colorScheme.onSurface.withValues(alpha: 0.7);

    return SvgPicture.asset(
      'assets/icons/msarticon/RO.svg',
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(effectiveColor, BlendMode.srcIn),
    );
  }
}

/// A widget that displays an amount with the Omani Rial symbol
class OmaniRialAmount extends StatelessWidget {
  const OmaniRialAmount({
    super.key,
    required this.amount,
    this.iconSize = 20,
    this.textStyle,
    this.iconColor,
    this.spacing = 6,
  });

  final String amount;
  final double iconSize;
  final TextStyle? textStyle;
  final Color? iconColor;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveTextStyle =
        textStyle ??
        theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold);
    final effectiveIconColor =
        iconColor ?? effectiveTextStyle?.color ?? theme.colorScheme.onSurface;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        OmaniRialIcon(size: iconSize, color: effectiveIconColor),
        SizedBox(width: spacing),
        Text(amount, style: effectiveTextStyle),
      ],
    );
  }
}
