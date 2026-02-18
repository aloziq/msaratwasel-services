import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Omani Rial symbol widget following official brand guidelines:
/// 1. Position: Symbol to the left of numeral values
/// 2. Spacing: Required space between symbol and numeral
/// 3. Proportions: Maintains the original shape
/// 4. Geometry: Preserves geometric structure
/// 5. Alignment: Symbol height aligned with text height
/// 6. Direction: Matches text direction (RTL/LTR)
/// 7. Clear Space: Protective empty area around symbol
/// 8. Contrast: Sufficient color contrast with background
class OmaniRialIcon extends StatelessWidget {
  const OmaniRialIcon({super.key, this.size = 24, this.color});

  /// Size of the icon (width and height)
  final double size;

  /// Color of the icon. If null, uses theme's onSurface color
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
/// following official brand guidelines
class OmaniRialAmount extends StatelessWidget {
  const OmaniRialAmount({
    super.key,
    required this.amount,
    this.iconSize = 20,
    this.textStyle,
    this.iconColor,
    this.spacing = 6,
  });

  /// The amount to display
  final String amount;

  /// Size of the OMR icon
  final double iconSize;

  /// Text style for the amount
  final TextStyle? textStyle;

  /// Color of the OMR icon
  final Color? iconColor;

  /// Spacing between icon and amount (المسافة)
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
      crossAxisAlignment: CrossAxisAlignment.center, // المحاذاة
      children: [
        // الرمز يكون يسار القيمة العددية (الموقع)
        OmaniRialIcon(size: iconSize, color: effectiveIconColor),
        // المسافة بين الرمز والقيم العددية
        SizedBox(width: spacing),
        // القيمة العددية
        Text(amount, style: effectiveTextStyle),
      ],
    );
  }
}
