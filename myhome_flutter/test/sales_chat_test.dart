import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhome_flutter/features/chat/domain/chat_repository.dart';
import 'package:myhome_flutter/features/chat/presentation/chat_cubit.dart';
import 'package:myhome_flutter/features/sales/domain/sales_repository.dart';
import 'package:myhome_flutter/features/sales/presentation/sales_cubit.dart';
import 'package:myhome_flutter/features/sales/presentation/financial_card.dart';
import 'package:myhome_flutter/features/sales/presentation/sales_pages.dart';

class SalesFake extends Fake implements SalesRepository {
  Future<Map<String, dynamic>> Function() response = () async => {
    'stage': 'open',
  };
  @override
  Future<Map<String, dynamic>> detail(String id) => response();
}

class ChatFake extends Fake implements ChatRepository {
  Future<ChatBatch> Function(int? before, int? after) response = (b, a) async =>
      const ChatBatch([ChatMessage(2, 'Hello', 'Buyer', true)], 2);
  @override
  Future<String> openDeal(String id) async => 'conversation';
  @override
  Future<ChatBatch> read(String id, {int? before, int? after}) =>
      response(before, after);
  @override
  Future<ChatMessage> send(String id, String text) async =>
      throw const ChatFailure('CONTACT_DETAILS_BLOCKED');
}

const saleSnapshot = <String, dynamic>{
  'original_price': '2000000.00',
  'property_component': '1900000.00',
  'buyer_fee': '10000.00',
  'seller_fee': '10000.00',
  'platform_fee': '20000.00',
  'buyer_total': '1910000.00',
  'seller_net': '1890000.00',
};

Widget financialApp(
  Widget child, {
  String language = 'en',
  bool dark = false,
}) => MaterialApp(
  locale: Locale(language),
  supportedLocales: const [Locale('en'), Locale('ar')],
  localizationsDelegates: GlobalMaterialLocalizations.delegates,
  theme: ThemeData(brightness: dark ? Brightness.dark : Brightness.light),
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

void main() {
  test('sales ignores stale loads and blocks duplicate mutations', () async {
    final repo = SalesFake();
    final first = Completer<Map<String, dynamic>>();
    repo.response = () => first.future;
    final cubit = SalesCubit(repo, 'deal');
    final loading = cubit.load();
    repo.response = () async => {'stage': 'accepted'};
    await cubit.load();
    first.complete({'stage': 'open'});
    await loading;
    expect(cubit.state.deal!['stage'], 'accepted');
    final mutation = Completer<void>();
    final active = cubit.act(() => mutation.future);
    expect(await cubit.act(() async => fail('duplicate mutation')), isFalse);
    mutation.complete();
    expect(await active, isTrue);
    await cubit.close();
  });

  test('sales retains loaded amounts on failed action', () async {
    final cubit = SalesCubit(SalesFake(), 'deal');
    await cubit.load();
    expect(
      await cubit.act(
        () async => throw const SalesFailure('INVALID_NET_OFFER'),
      ),
      isFalse,
    );
    expect(cubit.state.deal!['stage'], 'open');
    expect(cubit.state.error, 'INVALID_NET_OFFER');
    expect(cubit.state.busy, isFalse);
    await cubit.close();
  });

  test(
    'chat merges older pages, rejects contacts and clears revoked access',
    () async {
      final repo = ChatFake();
      final cubit = ChatCubit(repo, dealId: 'deal');
      await cubit.open();
      expect(await cubit.send('01012345678'), isFalse);
      expect(cubit.state.error, 'CONTACT_DETAILS_BLOCKED');
      expect(cubit.state.messages.length, 1);
      repo.response = (before, after) async {
        expect(before, 2);
        return const ChatBatch([
          ChatMessage(1, 'Earlier', 'Seller', false),
        ], null);
      };
      await cubit.older();
      expect(cubit.state.messages.map((m) => m.id), [1, 2]);
      repo.response = (b, a) async =>
          throw const ChatFailure('CHAT_ACCESS_REVOKED');
      await cubit.poll();
      expect(cubit.state.messages, isEmpty);
      expect(cubit.state.error, 'CHAT_ACCESS_REVOKED');
      await cubit.close();
    },
  );

  test(
    'unexpected polling failure is recoverable and preserves messages',
    () async {
      final repo = ChatFake();
      final cubit = ChatCubit(repo, dealId: 'deal');
      await cubit.open();
      repo.response = (b, a) async =>
          throw const FormatException('invalid server response');
      await cubit.poll();
      expect(cubit.state.error, 'NETWORK_ERROR');
      expect(cubit.state.messages.length, 1);
      await cubit.close();
    },
  );

  for (final language in ['en', 'ar']) {
    for (final dark in [false, true]) {
      testWidgets('all-in breakdown $language dark=$dark fits narrow screens', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(320, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          financialApp(
            const FinancialCard(snapshot: saleSnapshot),
            language: language,
            dark: dark,
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.text('1910000.00 ${language == 'ar' ? 'ج.م' : 'EGP'}'),
          findsOneWidget,
        );
        expect(
          find.text('1890000.00 ${language == 'ar' ? 'ج.م' : 'EGP'}'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('old rent distinguishes first payment and legal review', (
    tester,
  ) async {
    await tester.pumpWidget(
      financialApp(
        FinancialCard(
          commitmentEnabled: false,
          snapshot: {
            ...saleSnapshot,
            'old_rent': true,
            'months': 12,
            'subsequent_monthly_price': '9000.00',
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Monthly all-in price'), findsNothing);
    expect(find.textContaining('12'), findsOneWidget);
    expect(find.text('9000.00 EGP'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'financial consent form closes without using disposed controllers',
    (tester) async {
      Map<String, String>? result;
      await tester.pumpWidget(
        financialApp(
          Builder(
            builder: (context) => FilledButton(
              onPressed: () async {
                result = await salesForm(context, 'offer', const [
                  InputSpec('amount', 'buyerTotal', number: true),
                ], acknowledgement: 'fixedHint');
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), '١٩١٠٠٠٠');
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();
      expect(result, isNull);
      expect(find.byType(Checkbox), findsNothing);
      await tester.tap(find.byKey(const Key('formAcknowledgement')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();
      expect(result?['amount'], '1910000');
      expect(tester.takeException(), isNull);
    },
  );
}
