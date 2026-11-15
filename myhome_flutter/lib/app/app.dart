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
import '../features/properties/domain/location_repository.dart';
import '../core/widgets/app_backdrop.dart';
import '../features/sales/domain/sales_repository.dart';
import '../features/chat/domain/chat_repository.dart';
import '../localizations/app_localizations.dart';

class MyHome extends StatelessWidget {
  final AuthRepository? repository;
  final PropertyRepository? propertyRepository;
  final SalesRepository? salesRepository;
  final ChatRepository? chatRepository;
  final SettingsCubit? settings;
  final LocationRepository? locationRepository;
  const MyHome({
    super.key,
    this.repository,
    this.settings,
    this.locationRepository,
    this.propertyRepository,
    this.salesRepository,
    this.chatRepository,
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
    child: MultiRepositoryProvider(
      providers: [
        if (locationRepository != null ||
            locator.isRegistered<LocationRepository>())
          RepositoryProvider<LocationRepository>.value(
            value: locationRepository ?? locator<LocationRepository>(),
          ),
        RepositoryProvider<PropertyRepository>.value(
          value: propertyRepository ?? locator<PropertyRepository>(),
        ),
        if (salesRepository != null || locator.isRegistered<SalesRepository>())
          RepositoryProvider<SalesRepository>.value(
            value: salesRepository ?? locator<SalesRepository>(),
          ),
        if (chatRepository != null || locator.isRegistered<ChatRepository>())
          RepositoryProvider<ChatRepository>.value(
            value: chatRepository ?? locator<ChatRepository>(),
          ),
      ],
      child: BlocBuilder<SettingsCubit, AppSettings>(
        builder: (context, state) => LayoutBuilder(
          builder: (context, constraints) => MaterialApp(
            debugShowCheckedModeBanner: false,
            builder: (context, child) =>
                AppBackdrop(child: child ?? const SizedBox.shrink()),
            onGenerateTitle: (context) => context.l10n.appName,
            theme: ThemeConfig.lightTheme(viewportWidth: constraints.maxWidth),
            darkTheme: ThemeConfig.darkTheme(
              viewportWidth: constraints.maxWidth,
            ),
            themeMode: state.themeMode,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: LocaleConfig.supported,
            locale: state.locale,
            home: const _PublicHomeGate(),
          ),
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
