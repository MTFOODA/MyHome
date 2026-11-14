import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  final Locale locale;
  final ThemeMode themeMode;
  const AppSettings(this.locale, this.themeMode);
}

class SettingsCubit extends Cubit<AppSettings> {
  final SharedPreferences preferences;
  SettingsCubit(this.preferences)
    : super(
        AppSettings(
          Locale(preferences.getString('language') == 'ar' ? 'ar' : 'en'),
          ThemeMode.values.firstWhere(
            (value) => value.name == preferences.getString('theme'),
            orElse: () => ThemeMode.system,
          ),
        ),
      );
  Future<void> toggleLanguage() async {
    final language = state.locale.languageCode == 'ar' ? 'en' : 'ar';
    emit(AppSettings(Locale(language), state.themeMode));
    await preferences.setString('language', language);
  }

  Future<void> setTheme(ThemeMode mode) async {
    emit(AppSettings(state.locale, mode));
    await preferences.setString('theme', mode.name);
  }
}
