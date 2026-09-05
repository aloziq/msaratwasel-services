import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:msaratwasel_services/config/theme/app_colors.dart';

class BackgroundWidget extends StatelessWidget {
  const BackgroundWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Stack(
      children: [
        // Base gradient
        Container(
          decoration: BoxDecoration(
            gradient: isDark
                ? const LinearGradient(
                    colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : const LinearGradient(
                    colors: [Color(0xFFF0F4F8), Color(0xFFE2E8F0)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
          ),
        ),
        // Orb 1 (Top Left) - More subtle
        Positioned(
          top: -100,
          left: -100,
          child: _AnimatedOrb(
            color: AppColors.primary.withValues(alpha: 0.15),
            size: 400,
          ),
        ),
        // Orb 2 (Bottom Right) - More subtle
        Positioned(
          bottom: -50,
          right: -50,
          child: _AnimatedOrb(
            color: AppColors.secondary.withValues(alpha: 0.1),
            size: 300,
            delay: const Duration(seconds: 2),
          ),
        ),
        // Orb 3 (Center-ish) - More subtle
        Positioned(
          top: 200,
          right: -100,
          child: _AnimatedOrb(
            color: AppColors.primaryDark.withValues(alpha: 0.08),
            size: 250,
            delay: const Duration(seconds: 4),
          ),
        ),
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
            child: Container(color: Colors.transparent),
          ),
        ),
      ],
    );
  }
}

class _AnimatedOrb extends StatefulWidget {
  final Color color;
  final double size;
  final Duration delay;

  const _AnimatedOrb({
    required this.color,
    required this.size,
    this.delay = Duration.zero,
  });

  @override
  State<_AnimatedOrb> createState() => _AnimatedOrbState();
}

class _AnimatedOrbState extends State<_AnimatedOrb>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Timer? _delayTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );

    if (widget.delay == Duration.zero) {
      _controller.repeat(reverse: true);
    } else {
      _delayTimer = Timer(widget.delay, () {
        if (mounted) _controller.repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
            0,
            20 * _controller.value, // Floating effect
          ),
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.color,
            ),
          ),
        );
      },
    );
  }
}
