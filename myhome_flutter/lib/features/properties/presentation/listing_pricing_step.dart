import 'package:flutter/material.dart';
import '../../../core/config/marketplace_strings.dart';
import '../domain/property_repository.dart';
import 'listing_cubit.dart';
import 'price_quote_panel.dart';
import 'listing_choices.dart';
import '../../../core/widgets/property_illustration.dart';

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
  final _controllers = <String, TextEditingController>{};
  TextEditingController _controller(String key) {
    final text = widget.cubit.values[key]?.toString() ?? '';
    final controller = _controllers.putIfAbsent(
      key,
      () => TextEditingController(text: text),
    );
    if (controller.text != text) {
      controller.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    }
    return controller;
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

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
      controller: _controller(key),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: words(context, label ?? key),
        prefixIcon: Padding(
          padding: const EdgeInsets.all(8),
          child: PropertyIllustration(
            key == 'price'
                ? widget.cubit.values['category'] as String
                : 'rental_period',
            size: 32,
          ),
        ),
      ),
      onChanged: (value) => _set(key, ListingCubit.latinDigits(value)),
    ),
  );

  Widget _presets(String field, List<int> amounts) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final amount in amounts)
          ChoiceChip(
            key: ValueKey('preset-$field-$amount'),
            avatar: PropertyIllustration(
              widget.cubit.values['category'] as String,
              size: 18,
            ),
            label: Text('$amount ${words(context, 'egp')}'),
            selected: widget.cubit.values[field] == '$amount',
            onSelected: (_) => _set(field, '$amount'),
          ),
      ],
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
          child: Chip(
            avatar: PropertyIllustration(category, size: 28),
            label: Text(words(context, category)),
          ),
        ),
        const SizedBox(height: 20),
        if (rental) ...[
          DropdownButtonFormField<String>(
            key: const Key('pricing-period'),
            initialValue: widget.cubit.values['rental_period'] as String?,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: words(context, 'rentalTermChoice'),
              prefixIcon: const Padding(
                padding: EdgeInsets.all(8),
                child: PropertyIllustration('rental_period', size: 32),
              ),
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
            ListingQuantity(
              field: 'custom_months',
              value: int.tryParse('${widget.cubit.values['custom_months']}'),
              maximum: 1200,
              presets: const [1, 3, 6, 12, 24, 60],
              onChanged: (n) => _set('custom_months', '$n'),
            ),
        ],
        _presets(
          'price',
          category == 'shared_rental'
              ? [1000, 2000, 3000]
              : rental
              ? [3000, 5000, 10000]
              : [500000, 1000000, 2000000],
        ),
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
                avatar: AppImageIcon(
                  value ? Icons.handshake_outlined : Icons.price_check,
                  color: Theme.of(context).colorScheme.primary,
                ),
                label: Text(words(context, value ? 'yes' : 'no')),
                selected: widget.cubit.values['negotiable'] == value,
                onSelected: (_) => _set('negotiable', value),
              ),
          ],
        ),
        const SizedBox(height: 24),
        if (rental) ...[
          _presets('deposit', [0, 3000, 5000, 10000]),
          _number('deposit'),
          Text(words(context, 'depositSeparate')),
        ],
        if (category == 'sale_installments') ...[
          Text(words(context, 'installmentError')),
          const SizedBox(height: 18),
          _number('down_payment'),
          ListingQuantity(
            field: 'installment_count',
            value: int.tryParse('${widget.cubit.values['installment_count']}'),
            maximum: 600,
            presets: const [6, 12, 24, 36, 60],
            onChanged: (n) => _set('installment_count', '$n'),
          ),
          _number('installment_amount'),
        ],
      ],
    );
  }
}
