import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhome_flutter/core/config/theme_config.dart';
import 'package:myhome_flutter/features/auth/domain/auth_repository.dart';
import 'package:myhome_flutter/features/auth/presentation/auth_cubit.dart';
import 'package:myhome_flutter/features/chat/domain/chat_repository.dart';
import 'package:myhome_flutter/features/chat/presentation/chat_page.dart';
import 'package:myhome_flutter/features/sales/domain/sales_repository.dart';
import 'package:myhome_flutter/features/sales/presentation/financial_card.dart';
import 'package:myhome_flutter/features/sales/presentation/sales_pages.dart';
import 'package:myhome_flutter/features/sales/presentation/sales_admin_page.dart';
import 'package:myhome_flutter/localizations/app_localizations.dart';
import 'fakes.dart';
import 'sales_chat_test.dart' show SalesFake, ChatFake, saleSnapshot;

class PreviewSales extends SalesFake {
  PreviewSales() {
    response = () async => {
      'title': 'بيتي · MyHome',
      'stage': 'accepted',
      'my_side': 'buyer',
      'financial': saleSnapshot,
      'viewings': <dynamic>[],
      'offers': <dynamic>[],
      'terms': null,
      'buyer_consented': false,
      'seller_consented': false,
      'special_fee_proposals': <dynamic>[],
      'review_status': 'pending',
      'invoices': <dynamic>[],
      'claims': <dynamic>[],
      'qr_ready': false,
      'buyer_platform_paid': '0.00',
      'buyer_remaining_total': '1910000.00',
    };
  }
  @override
  Future<List<Map<String, dynamic>>> staff() async => [
    {
      'id': 'a',
      'name': 'DEMO · مشرف معاينات',
      'specialty': 'field_agent',
      'active': true,
    },
    {
      'id': 'b',
      'name': 'DEMO · مراجع مستندات',
      'specialty': 'document_reviewer',
      'active': true,
    },
  ];
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
  for (final language in ['ar', 'en']) {
    for (final dark in [false, true]) {
      testWidgets('sales chat preview $language dark=$dark', (tester) async {
        tester.view.physicalSize = const Size(390, 960);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final auth = AuthCubit(
          FakeAuthRepository()
            ..restored = const Account(
              id: 'admin',
              name: 'Demo',
              email: 'demo@example.com',
              role: 'admin',
              ownerVerified: false,
            ),
        );
        await auth.restore();
        final sales = PreviewSales();
        final chat = ChatFake()
          ..response = (before, after) async => ChatBatch([
            ChatMessage(
              1,
              language == 'ar'
                  ? 'أهلًا، ممكن نحجز معاينة مع مشرف المنصة؟'
                  : 'Hello, can we book an accompanied viewing?',
              'member-demo',
              true,
            ),
            ChatMessage(
              2,
              language == 'ar'
                  ? 'طبعًا، اختار الموعد المناسب من صفحة الصفقة.'
                  : 'Of course. Choose a time from the deal page.',
              'member-demo',
              false,
            ),
          ], null);
        Future<void> show(String name, Widget page) async {
          await tester.pumpWidget(
            RepaintBoundary(
              key: const Key('sale-preview'),
              child: MultiRepositoryProvider(
                providers: [
                  RepositoryProvider<SalesRepository>.value(value: sales),
                  RepositoryProvider<ChatRepository>.value(value: chat),
                ],
                child: BlocProvider.value(
                  value: auth,
                  child: MaterialApp(
                    key: UniqueKey(),
                    debugShowCheckedModeBanner: false,
                    locale: Locale(language),
                    supportedLocales: AppLocalizations.supportedLocales,
                    localizationsDelegates:
                        AppLocalizations.localizationsDelegates,
                    theme: dark
                        ? ThemeConfig.darkTheme()
                        : ThemeConfig.lightTheme(),
                    home: page,
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await expectLater(
            find.byKey(const Key('sale-preview')),
            matchesGoldenFile(
              '../../docs/screenshots/$name-${dark ? 'dark-' : ''}$language.png',
            ),
          );
        }

        await show('deal', const SalesDetailPage(id: 'demo'));
        await show(
          'old-rent',
          Scaffold(
            appBar: AppBar(title: const Text('بيتي · MyHome')),
            body: SingleChildScrollView(
              child: FinancialCard(
                commitmentEnabled: false,
                snapshot: {
                  'original_price': '10000.00',
                  'property_component': '9000.00',
                  'buyer_fee': '3750.00',
                  'seller_fee': '3750.00',
                  'platform_fee': '7500.00',
                  'buyer_total': '12750.00',
                  'seller_net': '5250.00',
                  'old_rent': true,
                  'months': 12,
                  'subsequent_monthly_price': '9000.00',
                },
              ),
            ),
          ),
        );
        await show('chat', const ChatPage(dealId: 'demo'));
        await show('staff', const SalesAdminPage());
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
        await auth.close();
      });
    }
  }
}
