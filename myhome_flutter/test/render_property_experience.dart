import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:myhome_flutter/app/app.dart';
import 'package:myhome_flutter/core/config/settings_cubit.dart';
import 'package:myhome_flutter/features/chat/presentation/chat_page.dart';
import 'package:myhome_flutter/features/properties/presentation/property_details_page.dart';
import 'package:myhome_flutter/features/properties/presentation/property_features_grid.dart';
import 'package:myhome_flutter/features/properties/presentation/similar_properties.dart';
import 'fakes.dart';
import 'property_experience_test.dart'
    show ExperienceRepository, ExperienceChat;

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
      'property and chat reference layout ${spec.language} ${spec.size.width}',
      (tester) async {
        tester.view.physicalSize = spec.size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        SharedPreferences.setMockInitialValues({
          'language': spec.language,
          'theme': spec.dark ? 'dark' : 'light',
        });
        final repo = ExperienceRepository();
        await tester.pumpWidget(
          RepaintBoundary(
            key: const Key('capture'),
            child: MyHome(
              repository: FakeAuthRepository()..restored = account,
              propertyRepository: repo,
              chatRepository: ExperienceChat(),
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
              '../../docs/screenshots/experience-$name-${spec.size.width.toInt()}-${spec.dark ? 'dark' : 'light'}-${spec.language}.png',
            ),
          );
        }

        Navigator.of(tester.element(find.byType(Scaffold).first)).push(
          MaterialPageRoute<void>(
            builder: (_) => PropertyDetailsPage(id: 'p1', repository: repo),
          ),
        );
        await tester.pumpAndSettle();
        await capture('details');
        await tester.ensureVisible(find.byType(PropertyFeaturesGrid));
        await tester.pumpAndSettle();
        await capture('features');
        await tester.ensureVisible(find.byType(SimilarProperties));
        await tester.pumpAndSettle();
        await capture('similar');
        Navigator.of(tester.element(find.byType(PropertyDetailsPage))).pop();
        await tester.pumpAndSettle();
        Navigator.of(tester.element(find.byType(Scaffold).first)).push(
          MaterialPageRoute<void>(
            builder: (_) => const ChatPage(propertyId: 'p1'),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.text(spec.language == 'ar' ? 'رسائل سريعة' : 'Quick messages'),
        );
        await tester.pumpAndSettle();
        await capture('chat');
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}
