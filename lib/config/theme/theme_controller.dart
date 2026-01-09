import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends ChangeNotifier {
  static const _storageKey = 'theme_mode';

  ThemeMode _mode = ThemeMode.system;
  ThemeMode get mode => _mode;

  /// Must be called once before runApp
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    String? value;
    try {
      value = prefs.getString(_storageKey);
    } catch (e) {
      // Handle type mismatch if key exists but is not a String
      debugPrint('Error loading theme: $e');
      await prefs.remove(_storageKey);
    }

    _mode = _fromString(value);
    notifyListeners();
  }

  /// Change theme mode and persist it
  Future<void> setMode(ThemeMode mode) async {
    if (_mode == mode) return;

    _mode = mode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, _toString(mode));
  }

  // ---- helpers ----

  ThemeMode _fromString(String? value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  String _toString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
}

/// Provider to pass ThemeController down the tree and trigger rebuilds.
class ThemeProvider extends InheritedNotifier<ThemeController> {
  const ThemeProvider({
    super.key,
    required ThemeController controller,
    required super.child,
  }) : super(notifier: controller);

  static ThemeController of(BuildContext context) {
    final provider = context
        .dependOnInheritedWidgetOfExactType<ThemeProvider>();
    if (provider == null || provider.notifier == null) {
      throw FlutterError(
        'ThemeController not found in context. Ensure ThemeProvider is above this widget.',
      );
    }
    return provider.notifier!;
  }
}
