import 'package:flutter/material.dart';
import '../../../core/config/marketplace_strings.dart';
import '../domain/property_repository.dart';
import 'listing_cubit.dart';
import 'price_quote_panel.dart';

class ListingPricingStep extends StatefulWidget {
  final ListingCubit cubit;
  final PropertyRepository repository;
  final ValueChanged<bool> onReadyChanged;
  const ListingPricingStep({
    super.key,
    required this.cubit,
    required this.repository,
    required this.onReadyChanged,
  });
  @override
  State<ListingPricingStep> createState() => _ListingPricingStepState();
}

class _ListingPricingStepState extends State<ListingPricingStep> {
  void _set(String key, dynamic value) {
    if (['price', 'rental_period', 'custom_months'].contains(key)) {
      widget.onReadyChanged(false);
    }
    setState(() => widget.cubit.setValue(key, value));
  }

  Widget _number(String key, {String? label}) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: TextFormField(
      key: ValueKey('pricing-$key'),
      initialValue: widget.cubit.values[key]?.toString(),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: words(context, label ?? key)),
      onChanged: (value) => _set(key, ListingCubit.latinDigits(value)),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final category = widget.cubit.values['category'] as String;
    final rental = ['private_rental', 'shared_rental'].contains(category);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(words(context, 'pricingFinalHint')),
        const SizedBox(height: 12),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Chip(label: Text(words(context, category))),
        ),
        const SizedBox(height: 20),
        if (rental) ...[
          DropdownButtonFormField<String>(
            key: const Key('pricing-period'),
            initialValue: widget.cubit.values['rental_period'] as String?,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: words(context, 'rentalTermChoice'),
            ),
            items: [
              for (final value in [
                'one_year',
                'three_years',
                'five_years',
                'old_rent',
                'custom',
              ])
                DropdownMenuItem(
                  value: value,
                  child: Text(words(context, value)),
                ),
            ],
            onChanged: (value) => _set('rental_period', value),
          ),
          const SizedBox(height: 20),
          if (widget.cubit.values['rental_period'] == 'custom')
            _number('custom_months'),
        ],
        _number(
          'price',
          label: category == 'shared_rental'
              ? 'baseBedPrice'
              : rental
              ? 'baseMonthlyPrice'
              : 'baseSalePrice',
        ),
        PriceQuotePanel(
          repository: widget.repository,
          values: widget.cubit.values,
          propertyId: widget.cubit.draftId,
          onReadyChanged: widget.onReadyChanged,
        ),
        const SizedBox(height: 20),
        Text(
          words(context, 'negotiable'),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 12,
          children: [
            for (final value in [true, false])
              ChoiceChip(
                key: ValueKey('pricing-negotiable-$value'),
                label: Text(words(context, value ? 'yes' : 'no')),
                selected: widget.cubit.values['negotiable'] == value,
                onSelected: (_) => _set('negotiable', value),
              ),
          ],
        ),
        const SizedBox(height: 24),
        if (rental) ...[
          _number('deposit'),
          Text(words(context, 'depositSeparate')),
        ],
        if (category == 'sale_installments') ...[
          Text(words(context, 'installmentError')),
          const SizedBox(height: 18),
          _number('down_payment'),
          _number('installment_count'),
          _number('installment_amount'),
        ],
      ],
    );
  }
}
