## AppLocal.dart

```{contents}
:depth: 2
:local:
```

### Purpose

This file implements Flutter localization using a custom `AppLocalizations` class and a corresponding `LocalizationsDelegate`. It provides localized strings for English and Spanish, allowing the HealthyWear app to display UI elements in multiple languages.

---

### Localization Entry Point

```dart
class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);
```

- Holds the current locale.
- Serves as the lookup class for localized values.

---

### Supported Locales

```dart
static const List<Locale> supportedLocales = [
  Locale('en', ''),
  Locale('es', ''),
];
```

These define which languages the app supports.

---

### Localization Delegate

```dart
static const LocalizationsDelegate<AppLocalizations> delegate = AppLocalizationsDelegate();
```

Used in `MaterialApp` to load localized content via `AppLocalizationsDelegate`.

---

### Localized Values

```dart
static Map<String, Map<String, String>> _localizedValues = {
  'en': {'title': 'Healthy Wear', 'id_number': 'ID Number'},
  'es': {'title': 'HealthyWear ', 'id_number': 'Número de Referencia'},
};
```

- Stores translatable strings keyed by language code (`'en'`, `'es'`).
- Custom method `translate(String key)` fetches translations dynamically.

---

### Translation Accessors

```dart
String get title
String get idNumber
```

Convenient property-style access for common fields in the app.

---

### Usage

Use anywhere in a widget tree:

```dart
AppLocalizations.of(context)?.translate('title')
AppLocalizations.of(context)?.idNumber
```

---

### Custom Localization Delegate

```dart
class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations>
```

Defines how `AppLocalizations` is loaded.

#### Key Methods:
- `isSupported()`: Checks if the locale is supported
- `load()`: Loads the `AppLocalizations` instance
- `shouldReload()`: Controls delegate rebuild behavior (always false)

---

### Integration in Flutter App

You should wire this into your `MaterialApp` like so:

```dart
MaterialApp(
  localizationsDelegates: [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: AppLocalizations.supportedLocales,
)
```

This will enable multilingual support in your HealthyWear app.

