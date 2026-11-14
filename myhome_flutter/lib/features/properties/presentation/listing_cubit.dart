import 'package:flutter_bloc/flutter_bloc.dart';
import '../domain/property_repository.dart';
import '../../../core/input/number_input.dart' as number_input;

class ListingState {
  final bool busy, submitted;
  final double progress;
  final String? error;
  const ListingState({
    this.busy = false,
    this.submitted = false,
    this.progress = 0,
    this.error,
  });
}

class ListingCubit extends Cubit<ListingState> {
  static String latinDigits(String input) => number_input.latinDigits(input);
  final PropertyRepository repository;
  final values = <String, dynamic>{};
  final List<UploadImage> photos = [];
  UploadImage? identity, ownership;
  String nationalId = '', birthDate = '';
  bool consent = false;
  String? _propertyId, _identityId, _ownershipId;
  final Map<UploadImage, String> _uploaded = {};
  UploadImage? _lastIdentity, _lastOwnership;
  String? _lastIdentityInput;
  ListingCubit(this.repository) : super(const ListingState());
  List<String> get steps => [
    'category',
    'information',
    'location',
    'dimensions',
    'water',
    'electricity',
    'gas',
    'finishing',
    'elevator',
    'pricing',
    'negotiable',
    if (['private_rental', 'shared_rental'].contains(values['category']))
      'rental_period',
    if (values['category'] == 'sale_installments') 'installments',
    if (values['category'] == 'shared_rental') 'beds',
    'photos',
    'verification',
    'review',
  ];
  void setValue(String key, dynamic value) {
    values[key] = value;
  }

  static int? moneyCents(dynamic value) {
    if (value == null ||
        !RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(value.toString())) {
      return null;
    }
    final parts = value.toString().split('.');
    return int.parse(parts[0]) * 100 +
        int.parse(parts.length == 1 ? '0' : parts[1].padRight(2, '0'));
  }

  bool valid(String step) {
    bool nonempty(String key, int minimum) =>
        (values[key]?.toString().trim().length ?? 0) >= minimum;
    int? integer(String key) => int.tryParse(values[key]?.toString() ?? '');
    switch (step) {
      case 'category':
        return values['category'] != null;
      case 'information':
        return nonempty('title', 5) && nonempty('description', 20);
      case 'location':
        return values['area_id'] != null &&
            nonempty('approximate_location', 5) &&
            ((values['latitude']?.toString().isNotEmpty ?? false) ==
                (values['longitude']?.toString().isNotEmpty ?? false));
      case 'dimensions':
        return (num.tryParse(values['area_m2']?.toString() ?? '') ?? 0) > 0 &&
            (integer('bedrooms') ?? -1) >= 0 &&
            (integer('bathrooms') ?? 0) > 0 &&
            (integer('capacity') ?? 0) > 0;
      case 'water':
      case 'electricity':
      case 'gas':
      case 'elevator':
      case 'negotiable':
        return values[step] is bool;
      case 'finishing':
        return values['finishing'] != null;
      case 'pricing':
        return (moneyCents(values['price']) ?? 0) > 0;
      case 'rental_period':
        return values['rental_period'] != null &&
            (moneyCents(values['deposit']) ?? -1) >= 0 &&
            (values['rental_period'] != 'custom' ||
                (integer('custom_months') ?? 0) > 0);
      case 'installments':
        final down = moneyCents(values['down_payment']),
            amount = moneyCents(values['installment_amount']),
            count = integer('installment_count');
        return down != null &&
            amount != null &&
            amount > 0 &&
            count != null &&
            count > 0 &&
            down + amount * count == moneyCents(values['price']);
      case 'beds':
        final total = integer('total_beds'),
            available = integer('available_beds');
        return total != null &&
            total > 0 &&
            available != null &&
            available >= 0 &&
            available <= total &&
            total <= (integer('capacity') ?? 0);
      case 'photos':
        return photos.length >= 2 &&
            photos.length <= 12 &&
            photos.every((file) => file.bytes.length <= 8 * 1024 * 1024);
      case 'verification':
        if (identity == null ||
            ownership == null ||
            !consent ||
            !RegExp(r'^[23]\d{13}$').hasMatch(nationalId)) {
          return false;
        }
        final parsed = DateTime.tryParse(birthDate);
        if (parsed == null || parsed.isAfter(DateTime.now())) return false;
        final expected =
            '${nationalId[0] == '2' ? '19' : '20'}${nationalId.substring(1, 3)}-${nationalId.substring(3, 5)}-${nationalId.substring(5, 7)}';
        return birthDate == expected &&
            '${parsed.year.toString().padLeft(4, '0')}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')}' ==
                birthDate;
      default:
        return true;
    }
  }

  Map<String, dynamic> payload() {
    final data = Map<String, dynamic>.of(values)..remove('governorate_id');
    for (final key in ['latitude', 'longitude']) {
      if (data[key] == null || data[key] == '') data.remove(key);
    }
    for (final key in [
      'bedrooms',
      'bathrooms',
      'capacity',
      'custom_months',
      'installment_count',
      'total_beds',
      'available_beds',
    ]) {
      if (data[key] != null) data[key] = int.parse(data[key].toString());
    }
    if (!['private_rental', 'shared_rental'].contains(data['category'])) {
      for (final key in ['rental_period', 'custom_months', 'deposit']) {
        data.remove(key);
      }
    }
    if (data['rental_period'] != 'custom') data.remove('custom_months');
    if (data['category'] != 'sale_installments') {
      for (final key in [
        'down_payment',
        'installment_count',
        'installment_amount',
      ]) {
        data.remove(key);
      }
    }
    if (data['category'] != 'shared_rental') {
      data.remove('total_beds');
      data.remove('available_beds');
    }
    return data;
  }

  Future<void> submit() async {
    if (state.busy) return;
    if (steps.any((step) => !valid(step))) {
      emit(const ListingState(error: 'invalid'));
      return;
    }
    emit(const ListingState(busy: true));
    try {
      if (_propertyId == null) {
        _propertyId = await repository.create(payload());
      } else {
        await repository.update(_propertyId!, payload());
      }
      final total = photos.length + 4;
      var done = 1;
      for (final photo in photos) {
        _uploaded[photo] ??= await repository.upload(photo, 'photo');
        emit(ListingState(busy: true, progress: ++done / total));
      }
      await repository.attachPhotos(
        _propertyId!,
        photos.map((photo) => _uploaded[photo]!).toList(),
      );
      if (_lastIdentity != identity ||
          _lastIdentityInput != '$nationalId:$birthDate') {
        _identityId = null;
      }
      _identityId ??= await repository.upload(
        identity!,
        'identity',
        nationalId: nationalId,
        birthDate: birthDate,
      );
      _lastIdentity = identity;
      _lastIdentityInput = '$nationalId:$birthDate';
      emit(ListingState(busy: true, progress: ++done / total));
      if (_lastOwnership != ownership) _ownershipId = null;
      _ownershipId ??= await repository.upload(ownership!, 'ownership');
      _lastOwnership = ownership;
      emit(ListingState(busy: true, progress: ++done / total));
      await repository.submit(_propertyId!, _identityId!, _ownershipId!);
      // Drop sensitive in-memory bytes after submission.
      identity = null;
      ownership = null;
      _lastIdentity = null;
      _lastOwnership = null;
      _lastIdentityInput = null;
      nationalId = '';
      birthDate = '';
      photos.clear();
      _uploaded.clear();
      emit(const ListingState(submitted: true, progress: 1));
    } on PropertyException catch (error) {
      emit(
        ListingState(
          error: switch (error.code) {
            'OCR_NUMBER_MISMATCH' => 'ocrMismatch',
            'NATIONAL_ID_BIRTH_DATE_MISMATCH' => 'idMismatch',
            _ => 'saveError',
          },
        ),
      );
    } catch (_) {
      emit(const ListingState(error: 'saveError'));
    }
  }
}
