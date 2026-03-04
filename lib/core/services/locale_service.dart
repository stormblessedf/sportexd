import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleOption {
  final Locale locale;
  final String name;
  final String flag;

  const LocaleOption({
    required this.locale,
    required this.name,
    required this.flag,
  });
}

class LocaleService extends ChangeNotifier {
  static const String _prefKey = 'app_locale';

  Locale _locale = const Locale('tr');
  Locale get locale => _locale;

  static const List<LocaleOption> supportedLocales = [
    LocaleOption(locale: Locale('tr'), name: 'Türkçe', flag: '🇹🇷'),
    LocaleOption(locale: Locale('en'), name: 'English', flag: '🇬🇧'),
    LocaleOption(locale: Locale('de'), name: 'Deutsch', flag: '🇩🇪'),
    LocaleOption(locale: Locale('fr'), name: 'Français', flag: '🇫🇷'),
    LocaleOption(locale: Locale('es'), name: 'Español', flag: '🇪🇸'),
    LocaleOption(locale: Locale('ar'), name: 'العربية', flag: '🇸🇦'),
  ];

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_prefKey);
    if (code != null) {
      _locale = Locale(code);
      notifyListeners();
    }
  }

  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;
    _locale = locale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, locale.languageCode);
  }

  LocaleOption get currentOption => supportedLocales.firstWhere(
        (o) => o.locale.languageCode == _locale.languageCode,
        orElse: () => supportedLocales.first,
      );
}
