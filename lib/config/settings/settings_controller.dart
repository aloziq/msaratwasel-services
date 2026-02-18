import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsController extends ChangeNotifier {
  static const _localeKey = 'app_locale';
  static const _fontScaleKey = 'app_font_scale';

  /// null means "follow system locale"
  Locale? _locale;
  Locale? get locale => _locale;

  /// Whether the locale is set to follow the system
  bool get isSystemLocale => _locale == null;

  double _fontScale = 1.0;
  double get fontScale => _fontScale;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(_localeKey);
    final savedFontScale = prefs.getDouble(_fontScaleKey);

    // 'system' or absent → null (follow system)
    if (languageCode != null && languageCode != 'system') {
      _locale = Locale(languageCode);
    } else {
      _locale = null; // follow system
    }

    if (savedFontScale != null) {
      _fontScale = savedFontScale.clamp(0.8, 1.4);
    }

    notifyListeners();
  }

  /// Set locale. Pass null to follow the system locale.
  Future<void> setLocale(Locale? locale) async {
    if (_locale == locale) return;

    _locale = locale;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, locale?.languageCode ?? 'system');
  }

  Future<void> setFontScale(double scale) async {
    final clamped = scale.clamp(0.8, 1.4);
    if (_fontScale == clamped) return;

    _fontScale = clamped;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_fontScaleKey, clamped);
  }
}

class SettingsProvider extends InheritedNotifier<SettingsController> {
  const SettingsProvider({
    super.key,
    required SettingsController controller,
    required super.child,
  }) : super(notifier: controller);

  static SettingsController of(BuildContext context) {
    final provider = context
        .dependOnInheritedWidgetOfExactType<SettingsProvider>();
    if (provider == null || provider.notifier == null) {
      throw FlutterError(
        'SettingsController not found in context. Ensure SettingsProvider is above this widget.',
      );
    }
    return provider.notifier!;
  }
}
