import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:myhome_flutter/app/app.dart';
import 'package:myhome_flutter/core/config/settings_cubit.dart';
import 'package:myhome_flutter/features/auth/domain/auth_repository.dart';
import 'package:myhome_flutter/features/auth/presentation/auth_cubit.dart';
import 'package:myhome_flutter/features/profile/change_password_page.dart';
import 'package:myhome_flutter/features/sales/presentation/admin_dashboard.dart';
import 'package:myhome_flutter/features/support/introduction_page.dart';
import 'package:myhome_flutter/localizations/app_localizations.dart';
import 'fake_property_repository.dart';
import 'fakes.dart';
import 'sales_chat_test.dart' show SalesFake;
import 'onboarding_pricing_test.dart' show tap;

const operatorAccount = Account(
  id: 'operator',
  name: 'fooda',
  email: 'operator-fooda@myhome.example.com',
  username: 'fooda',
  role: 'admin',
  ownerVerified: false,
  intents: ['owner_sale_cash', 'tenant_shared'],
  activeIntent: 'tenant_shared',
);

class DashboardFake extends SalesFake {
  Future<Map<String, dynamic>> Function() getCounts = () async => {
    'properties': 13,
    'owners': 2,
    'buyers': 3,
    'renters': 5,
    'published_properties': 7,
    'pending_total': 4,
    'property_reviews': 4,
  };
  int loads = 0;
  @override
  Future<Map<String, dynamic>> dashboard() {
    loads++;
    return getCounts();
  }
}

class PasswordFake extends FakeAuthRepository {
  final changes = <(String, String)>[];
  String? passwordError;
  @override
  Future<void> changePassword(String old, String next) async {
    changes.add((old, next));
    if (passwordError != null) throw PasswordChangeFailure(passwordError!);
  }
}

class OperatorLoginFake extends FakeAuthRepository {
  final String username;
  (String, String)? submitted;
  OperatorLoginFake(this.username);
  @override
  Future<Account> login(String email, String password) async {
    submitted = (email, password);
    return Account(
      id: 'operator-$username',
      name: username,
      email: 'operator-$username@myhome.example.com',
      username: username,
      role: 'admin',
      ownerVerified: false,
      onboardingComplete: true,
    );
  }
}

Widget localized(Widget home, String language) => MaterialApp(
  locale: Locale(language),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  home: home,
);

void main() {
  test(
    'administrator never gains owner or roommate controls from old intents',
    () {
      expect(operatorAccount.canManageProperties, isFalse);
      expect(operatorAccount.canFindRoommates, isFalse);
    },
  );
  test(
    'dashboard avoids overlapping requests and ignores completion after close',
    () async {
      final repo = DashboardFake();
      final pending = Completer<Map<String, dynamic>>();
      repo.getCounts = () => pending.future;
      final cubit = AdminDashboardCubit(repo);
      final request = cubit.load();
      await cubit.load();
      expect(repo.loads, 1);
      await cubit.close();
      pending.complete({'properties': 13});
      await request;
      expect(cubit.state.loading, isTrue);
    },
  );
  test('dashboard failure reports unknown counts and retry recovers', () async {
    final repo = DashboardFake()
      ..getCounts = () async => throw Exception('offline');
    final cubit = AdminDashboardCubit(repo);
    await cubit.load();
    expect(cubit.state.failed, isTrue);
    expect(cubit.state.counts, isEmpty);
    repo.getCounts = () async => {'properties': 13};
    await cubit.load();
    expect(cubit.state.failed, isFalse);
    expect(cubit.state.counts['properties'], 13);
    await cubit.close();
  });
  for (final language in ['ar', 'en']) {
    for (final username in ['fooda', 'amr']) {
      testWidgets(
        '$username signs in through the public form and reaches the admin dashboard in $language',
        (tester) async {
          SharedPreferences.setMockInitialValues({'language': language});
          final repository = OperatorLoginFake(username);
          await tester.pumpWidget(
            MyHome(
              showIntroduction: false,
              repository: repository,
              propertyRepository: FakePropertyRepository(),
              salesRepository: DashboardFake(),
              settings: SettingsCubit(await SharedPreferences.getInstance()),
            ),
          );
          await tester.pumpAndSettle();
          expect(find.byType(AdminDashboard), findsNothing);
          await tap(tester, find.byKey(const Key('openSignIn')));
          await tester.enterText(find.byKey(const Key('email')), username);
          await tester.enterText(
            find.byKey(const Key('password')),
            'synthetic-password-for-ui-test',
          );
          await tap(tester, find.byKey(const Key('submitAuth')));
          expect(repository.submitted, (
            username,
            'synthetic-password-for-ui-test',
          ));
          expect(find.byType(AdminDashboard), findsOneWidget);
          expect(find.byKey(const Key('submitAuth')), findsNothing);
          expect(
            find.byKey(const ValueKey('navigation-favorites')),
            findsNothing,
          );
          expect(
            find.byKey(const ValueKey('navigation-roommates')),
            findsNothing,
          );
          expect(find.byKey(const Key('drawerAddProperty')), findsNothing);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
        },
      );
    }
    testWidgets('admin has dashboard and no consumer navigation in $language', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({'language': language});
      await tester.pumpWidget(
        MyHome(
          showIntroduction: false,
          repository: FakeAuthRepository()..restored = operatorAccount,
          propertyRepository: FakePropertyRepository(),
          salesRepository: DashboardFake(),
          settings: SettingsCubit(await SharedPreferences.getInstance()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(AdminDashboard), findsOneWidget);
      expect(find.byKey(const ValueKey('navigation-favorites')), findsNothing);
      expect(find.byKey(const ValueKey('navigation-roommates')), findsNothing);
      tester.state<ScaffoldState>(find.byType(Scaffold).first).openDrawer();
      await tester.pumpAndSettle();
      for (final key in [
        'drawerAddProperty',
        'drawerManageProperties',
        'drawerGroups',
        'drawerPropertyMessages',
      ]) {
        expect(find.byKey(Key(key)), findsNothing);
      }
      expect(find.byType(ReviewBadge), findsWidgets);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
    testWidgets('old-password error remains actionable in $language', (
      tester,
    ) async {
      final repo = PasswordFake()..passwordError = 'CURRENT_PASSWORD_INCORRECT';
      final auth = AuthCubit(repo);
      addTearDown(auth.close);
      await tester.pumpWidget(
        BlocProvider.value(
          value: auth,
          child: localized(const ChangePasswordPage(), language),
        ),
      );
      await tester.enterText(
        find.byKey(const ValueKey('currentPassword')),
        'wrong-current',
      );
      await tester.enterText(
        find.byKey(const ValueKey('newPassword')),
        'new-password-123',
      );
      await tester.enterText(
        find.byKey(const ValueKey('confirmPassword')),
        'new-password-123',
      );
      await tap(tester, find.byKey(const Key('savePassword')));
      expect(repo.changes.single, ('wrong-current', 'new-password-123'));
      expect(
        find.text(
          language == 'ar'
              ? 'كلمة المرور الحالية غير صحيحة.'
              : 'The current password is incorrect.',
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
    testWidgets('introduction can skip and persists completion in $language', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final settings = SettingsCubit(preferences);
      addTearDown(settings.close);
      await tester.pumpWidget(
        BlocProvider.value(
          value: settings,
          child: localized(
            const IntroductionGate(child: Text('Finished')),
            language,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(IntroductionPage), findsOneWidget);
      await tap(tester, find.byKey(const Key('skipIntroduction')));
      expect(find.text('Finished'), findsOneWidget);
      expect(preferences.getBool('intro.v1'), isTrue);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('introduction advances all steps without a forced delay', (
    tester,
  ) async {
    var done = false;
    await tester.pumpWidget(
      localized(IntroductionPage(onFinished: () => done = true), 'en'),
    );
    for (var i = 0; i < 3; i++) {
      await tap(tester, find.byKey(const Key('nextIntroduction')));
    }
    expect(done, isTrue);
    expect(tester.takeException(), isNull);
  });
}
