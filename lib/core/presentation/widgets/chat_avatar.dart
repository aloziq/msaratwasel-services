import 'package:flutter/material.dart';
import 'package:msaratwasel_services/core/network/api_config.dart';

class ChatAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String name;
  final double radius;

  const ChatAvatar({
    super.key,
    required this.avatarUrl,
    required this.name,
    this.radius = 24,
  });

  String get _initial {
    if (name.isEmpty) return '؟';
    final runes = name.runes.toList();
    return runes.isEmpty ? '؟' : String.fromCharCode(runes.first);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = radius * 2;

    Widget fallback = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          _initial,
          style: TextStyle(
            color: theme.colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.bold,
            fontSize: radius * 0.75,
          ),
        ),
      ),
    );

    final resolvedUrl = avatarUrl != null
        ? ApiConfig.getImageUrl(avatarUrl)
        : null;

    if (resolvedUrl == null) return fallback;

    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: Image.network(
          resolvedUrl,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              color: theme.colorScheme.primaryContainer,
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: theme.colorScheme.primary,
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                ),
              ),
            );
          },
          errorBuilder: (_, _, _) => fallback,
        ),
      ),
    );
  }
}
