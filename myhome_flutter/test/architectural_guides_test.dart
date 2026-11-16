import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhome_flutter/core/widgets/app_layout.dart';
import 'package:myhome_flutter/core/widgets/architectural_backdrop.dart';
import 'package:myhome_flutter/core/widgets/app_backdrop.dart';
import 'package:myhome_flutter/core/config/theme_config.dart';
import 'package:myhome_flutter/features/support/guide_content.dart';
import 'package:myhome_flutter/features/support/info_page.dart';
import 'package:myhome_flutter/features/support/introduction_page.dart';
import 'package:myhome_flutter/localizations/app_localizations.dart';
import 'onboarding_pricing_test.dart' show tap;

Widget sceneApp(
  Widget page,
  String language,
  bool dark, {
  bool reduceMotion = false,
  double width = 390,
}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  locale: Locale(language),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  theme: dark
      ? ThemeConfig.darkTheme(viewportWidth: width)
      : ThemeConfig.lightTheme(viewportWidth: width),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
    child: AppBackdrop(child: child!),
  ),
  home: page,
);

void main() {
  test('all header and presenter assets are bundled for offline use', () async {
    for (final asset in [
      ...ArchitecturalScene.values.map((scene) => scene.asset),
      ...GuidePose.values.map((pose) => pose.asset),
    ]) {
      expect((await rootBundle.load(asset)).lengthInBytes, greaterThan(1000));
    }
    expect(GuidePose.values.map((pose) => pose.asset).toSet().length, 4);
  });
  test('section order alternates the two presenters and their poses', () {
    expect(List.generate(7, (index) => GuidePose.forSection(index).character), [
      'olive',
      'blazer',
      'olive',
      'blazer',
      'olive',
      'blazer',
      'olive',
    ]);
  });
  for (final language in ['ar', 'en']) {
    for (final dark in [false, true]) {
      testWidgets(
        'decorative header keeps controls interactive $language dark=$dark',
        (tester) async {
          var tapped = false;
          await tester.pumpWidget(
            sceneApp(
              AppScaffold(
                scene: ArchitecturalScene.corner,
                body: Center(
                  child: FilledButton(
                    onPressed: () => tapped = true,
                    child: const Text('Action'),
                  ),
                ),
              ),
              language,
              dark,
            ),
          );
          await tester.pumpAndSettle();
          await tester.tap(find.text('Action'));
          expect(tapped, isTrue);
          expect(
            tester
                .widget<ArchitecturalBackdrop>(
                  find.byType(ArchitecturalBackdrop),
                )
                .scene,
            ArchitecturalScene.corner,
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
    testWidgets('only first introduction combines presenters $language', (
      tester,
    ) async {
      await tester.pumpWidget(
        sceneApp(const IntroductionPage(), language, false, reduceMotion: true),
      );
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('intro-browse')),
          matching: find.byType(GuidePresenters),
        ),
        findsOneWidget,
      );
      await tap(tester, find.byKey(const Key('nextIntroduction')));
      final second = find.byKey(const ValueKey('intro-list'));
      expect(
        find.descendant(of: second, matching: find.byType(GuidePresenters)),
        findsNothing,
      );
      expect(
        tester
            .widget<GuidePresenter>(
              find.descendant(
                of: second,
                matching: find.byType(GuidePresenter),
              ),
            )
            .pose
            .character,
        'olive',
      );
      await tap(tester, find.byKey(const Key('nextIntroduction')));
      final third = find.byKey(const ValueKey('intro-connect'));
      expect(
        find.descendant(of: third, matching: find.byType(GuidePresenters)),
        findsNothing,
      );
      expect(
        tester
            .widget<GuidePresenter>(
              find.descendant(of: third, matching: find.byType(GuidePresenter)),
            )
            .pose
            .character,
        'blazer',
      );
      expect(tester.takeException(), isNull);
    });
    for (final about in [false, true]) {
      testWidgets(
        'each explanation has one adjacent alternating presenter on a narrow phone $language about=$about',
        (tester) async {
          tester.view.physicalSize = const Size(320, 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          await tester.pumpWidget(
            sceneApp(InfoPage(about: about), language, true),
          );
          await tester.pumpAndSettle();
          expect(find.byType(GuidePresenters), findsNothing);
          final sections = find.byType(GuideExplanation);
          expect(sections, findsNWidgets(7));
          for (var index = 0; index < 7; index++) {
            final section = sections.at(index);
            final presenter = find.descendant(
              of: section,
              matching: find.byType(GuidePresenter),
            );
            final explanation = find
                .descendant(of: section, matching: find.byType(Text))
                .last;
            expect(presenter, findsOneWidget);
            final pictureRect = tester.getRect(presenter),
                textRect = tester.getRect(explanation);
            expect(pictureRect.overlaps(textRect), isFalse);
            expect(
              pictureRect.center.dy,
              inInclusiveRange(
                tester.getRect(section).top,
                tester.getRect(section).bottom,
              ),
            );
          }
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
