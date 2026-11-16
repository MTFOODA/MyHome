import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:myhome_flutter/app/app.dart';
import 'package:myhome_flutter/core/config/settings_cubit.dart';
import 'package:myhome_flutter/features/properties/domain/property_repository.dart';
import 'package:myhome_flutter/features/properties/presentation/property_details_page.dart';
import 'package:myhome_flutter/features/properties/presentation/property_features_grid.dart';
import 'package:myhome_flutter/features/properties/presentation/owner_portfolio_page.dart';
import 'address_details_test.dart' show DetailRepository;
import 'fakes.dart';
import 'onboarding_pricing_test.dart' show tap;
import 'visual_listing_test.dart' show listingOwner, nextStep, completeAddress;

class RenderOwnerRepository extends DetailRepository {
  @override
  Future<OwnerPage> ownerPage(
    String group, {
    String scope = 'current',
    String query = '',
    String availability = 'all',
    String? cursor,
  }) async => OwnerPage(
    [
      for (final record in [
        ('new', 'approved', 'active'),
        ('pending', 'pending', 'active'),
        ('sold', 'approved', 'sold'),
      ])
        PropertySummary(
          id: record.$1,
          title: 'MyHome apartment',
          category: 'sale_cash',
          price: '2010000',
          areaM2: '115',
          locationAr: 'المعادي',
          locationEn: 'Maadi',
          negotiable: false,
          bedrooms: 2,
          bathrooms: 1,
          capacity: null,
          status: record.$2,
          availability: record.$3,
          visitorCount: 24,
          savedCount: 5,
        ),
    ],
    3,
    null,
  );
}

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
  for (final spec in [
    (language: 'ar', dark: true, size: const Size(1440, 1100)),
    (language: 'en', dark: false, size: const Size(1440, 1100)),
    (language: 'ar', dark: false, size: const Size(390, 1100)),
    (language: 'en', dark: true, size: const Size(320, 1100)),
  ]) {
    testWidgets(
      'address and property dashboard ${spec.language} ${spec.size.width}',
      (tester) async {
        tester.view.physicalSize = spec.size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        SharedPreferences.setMockInitialValues({
          'language': spec.language,
          'theme': spec.dark ? 'dark' : 'light',
        });
        final repo = RenderOwnerRepository();
        await tester.pumpWidget(
          RepaintBoundary(
            key: const Key('capture'),
            child: MyHome(
              showIntroduction: false,
              repository: FakeAuthRepository()..restored = listingOwner,
              propertyRepository: repo,
              settings: SettingsCubit(await SharedPreferences.getInstance()),
            ),
          ),
        );
        await tester.pumpAndSettle();
        Future<void> capture(String name) async {
          expect(tester.takeException(), isNull);
          await expectLater(
            find.byKey(const Key('capture')),
            matchesGoldenFile(
              '../../docs/screenshots/address-$name-${spec.size.width.toInt()}-${spec.dark ? 'dark' : 'light'}-${spec.language}.png',
            ),
          );
        }

        tester.state<ScaffoldState>(find.byType(Scaffold).first).openDrawer();
        await tester.pumpAndSettle();
        await tap(tester, find.byKey(const Key('drawerAddProperty')));
        await tap(
          tester,
          find.byKey(const ValueKey('choice-category-sale_cash')),
        );
        await nextStep(tester);
        await tap(
          tester,
          find.byKey(const ValueKey('property-kind-apartment')),
        );
        await nextStep(tester);
        await tap(tester, find.byKey(const Key('listingGovernorate')));
        await tap(
          tester,
          find.text(spec.language == 'ar' ? 'القاهرة' : 'Cairo').last,
        );
        await tap(tester, find.byKey(const Key('listingAreaPicker')));
        await tap(tester, find.byKey(const ValueKey('location-option-maadi')));
        await completeAddress(tester);
        await tester.drag(
          find.byType(SingleChildScrollView).last,
          const Offset(0, 2000),
        );
        await tester.pumpAndSettle();
        await capture('form');
        Navigator.of(
          tester.element(find.byKey(const Key('listingContinue'))),
        ).pop();
        await tester.pumpAndSettle();
        Navigator.of(tester.element(find.byType(Scaffold).first)).push(
          MaterialPageRoute<void>(
            builder: (_) => PropertyDetailsPage(id: 'p1', repository: repo),
          ),
        );
        await tester.pumpAndSettle();
        await capture('details');
        await tester.ensureVisible(find.byType(PropertyFeaturesGrid));
        await tester.pumpAndSettle();
        await capture('facts');
        Navigator.of(tester.element(find.byType(PropertyDetailsPage))).pop();
        await tester.pumpAndSettle();
        Navigator.of(tester.element(find.byType(Scaffold).first)).push(
          MaterialPageRoute<void>(
            builder: (_) =>
                OwnerPortfolioPage(repository: repo, onDetails: (_) {}),
          ),
        );
        await tester.pumpAndSettle();
        await capture('owner');
        final ownerScroll = find
            .descendant(
              of: find.byType(OwnerListingsPage),
              matching: find.byType(Scrollable),
            )
            .last;
        await tester.scrollUntilVisible(
          find.byKey(const ValueKey('interested-pending')),
          300,
          scrollable: ownerScroll,
        );
        await tester.pumpAndSettle();
        await capture('review');
        await tester.scrollUntilVisible(
          find.byKey(const ValueKey('interested-sold')),
          300,
          scrollable: ownerScroll,
        );
        await tester.pumpAndSettle();
        await capture('sold');
      },
    );
  }
}
