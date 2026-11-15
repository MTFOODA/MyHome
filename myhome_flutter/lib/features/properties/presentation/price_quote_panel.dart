import '../../../core/widgets/app_icon.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/config/marketplace_strings.dart';
import '../domain/property_repository.dart';
import 'price_calculator_result.dart';
import '../../sales/presentation/sales_strings.dart';

class PriceQuotePanel extends StatefulWidget {
  final PropertyRepository repository;
  final Map<String, dynamic> values;
  final String? propertyId;
  final ValueChanged<bool>? onReadyChanged;
  const PriceQuotePanel({
    super.key,
    required this.repository,
    required this.values,
    this.propertyId,
    this.onReadyChanged,
  });
  @override
  State<PriceQuotePanel> createState() => _PriceQuotePanelState();
}

class _PriceQuotePanelState extends State<PriceQuotePanel> {
  Timer? _timer;
  String? _fingerprint;
  Map<String, dynamic>? _quote;
  bool _failed = false, _loading = false;
  int _generation = 0;
  @override
  void initState() {
    super.initState();
    _schedule();
  }

  @override
  void didUpdateWidget(covariant PriceQuotePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    _schedule();
  }

  void _schedule() {
    final rental = [
      'private_rental',
      'shared_rental',
    ].contains(widget.values['category']);
    final data = {
      if (widget.propertyId != null) 'property_id': widget.propertyId,
      for (final key in [
        'category',
        'price',
        'area_id',
        if (rental) 'rental_period',
        if (rental && widget.values['rental_period'] == 'custom')
          'custom_months',
        if (widget.values['category'] == 'shared_rental') 'total_beds',
      ])
        if (widget.values[key] != null && widget.values[key] != '')
          key: widget.values[key],
    };
    final fingerprint = jsonEncode(data);
    if (_fingerprint == fingerprint) return;
    _fingerprint = fingerprint;
    _timer?.cancel();
    final request = ++_generation;
    _quote = null;
    _failed = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && request == _generation && _quote == null) {
        widget.onReadyChanged?.call(false);
      }
    });
    if (data['category'] == null ||
        data['area_id'] == null ||
        (num.tryParse('${data['price']}') ?? 0) <= 0) {
      _loading = false;
      return;
    }
    for (final key in ['custom_months', 'total_beds']) {
      if (data[key] != null) {
        final value = int.tryParse('${data[key]}');
        if (value == null || value < 1) {
          _loading = false;
          return;
        }
        data[key] = value;
      }
    }
    _loading = true;
    _timer = Timer(const Duration(milliseconds: 450), () async {
      try {
        final quote = await widget.repository.priceQuote(data);
        if (mounted && request == _generation) {
          setState(() {
            _quote = quote;
            _loading = false;
          });
          widget.onReadyChanged?.call(
            quote['requires_agreement'] == false &&
                quote.containsKey('buyer_fee'),
          );
        }
      } catch (_) {
        if (mounted && request == _generation) {
          setState(() {
            _failed = true;
            _loading = false;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _generation++;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            words(context, 'calculator'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          if (_loading)
            const LinearProgressIndicator()
          else if (_failed) ...[
            Text(words(context, 'quoteFailed')),
            TextButton.icon(
              onPressed: () => setState(() {
                _fingerprint = null;
                _schedule();
              }),
              icon: const AppIcon(Icons.refresh),
              label: Text(words(context, 'quoteRetry')),
            ),
          ] else if (_quote == null || _quote!['requires_agreement'] == true)
            Text(words(context, 'calculatorHint'))
          else if (_quote!.containsKey('buyer_fee'))
            PriceCalculatorResult(quote: _quote!)
          else ...[
            Text(
              words(
                context,
                _quote!['enabled'] == true ? 'feeEnabled' : 'feeProposal',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${words(context, 'ownerPrice')}: ${_quote!['owner_price']} ${words(context, 'egp')}',
            ),
            Text(
              '${words(context, 'platformFee')}: ${_quote!['platform_fee']} ${words(context, 'egp')}',
            ),
            Text(
              '${words(context, 'inclusivePrice')}: ${_quote!['display_price']} ${words(context, 'egp')}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(
              words(
                context,
                _quote!['price_basis'] == 'bed_month'
                    ? 'perBedMonth'
                    : _quote!['price_basis'] == 'month'
                    ? 'perMonth'
                    : 'salePrice',
              ),
            ),
            if (_quote!['months'] != null && _quote!['old_rent'] != true)
              Text(
                '${words(context, 'feeSpread')}: ${_quote!['months']} ${words(context, 'months')}',
              ),
            if (_quote!['price_basis'] == 'bed_month')
              Text(words(context, 'sharedFeeBasis')),
            if (_quote!['old_rent'] == true)
              Text(salesText(context, 'oldReference')),
          ],
        ],
      ),
    ),
  );
}
