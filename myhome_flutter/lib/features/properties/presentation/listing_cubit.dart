import 'package:flutter_bloc/flutter_bloc.dart';
import '../domain/property_repository.dart';
import '../../../core/input/number_input.dart' as number_input;
import '../../../core/input/egyptian_identity.dart';

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
  String? propertyKind;
  String? _propertyId, _identityId, _ownershipId;
  String? get draftId => _propertyId;
  final Map<UploadImage, String> _uploaded = {};
  UploadImage? _lastIdentity, _lastOwnership;
  String? _lastIdentityInput;
  ListingCubit(this.repository) : super(const ListingState());
  List<String> get steps => [
    'category',
    'information',
    'location',
    'dimensions',
    'utilities',
    'finishing',
    'elevator',
    if (values['category'] == 'shared_rental') 'beds',
    'photos',
    'verification',
    'review',
    'pricing',
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
        final lat = values['latitude']?.toString() ?? '';
        final lon = values['longitude']?.toString() ?? '';
        return values['area_id'] != null &&
            nonempty('street_address', 3) &&
            nonempty('building_number', 1) &&
            nonempty('unit_number', 1) &&
            (integer('floor_number') ?? -99) >= 0 &&
            (integer('floor_number') ?? 101) <= 100 &&
            nonempty('approximate_location', 5) &&
            ((lat.isEmpty && lon.isEmpty) ||
                ((num.tryParse(lat) ?? -1) >= 22 &&
                    (num.tryParse(lat) ?? 99) <= 32 &&
                    (num.tryParse(lon) ?? -1) >= 24 &&
                    (num.tryParse(lon) ?? 99) <= 37));
      case 'dimensions':
        return ['net', 'gross'].contains(values['area_measurement']) &&
            RegExp(r'^\d+(\.\d{1,2})?$').hasMatch('${values['area_m2']}') &&
            (num.tryParse(values['area_m2']?.toString() ?? '') ?? 0) > 0 &&
            (num.tryParse(values['area_m2']?.toString() ?? '') ?? 0) <=
                100000 &&
            (integer('bedrooms') ?? -1) >= 0 &&
            (integer('bedrooms') ?? 101) <= 100 &&
            (integer('bathrooms') ?? 0) > 0 &&
            (integer('bathrooms') ?? 101) <= 100 &&
            (values['category'] != 'shared_rental' ||
                ((integer('capacity') ?? 0) > 0 &&
                    (integer('capacity') ?? 501) <= 500));
      case 'utilities':
        return [
          'water',
          'electricity',
          'gas',
        ].every((field) => values[field] is bool);
      case 'water':
      case 'electricity':
      case 'gas':
      case 'elevator':
      case 'negotiable':
        return values[step] is bool;
      case 'finishing':
        return values['finishing'] != null &&
            (![
                  'lux',
                  'super_lux',
                  'ultra_super_lux',
                ].contains(values['finishing']) ||
                values['furnished'] is bool);
      case 'pricing':
        return (moneyCents(values['price']) ?? 0) > 0 &&
            valid('negotiable') &&
            (![
                  'private_rental',
                  'shared_rental',
                ].contains(values['category']) ||
                valid('rental_period')) &&
            (values['category'] != 'sale_installments' ||
                valid('installments'));
      case 'rental_period':
        return values['rental_period'] != null &&
            (moneyCents(values['deposit']) ?? -1) >= 0 &&
            (values['rental_period'] != 'custom' ||
                ((integer('custom_months') ?? 0) > 0 &&
                    (integer('custom_months') ?? 1201) <= 1200));
      case 'installments':
        final down = moneyCents(values['down_payment']),
            amount = moneyCents(values['installment_amount']),
            count = integer('installment_count');
        return down != null &&
            down >= 0 &&
            amount != null &&
            amount > 0 &&
            count != null &&
            count > 0 &&
            count <= 600 &&
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
        final expected = nationalIdBirthDate(nationalId);
        return expected != null &&
            birthDate == identityDateText(expected) &&
            identity != null &&
            ownership != null &&
            consent;
      default:
        return true;
    }
  }

  /// Localized by the presentation layer; keep validation feedback actionable.
  String? validationIssue(String step) {
    if (valid(step)) return null;
    int? integer(String key) => int.tryParse('${values[key]}');
    bool missing(String key) => (values[key]?.toString().trim() ?? '').isEmpty;
    switch (step) {
      case 'category':
        return 'chooseCategory';
      case 'information':
        return propertyKind == null
            ? 'choosePropertyKind'
            : (values['title']?.toString().trim().length ?? 0) < 5
            ? 'titleTooShort'
            : 'descriptionTooShort';
      case 'location':
        if (values['governorate_id'] == null) return 'needGovernorate';
        if (values['area_id'] == null) return 'needArea';
        if ((values['street_address']?.toString().trim().length ?? 0) < 3) {
          return 'needStreet';
        }
        if (missing('building_number')) return 'needBuilding';
        if (integer('floor_number') == null) return 'needFloor';
        if (integer('floor_number')! < 0 || integer('floor_number')! > 100) {
          return 'floorInvalid';
        }
        if (missing('unit_number')) return 'needUnit';
        return 'checkCoordinates';
      case 'dimensions':
        if (!['net', 'gross'].contains(values['area_measurement'])) {
          return 'needAreaMeasurement';
        }
        if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch('${values['area_m2']}') ||
            (num.tryParse('${values['area_m2']}') ?? 0) <= 0 ||
            (num.tryParse('${values['area_m2']}') ?? 0) > 100000) {
          return 'areaInvalid';
        }
        if ((integer('bedrooms') ?? -1) < 0 ||
            (integer('bedrooms') ?? 101) > 100) {
          return 'bedroomsInvalid';
        }
        if ((integer('bathrooms') ?? 0) < 1 ||
            (integer('bathrooms') ?? 101) > 100) {
          return 'bathroomsInvalid';
        }
        return 'capacityInvalid';
      case 'verification':
        if (nationalId.isEmpty) return 'needNationalId';
        final expected = nationalIdBirthDate(nationalId);
        if (expected == null) return 'invalidNationalId';
        if (birthDate.isEmpty) return 'needBirthDate';
        if (birthDate != identityDateText(expected)) {
          return 'NATIONAL_ID_BIRTH_DATE_MISMATCH';
        }
        if (identity == null) return 'needIdentityImage';
        if (ownership == null) return 'needOwnershipImage';
        return 'needReviewConsent';
      case 'photos':
        return 'choosePhotos';
      case 'beds':
        if ((integer('total_beds') ?? 0) < 1) return 'totalBedsInvalid';
        if ((integer('total_beds') ?? 0) > (integer('capacity') ?? 0)) {
          return 'bedsExceedCapacity';
        }
        return 'availableBedsInvalid';
      case 'utilities':
        for (final key in ['water', 'electricity', 'gas']) {
          if (values[key] is! bool) return 'needAnswer:$key';
        }
        return 'checkUtilities';
      case 'finishing':
        return values['finishing'] == null ? 'needFinishing' : 'needFurnishing';
      case 'pricing':
        if ((moneyCents(values['price']) ?? 0) <= 0) return 'priceInvalid';
        if (values['negotiable'] is! bool) return 'needAnswer:negotiable';
        if (values['category'] == 'sale_installments') {
          return 'installmentError';
        }
        if (values['rental_period'] == null) return 'needRentalPeriod';
        if ((moneyCents(values['deposit']) ?? -1) < 0) return 'depositInvalid';
        return 'customMonthsInvalid';
      case 'elevator':
        return 'needAnswer:elevator';
      default:
        return 'chooseAnswer';
    }
  }

  Map<String, dynamic> payload() {
    final data = Map<String, dynamic>.of(values)..remove('governorate_id');
    data['property_kind'] =
        propertyKind ?? values['property_kind'] ?? 'apartment';
    if (data['category'] != 'shared_rental') data.remove('capacity');
    if (!['lux', 'super_lux', 'ultra_super_lux'].contains(data['finishing'])) {
      data.remove('furnished');
    }
    for (final key in ['latitude', 'longitude']) {
      if (data[key] == null || data[key] == '') data.remove(key);
    }
    for (final key in [
      'floor_number',
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
      final invalidStep = steps.firstWhere((step) => !valid(step));
      emit(ListingState(error: validationIssue(invalidStep)));
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
