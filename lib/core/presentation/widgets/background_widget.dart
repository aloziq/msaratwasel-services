import 'package:flutter/material.dart';
import 'package:msaratwasel_services/config/theme/brand_colors.dart';

class BackgroundWidget extends StatelessWidget {
  const BackgroundWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? BrandColors.primary : Color(0xFFF7F9FC),
      ),
      child: Stack(children: []),
    );
  }
}
