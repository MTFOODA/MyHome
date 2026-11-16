import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:myhome_flutter/app/app.dart';
import 'package:myhome_flutter/core/config/settings_cubit.dart';
import 'package:myhome_flutter/features/auth/domain/auth_repository.dart';
import 'fakes.dart';
import 'fake_property_repository.dart';
import 'package:myhome_flutter/features/chat/domain/chat_repository.dart';

Future<void> launch(
  WidgetTester tester,
  FakeAuthRepository repo, {
  String language = 'en',
  Size size = const Size(390, 844),
  FakePropertyRepository? properties,
  ChatRepository? chat,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  SharedPreferences.setMockInitialValues({'language': language});
  await tester.pumpWidget(
    MyHome(
      showIntroduction: false,
      repository: repo,
      propertyRepository: properties ?? FakePropertyRepository(),
      chatRepository: chat,
      settings: SettingsCubit(await SharedPreferences.getInstance()),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> signIn(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('openSignIn')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'new account completes multi-role onboarding after registration',
    (tester) async {
      final repo = FakeAuthRepository()
        ..registeredAccount = const Account(
          id: 'new',
          name: 'New User',
          email: 'new@example.com',
          role: 'user',
          ownerVerified: false,
          onboardingComplete: false,
        );
      await launch(tester, repo);
      await signIn(tester);
      await tester.ensureVisible(find.byKey(const Key('toggleAuth')));
      await tester.tap(find.byKey(const Key('toggleAuth')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('name')), 'New User');
      await tester.enterText(find.byKey(const Key('email')), 'new@example.com');
      await tester.enterText(find.byKey(const Key('password')), 'password-123');
      await tester.enterText(find.byKey(const Key('confirm')), 'password-123');
      await tester.ensureVisible(find.byKey(const Key('submitAuth')));
      await tester.tap(find.byKey(const Key('submitAuth')));
      await tester.pumpAndSettle();
      expect(find.text('How will you use MyHome?'), findsOneWidget);
      final continueButton = tester.widget<FilledButton>(
        find.byKey(const Key('saveIntents')),
      );
      expect(continueButton.onPressed, isNull);
      expect(find.text('Transparent final price'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('family_owner')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey('intent_owner_private_rental')),
      );
      await tester.tap(
        find.byKey(const ValueKey('intent_owner_private_rental')),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const ValueKey('family_seeker')));
      await tester.tap(find.byKey(const ValueKey('family_seeker')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey('intent_tenant_shared')),
      );
      await tester.tap(find.byKey(const ValueKey('intent_tenant_shared')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('saveIntents')));
      await tester.tap(find.byKey(const Key('saveIntents')));
      await tester.pumpAndSettle();
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.text('Find roommates'), findsNothing);
    },
  );
  testWidgets(
    'home is public, sign-in validates fields and logout preserves public home',
    (tester) async {
      final repo = FakeAuthRepository();
      await launch(tester, repo);
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.text('Find roommates'), findsNothing);
      expect(find.text('Welcome back'), findsNothing);
      await signIn(tester);
      await tester.ensureVisible(find.byKey(const Key('submitAuth')));
      await tester.tap(find.byKey(const Key('submitAuth')));
      await tester.pumpAndSettle();
      expect(repo.loginCalls, 0);
      expect(
        find.text('Use your email, or fooda / amr for an administrator.'),
        findsOneWidget,
      );
      await tester.enterText(
        find.byKey(const Key('email')),
        'mariam@example.com',
      );
      await tester.enterText(find.byKey(const Key('password')), 'password-123');
      await tester.ensureVisible(find.byKey(const Key('submitAuth')));
      await tester.tap(find.byKey(const Key('submitAuth')));
      await tester.pumpAndSettle();
      expect(repo.loginCalls, 1);
      expect(find.byKey(const Key('openSignIn')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('navigation-account')));
      await tester.pumpAndSettle();
      expect(find.text('Mariam Ahmed'), findsWidgets);
      await tester.ensureVisible(find.byKey(const Key('logout')));
      await tester.tap(find.byKey(const Key('logout')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('openSignIn')), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);
    },
  );
  testWidgets(
    'registration validates confirmation and roles are not chosen before sign-up',
    (tester) async {
      final repo = FakeAuthRepository();
      await launch(tester, repo);
      await signIn(tester);
      await tester.ensureVisible(find.byKey(const Key('toggleAuth')));
      await tester.tap(find.byKey(const Key('toggleAuth')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('name')), 'Mariam Ahmed');
      await tester.enterText(
        find.byKey(const Key('email')),
        'mariam@example.com',
      );
      await tester.enterText(find.byKey(const Key('password')), 'password-123');
      await tester.enterText(find.byKey(const Key('confirm')), 'wrong');
      await tester.ensureVisible(find.byKey(const Key('submitAuth')));
      await tester.tap(find.byKey(const Key('submitAuth')));
      await tester.pumpAndSettle();
      expect(find.text('Passwords do not match.'), findsOneWidget);
      expect(repo.registerCalls, 0);
      expect(find.byKey(const Key('role')), findsNothing);
      await tester.enterText(find.byKey(const Key('confirm')), 'password-123');
      await tester.ensureVisible(find.byKey(const Key('submitAuth')));
      await tester.tap(find.byKey(const Key('submitAuth')));
      await tester.pumpAndSettle();
      expect(repo.selectedRole, 'user');
    },
  );
  testWidgets('guest details and save require login before repository calls', (
    tester,
  ) async {
    final properties = FakePropertyRepository()..items = [testProperty];
    await launch(tester, FakeAuthRepository(), properties: properties);
    await tester.ensureVisible(find.text('Test apartment'));
    await tester.tap(find.text('Test apartment'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome back'), findsOneWidget);
    expect(properties.detailCalls, 0);
    await tester.ensureVisible(find.text('Explore as a guest'));
    await tester.tap(find.text('Explore as a guest'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byTooltip(RegExp('^Save property')));
    await tester.tap(find.byTooltip(RegExp('^Save property')));
    await tester.pumpAndSettle();
    expect(find.text('Welcome back'), findsOneWidget);
    expect(properties.saveCalls, 0);
  });
  testWidgets(
    'changing active shared-rental intent removes roommate tab immediately',
    (tester) async {
      final repo = FakeAuthRepository()
        ..restored = const Account(
          id: 'shared',
          name: 'Student',
          email: 'student@example.com',
          role: 'student',
          ownerVerified: false,
          intents: ['tenant_shared'],
          activeIntent: 'tenant_shared',
        );
      await launch(tester, repo);
      expect(find.text('Find roommates'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('navigation-account')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('How will you use MyHome?'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey('intent_tenant_private')),
      );
      await tester.tap(find.byKey(const ValueKey('intent_tenant_private')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey('intent_tenant_shared')),
      );
      await tester.tap(find.byKey(const ValueKey('intent_tenant_shared')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('saveIntents')));
      await tester.tap(find.byKey(const Key('saveIntents')));
      await tester.pumpAndSettle();
      expect(find.text('Find roommates'), findsNothing);
    },
  );
  for (final size in [
    const Size(320, 640),
    const Size(768, 1024),
    const Size(1440, 900),
  ]) {
    testWidgets('Arabic RTL home and dark settings at ${size.width}', (
      tester,
    ) async {
      await launch(tester, FakeAuthRepository(), language: 'ar', size: size);
      expect(find.byTooltip('الفلاتر'), findsOneWidget);
      expect(find.text('بيتي'), findsOneWidget);
      expect(
        Directionality.of(tester.element(find.byType(NavigationBar))),
        TextDirection.rtl,
      );
      await tester.tap(find.byKey(const ValueKey('navigation-account')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('داكن'));
      await tester.tap(find.text('داكن'));
      await tester.pumpAndSettle();
      expect(
        Theme.of(tester.element(find.byType(NavigationBar))).brightness,
        Brightness.dark,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
