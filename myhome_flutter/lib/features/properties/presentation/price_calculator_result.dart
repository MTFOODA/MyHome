import 'package:flutter/material.dart';
import '../../../core/config/marketplace_strings.dart';
import '../../sales/presentation/financial_card.dart';
import '../../sales/presentation/sales_strings.dart';

/// All money and percentages come from the server's frozen commission reference.
class PriceCalculatorResult extends StatelessWidget {
  final Map<String, dynamic> quote;
  const PriceCalculatorResult({super.key, required this.quote});

  @override
  Widget build(BuildContext context) {
    final old = quote['old_rent'] == true;
    final rental = quote['months'] != null;
    final shared = quote['price_basis'] == 'bed_month';
    final percentages = quote['calculator'] as Map?;
    final colors = Theme.of(context).colorScheme;
    String amount(String field) {
      final parts = '${quote[field]}'.split('.');
      final whole = parts.first.replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+$)'),
        (match) => '${match[1]},',
      );
      return '$whole${parts.length > 1 ? '.${parts[1]}' : ''} ${words(context, 'egp')}';
    }

    Widget amountCard(String key, String label, String field, {String? hint}) =>
        Container(
          key: ValueKey(key),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(label, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Text(
                amount(field),
                textDirection: TextDirection.ltr,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: colors.onPrimaryContainer,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (hint != null) ...[const SizedBox(height: 6), Text(hint)],
            ],
          ),
        );
    Widget share(String label, String field, String percentField) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(label),
          const SizedBox(height: 4),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                amount(field),
                textDirection: TextDirection.ltr,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              if (percentages != null)
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.secondaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: Text(
                      '${percentages[percentField]}%',
                      textDirection: TextDirection.ltr,
                      style: TextStyle(
                        color: colors.onSecondaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (quote['requires_legal_eligibility'] == true) ...[
          Text(
            salesText(context, 'eligibilityPending'),
            style: TextStyle(color: colors.error),
          ),
          const SizedBox(height: 12),
        ],
        amountCard(
          'calculatorBuyer',
          words(context, 'inclusivePrice'),
          'display_price',
          hint: old
              ? salesText(context, 'firstPayment')
              : words(
                  context,
                  shared
                      ? 'perBedMonth'
                      : rental
                      ? 'perMonth'
                      : 'salePrice',
                ),
        ),
        const SizedBox(height: 12),
        amountCard(
          'calculatorOwner',
          words(
            context,
            old
                ? 'ownerNetFirst'
                : shared
                ? 'ownerNetBed'
                : rental
                ? 'ownerNetMonthly'
                : 'ownerNet',
          ),
          rental && !old ? 'seller_monthly_net' : 'seller_net',
          hint: rental && !old ? words(context, 'monthlyNetHint') : null,
        ),
        if (percentages != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                Text(words(context, 'ownerNetRatio')),
                Text(
                  '${percentages['owner_net_percent']}%',
                  textDirection: TextDirection.ltr,
                ),
              ],
            ),
          ),
        const Divider(height: 28),
        if (percentages != null) ...[
          Text(
            words(context, switch (percentages['reference_basis']) {
              'contract_rent' => 'referenceContract',
              'monthly_rent' => 'referenceMonth',
              _ => 'referenceSale',
            }),
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 12),
        ],
        share(
          words(context, 'platformFee'),
          'platform_fee',
          'platform_percent',
        ),
        share(salesText(context, 'sellerFee'), 'seller_fee', 'seller_percent'),
        share(salesText(context, 'buyerFee'), 'buyer_fee', 'buyer_percent'),
        if (shared) Text(words(context, 'sharedFeeBasis')),
        if (old) ...[
          Text(salesText(context, 'oldReference')),
          const SizedBox(height: 8),
          Text(
            '${salesText(context, 'subsequentRent')}: ${quote['subsequent_monthly_price']} ${words(context, 'egp')}',
          ),
        ],
        const SizedBox(height: 12),
        Text(salesText(context, 'fixedHint')),
        ExpansionTile(
          key: const Key('calculatorDetails'),
          tilePadding: EdgeInsets.zero,
          title: Text(words(context, 'calculatorDetails')),
          children: [
            FinancialCard(
              snapshot: quote,
              commitmentEnabled: quote['requires_legal_eligibility'] != true,
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(salesText(context, 'policy')),
            ),
          ],
        ),
      ],
    );
  }
}
