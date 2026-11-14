import 'package:flutter/material.dart';
import '../../localizations/app_localizations.dart';

class LocaleConfig {
  static const supported = [Locale('en'), Locale('ar')];
}

extension LocalizedContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}
