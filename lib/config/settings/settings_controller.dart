import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsController extends ChangeNotifier {
  static const _localeKey = 'app_locale';

  Locale _locale = const Locale('ar'); // Default to Arabic
  Locale get locale => _locale;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(_localeKey);

    if (languageCode != null) {
      _locale = Locale(languageCode);
      notifyListeners();
    }
  }

  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;

    _locale = locale;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, locale.languageCode);
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
