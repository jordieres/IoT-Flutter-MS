import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static const List<Locale> supportedLocales = [
    Locale('en', ''),
    Locale('es', ''),
  ];

  static const LocalizationsDelegate<AppLocalizations> delegate = AppLocalizationsDelegate();

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'title': 'Healthy Wear',
      'id_number': 'ID Number',
    },
    'es': {
      'title': 'HealthyWear ',
      'id_number': 'Número de Referencia',
    },
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? 'Key not found: $key';
  }

  String get title {
    return _localizedValues[locale.languageCode]!['title']!;
  }

  String get idNumber {
    return _localizedValues[locale.languageCode]!['id_number']!;
  }
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'es'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    print("Loading locale: $locale");
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;

  static AppLocalizationsDelegate get delegate => AppLocalizationsDelegate();
}
