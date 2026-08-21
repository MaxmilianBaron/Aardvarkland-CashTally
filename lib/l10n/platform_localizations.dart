import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Flutter does not ship Material/Cupertino framework strings for
/// Luxembourgish (`lb`) or Maltese (`mt`). The application strings remain in
/// the selected language while
/// framework-only labels (for example the back-button tooltip) use Flutter's
/// safe English defaults instead of leaving the widget tree without
/// MaterialLocalizations and crashing.
class AppMaterialFallbackLocalizationsDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const AppMaterialFallbackLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      const {'lb', 'mt'}.contains(locale.languageCode);

  @override
  Future<MaterialLocalizations> load(Locale locale) =>
      SynchronousFuture<MaterialLocalizations>(
        const DefaultMaterialLocalizations(),
      );

  @override
  bool shouldReload(AppMaterialFallbackLocalizationsDelegate old) => false;
}

class AppCupertinoFallbackLocalizationsDelegate
    extends LocalizationsDelegate<CupertinoLocalizations> {
  const AppCupertinoFallbackLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      const {'lb', 'mt'}.contains(locale.languageCode);

  @override
  Future<CupertinoLocalizations> load(Locale locale) =>
      SynchronousFuture<CupertinoLocalizations>(
        const DefaultCupertinoLocalizations(),
      );

  @override
  bool shouldReload(AppCupertinoFallbackLocalizationsDelegate old) => false;
}
