import 'package:flutter/material.dart';
import 'sales_strings.dart';

/// Displays server-calculated amounts only; no commission arithmetic in Flutter.
class FinancialCard extends StatelessWidget {
  final Map<String, dynamic> snapshot;
  final bool commitmentEnabled;
  const FinancialCard({
    super.key,
    required this.snapshot,
    this.commitmentEnabled = true,
  });
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            salesText(context, 'financialBreakdown'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 14),
          if (!commitmentEnabled)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                salesText(context, 'eligibilityPending'),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          for (final entry in <(String, String)>[
            ('original', 'original_price'),
            ('propertyPart', 'property_component'),
            ('buyerFee', 'buyer_fee'),
            ('sellerFee', 'seller_fee'),
            ('totalFee', 'platform_fee'),
            (
              snapshot['old_rent'] == true ? 'firstPayment' : 'buyerTotal',
              'buyer_total',
            ),
            ('sellerNet', 'seller_net'),
            if (snapshot['months'] != null && snapshot['old_rent'] != true)
              ('monthlyAllIn', 'display_price'),
            if (snapshot['old_rent'] == true)
              ('subsequentRent', 'subsequent_monthly_price'),
          ])
            if (snapshot[entry.$2] != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  spacing: 16,
                  children: [
                    Text(salesText(context, entry.$1)),
                    Text(
                      '${snapshot[entry.$2]} ${Localizations.localeOf(context).languageCode == 'ar' ? 'ج.م' : 'EGP'}',
                      textDirection: TextDirection.ltr,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
          const Divider(),
          Text(salesText(context, 'fixedHint')),
          if (snapshot['old_rent'] == true)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(salesText(context, 'oldReference')),
            ),
        ],
      ),
    ),
  );
}
