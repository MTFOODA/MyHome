import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/config/locale_config.dart';
import '../core/config/settings_cubit.dart';
import '../core/config/theme_config.dart';
import '../core/di/locator.dart';
import '../features/auth/domain/auth_repository.dart';
import '../features/auth/presentation/auth_cubit.dart';
import '../features/auth/presentation/auth_page.dart';
import '../features/auth/presentation/intents_page.dart';
import '../features/home/home_page.dart';
import '../features/properties/domain/property_repository.dart';
import '../localizations/app_localizations.dart';

class MyHome extends StatelessWidget {
  final AuthRepository? repository;
  final PropertyRepository? propertyRepository;
  final SettingsCubit? settings;
  const MyHome({
    super.key,
    this.repository,
    this.settings,
    this.propertyRepository,
  });
  @override
  Widget build(BuildContext context) => MultiBlocProvider(
    providers: [
      BlocProvider(
        create: (_) =>
            AuthCubit(repository ?? locator<AuthRepository>())..restore(),
      ),
      BlocProvider(
        create: (_) => settings ?? SettingsCubit(locator<SharedPreferences>()),
      ),
    ],
    child: RepositoryProvider<PropertyRepository>.value(
      value: propertyRepository ?? locator<PropertyRepository>(),
      child: BlocBuilder<SettingsCubit, AppSettings>(
        builder: (context, state) => MaterialApp(
          debugShowCheckedModeBanner: false,
          onGenerateTitle: (context) => context.l10n.appName,
          theme: ThemeConfig.lightTheme(),
          darkTheme: ThemeConfig.darkTheme(),
          themeMode: state.themeMode,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: LocaleConfig.supported,
          locale: state.locale,
          home: const _PublicHomeGate(),
        ),
      ),
    ),
  );
}

class _PublicHomeGate extends StatelessWidget {
  const _PublicHomeGate();
  @override
  Widget build(BuildContext context) => BlocBuilder<AuthCubit, AuthState>(
    builder: (context, state) {
      if (state.account != null && !state.account!.onboardingComplete) {
        return const IntentsPage();
      }
      // Restoring/offline sessions never block public property discovery.
      return const HomePage();
    },
  );
}

Future<bool> requireSignIn(BuildContext context) async {
  if (context.read<AuthCubit>().state.account != null) return true;
  await Navigator.push<void>(
    context,
    MaterialPageRoute(
      builder: (routeContext) => BlocListener<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state.account != null && state.status == AuthStatus.signedIn) {
            Navigator.of(routeContext).pop();
          }
        },
        child: AuthPage(onGuest: () => Navigator.of(routeContext).pop()),
      ),
    ),
  );
  if (!context.mounted) return false;
  return context.read<AuthCubit>().state.account != null;
}
