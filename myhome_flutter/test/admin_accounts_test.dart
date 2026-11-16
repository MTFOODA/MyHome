import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhome_flutter/features/auth/domain/auth_repository.dart';
import 'package:myhome_flutter/features/auth/presentation/auth_cubit.dart';
import 'package:myhome_flutter/features/sales/domain/sales_repository.dart';
import 'package:myhome_flutter/features/sales/presentation/sales_admin_page.dart';
import 'package:myhome_flutter/localizations/app_localizations.dart';
import 'package:myhome_flutter/core/config/theme_config.dart';
import 'package:myhome_flutter/core/widgets/app_backdrop.dart';
import 'fakes.dart';
import 'onboarding_pricing_test.dart' show tap;
import 'sales_chat_test.dart' show SalesFake;

class AdminAccountsFake extends SalesFake {
  final created = <Map<String, dynamic>>[];
  @override
  Future<List<Map<String, dynamic>>> staff() async => [
    {
      'id': 'root',
      'name': 'Synthetic Admin',
      'specialty': 'admin',
      'active': true,
    },
    {
      'id': 'lawyer',
      'name': 'Synthetic Lawyer',
      'specialty': 'document_reviewer',
      'active': true,
    },
    {
      'id': 'broker',
      'name': 'Synthetic Broker',
      'specialty': 'field_agent',
      'active': true,
    },
  ];
  @override
  Future<void> createStaff(Map<String, dynamic> values) async {
    created.add(values);
  }
}

Future<void> openAdmin(
  WidgetTester tester,
  AdminAccountsFake repo,
  String language,
  Size size, {
  bool dark = false,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final auth = AuthCubit(
    FakeAuthRepository()
      ..restored = const Account(
        id: 'root',
        name: 'Synthetic Admin',
        email: 'test@example.com',
        role: 'admin',
        ownerVerified: false,
        onboardingComplete: true,
      ),
  );
  await auth.restore();
  addTearDown(auth.close);
  await tester.pumpWidget(
    RepaintBoundary(
      key: const Key('adminPreview'),
      child: RepositoryProvider<SalesRepository>.value(
        value: repo,
        child: BlocProvider.value(
          value: auth,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            builder: (context, child) =>
                AppBackdrop(child: child ?? const SizedBox.shrink()),
            theme: dark
                ? ThemeConfig.darkTheme(viewportWidth: size.width)
                : ThemeConfig.lightTheme(viewportWidth: size.width),
            locale: Locale(language),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: const SalesAdminPage(),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final language in ['ar', 'en']) {
    for (final role in ['field_agent', 'document_reviewer']) {
      testWidgets('admin creates $role in $language on a phone', (
        tester,
      ) async {
        final repo = AdminAccountsFake();
        await openAdmin(tester, repo, language, const Size(390, 1000));
        // Existing administrators have a shield, not the staff-authority toggle.
        expect(find.byType(Switch), findsNWidgets(2));
        await tap(tester, find.byKey(const Key('createInternalAccount')));
        await tap(tester, find.byKey(ValueKey('create-account-$role')));
        for (final field in {
          'name': 'Synthetic new colleague',
          'email': 'colleague@example.com',
          'password': 'test-internal-password-123',
          if (role == 'document_reviewer')
            'professional_reference': 'TEST-REFERENCE-NOT-A-LICENSE',
        }.entries) {
          final input = find.byKey(ValueKey('sales-${field.key}'));
          await tester.ensureVisible(input);
          await tester.enterText(input, field.value);
        }
        tester.testTextInput.hide();
        await tap(tester, find.byKey(const Key('salesSubmit')));
        expect(repo.created.single['specialty'], role);
        expect(
          repo.created.single.containsKey('professional_reference'),
          role == 'document_reviewer',
        );
        expect(tester.takeException(), isNull);
      });
    }
  }
}
