import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

class HoldToConfirmButton extends StatefulWidget {
  final String label;
  final Duration duration;
  final VoidCallback onConfirmed;
  final Color? color;
  final Color? textColor;
  final IconData? icon;

  const HoldToConfirmButton({
    super.key,
    required this.label,
    required this.onConfirmed,
    this.duration = const Duration(seconds: 3),
    this.color,
    this.textColor,
    this.icon,
  });

  @override
  State<HoldToConfirmButton> createState() => _HoldToConfirmButtonState();
}

class _HoldToConfirmButtonState extends State<HoldToConfirmButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isHolding = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        HapticFeedback.heavyImpact();
        widget.onConfirmed();
        setState(() => _isHolding = false);
        _controller.reset();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    setState(() => _isHolding = true);
    _controller.forward();
    HapticFeedback.mediumImpact();
  }

  void _onTapUp(TapUpDetails details) {
    if (_controller.status != AnimationStatus.completed) {
      _controller.reverse();
    }
    setState(() => _isHolding = false);
  }

  void _onTapCancel() {
    if (_controller.status != AnimationStatus.completed) {
      _controller.reverse();
    }
    setState(() => _isHolding = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final buttonColor = widget.color ?? theme.colorScheme.primary;
    final onButtonColor = widget.textColor ?? Colors.white;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 64,
        decoration: BoxDecoration(
          color: _isHolding ? buttonColor.withValues(alpha: 0.9) : buttonColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: _isHolding
              ? []
              : [
                  BoxShadow(
                    color: buttonColor.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Progress background
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return FractionallySizedBox(
                    alignment: AlignmentDirectional.centerStart,
                    widthFactor: _controller.value,
                    child: Container(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  );
                },
              ),
            ),

            // Content
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, color: onButtonColor),
                  const SizedBox(width: 12),
                ],
                Text(
                  widget.label,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: onButtonColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            // Helpful overlay when holding
            if (_isHolding)
              Positioned(
                bottom: 8,
                child: Text(
                  'استمر في الضغط للارسال...',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: onButtonColor.withValues(alpha: 0.8),
                    fontSize: 10,
                  ),
                ).animate().fadeIn(),
              ),
          ],
        ),
      ),
    );
  }
}
