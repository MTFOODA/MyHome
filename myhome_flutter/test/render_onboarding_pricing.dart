import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:myhome_flutter/app/app.dart';
import 'package:myhome_flutter/core/config/settings_cubit.dart';
import 'package:myhome_flutter/core/config/marketplace_strings.dart';
import 'package:myhome_flutter/core/config/theme_config.dart';
import 'package:myhome_flutter/features/auth/domain/auth_repository.dart';
import 'package:myhome_flutter/features/properties/presentation/listing_cubit.dart';
import 'package:myhome_flutter/features/properties/presentation/listing_pricing_step.dart';
import 'package:myhome_flutter/localizations/app_localizations.dart';
import 'fake_property_repository.dart';
import 'fakes.dart';
import 'onboarding_pricing_test.dart' show CalculatorRepository, calculate;
import 'pricing_test_data.dart';

void main() {
  setUpAll(() async {
    for (final entry in {
      'MaterialIcons':
          'C:/flutter/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
      'Roboto': 'C:/Windows/Fonts/segoeui.ttf',
    }.entries) {
      final bytes = await File(entry.value).readAsBytes();
      await (FontLoader(
        entry.key,
      )..addFont(Future.value(ByteData.sublistView(bytes)))).load();
    }
  });
  for (final language in ['ar', 'en']) {
    for (final dark in [false, true]) {
      testWidgets('onboarding and final calculator $language dark=$dark', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(390, 1100);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        Future<void> capture(String name) async {
          expect(tester.takeException(), isNull);
          await expectLater(
            find.byKey(const Key('preview-pricing')),
            matchesGoldenFile(
              '../../docs/screenshots/$name-${dark ? 'dark-' : ''}$language.png',
            ),
          );
        }

        SharedPreferences.setMockInitialValues({
          'language': language,
          'theme': dark ? 'dark' : 'light',
        });
        await tester.pumpWidget(
          RepaintBoundary(
            key: const Key('preview-pricing'),
            child: MyHome(
              key: UniqueKey(),
              repository: FakeAuthRepository()
                ..restored = const Account(
                  id: 'new',
                  name: 'Demo',
                  email: 'demo@example.com',
                  role: 'user',
                  ownerVerified: false,
                  onboardingComplete: false,
                ),
              propertyRepository: FakePropertyRepository(),
              settings: SettingsCubit(await SharedPreferences.getInstance()),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await capture('roles');
        await tester.tap(find.byKey(const ValueKey('family_owner')));
        await tester.pumpAndSettle();
        await capture('roles-owner');
        for (final scenario in ['sale', 'private', 'shared', 'old']) {
          final category = scenario == 'sale'
              ? 'sale_cash'
              : scenario == 'shared'
              ? 'shared_rental'
              : 'private_rental';
          final snapshot = scenario == 'sale'
              ? saleQuote
              : scenario == 'shared'
              ? sharedQuote
              : scenario == 'old'
              ? oldRentQuote
              : rentalQuote;
          final repo = CalculatorRepository()..response = (_) async => snapshot;
          final cubit = ListingCubit(repo)
            ..values.addAll({
              'category': category,
              'area_id': 'maadi',
              'price': scenario == 'sale'
                  ? '2000000'
                  : scenario == 'shared'
                  ? '3000'
                  : scenario == 'old'
                  ? '10000'
                  : '12000',
              'rental_period': scenario == 'old' ? 'old_rent' : 'one_year',
              'total_beds': '4',
              'deposit': '0',
              'negotiable': false,
            });
          await tester.pumpWidget(
            RepaintBoundary(
              key: const Key('preview-pricing'),
              child: MaterialApp(
                key: UniqueKey(),
                debugShowCheckedModeBanner: false,
                locale: Locale(language),
                supportedLocales: AppLocalizations.supportedLocales,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                theme: dark
                    ? ThemeConfig.darkTheme()
                    : ThemeConfig.lightTheme(),
                home: Builder(
                  builder: (context) => Scaffold(
                    appBar: AppBar(title: Text(words(context, 'addProperty'))),
                    body: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const LinearProgressIndicator(value: 1),
                            const SizedBox(height: 12),
                            Text(
                              '${cubit.steps.length} / ${cubit.steps.length}',
                            ),
                            const SizedBox(height: 24),
                            Text(
                              words(context, 'pricingFinal'),
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 24),
                            ListingPricingStep(
                              cubit: cubit,
                              repository: repo,
                              onReadyChanged: (_) {},
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          await calculate(tester);
          await capture('pricing-$scenario');
          await tester.pumpWidget(const SizedBox());
          await tester.pumpAndSettle();
          await cubit.close();
        }
      });
    }
  }
}
