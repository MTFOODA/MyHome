import 'package:flutter_test/flutter_test.dart';
import 'package:myhome_flutter/features/properties/presentation/listing_cubit.dart';
import 'package:myhome_flutter/features/properties/domain/property_repository.dart';
import 'fake_property_repository.dart';

void fill(ListingCubit cubit) {
  cubit.values.addAll({
    'title': 'A bright apartment',
    'description': 'This apartment is spacious and ready for testing.',
    'category': 'private_rental',
    'governorate_id': 'cairo',
    'area_id': 'maadi',
    'approximate_location': 'Near the main street',
    'street_address': 'Test street',
    'building_number': '7',
    'floor_number': 4,
    'unit_number': '12',
    'area_m2': '120',
    'area_measurement': 'net',
    'bedrooms': '2',
    'bathrooms': '1',
    'capacity': '4',
    'water': true,
    'electricity': true,
    'gas': false,
    'elevator': false,
    'finishing': 'plastered',
    'price': '10000',
    'negotiable': false,
    'rental_period': 'one_year',
    'deposit': '5000',
  });
  cubit.photos.addAll([
    const UploadImage('a.png', [1]),
    const UploadImage('b.png', [2]),
  ]);
  cubit.identity = const UploadImage('id.png', [1]);
  cubit.ownership = const UploadImage('deed.png', [1]);
  cubit.nationalId = '30001011234567';
  cubit.birthDate = '2000-01-01';
  cubit.consent = true;
}

void main() {
  test(
    'capacity is only required for shared housing; area basis and explicit furnishing are enforced',
    () {
      final cubit = ListingCubit(FakePropertyRepository());
      addTearDown(cubit.close);
      fill(cubit);
      cubit.values.remove('capacity');
      expect(cubit.valid('dimensions'), true);
      expect(cubit.payload().containsKey('capacity'), false);
      cubit.values['category'] = 'shared_rental';
      expect(cubit.valid('dimensions'), false);
      cubit.values['capacity'] = '4';
      expect(cubit.valid('dimensions'), true);
      cubit.values.remove('area_measurement');
      expect(cubit.valid('dimensions'), false);
      cubit.values['area_measurement'] = 'gross';
      cubit.values['finishing'] = 'lux';
      expect(cubit.valid('finishing'), false);
      cubit.values['furnished'] = false;
      expect(cubit.valid('finishing'), true);
      cubit.values['finishing'] = 'plastered';
      expect(cubit.payload().containsKey('furnished'), false);
    },
  );
  test('Arabic and Persian numerals preserve exact price input', () {
    expect(ListingCubit.latinDigits('١٢٣٫٤٥'), '123.45');
    expect(ListingCubit.latinDigits('۱۲۳'), '123');
  });
  test(
    'mandatory yes/no values start unanswered and false is a valid deliberate answer',
    () {
      final cubit = ListingCubit(FakePropertyRepository());
      addTearDown(cubit.close);
      for (final key in [
        'water',
        'electricity',
        'gas',
        'elevator',
        'negotiable',
      ]) {
        expect(cubit.valid(key), false);
        cubit.setValue(key, false);
        expect(cubit.valid(key), true);
      }
    },
  );
  test('installments use exact cents and invalid totals fail', () {
    final cubit = ListingCubit(FakePropertyRepository());
    addTearDown(cubit.close);
    cubit.values.addAll({
      'category': 'sale_installments',
      'price': '100.30',
      'down_payment': '10.00',
      'installment_count': '3',
      'installment_amount': '30.10',
    });
    expect(cubit.valid('installments'), true);
    cubit.values['installment_amount'] = '30.09';
    expect(cubit.valid('installments'), false);
    expect(ListingCubit.moneyCents('1.999'), isNull);
  });
  test('ID birth date mismatch prevents submission', () {
    final cubit = ListingCubit(FakePropertyRepository());
    addTearDown(cubit.close);
    fill(cubit);
    expect(cubit.valid('verification'), true);
    cubit.birthDate = '2000-01-02';
    expect(cubit.valid('verification'), false);
  });
  test(
    'submission requires every step and clears sensitive images on success',
    () async {
      final repo = FakePropertyRepository();
      final cubit = ListingCubit(repo);
      addTearDown(cubit.close);
      await cubit.submit();
      expect(repo.createCalls, 0);
      fill(cubit);
      await cubit.submit();
      expect(cubit.state.submitted, true);
      expect(cubit.identity, isNull);
      expect(cubit.nationalId, isEmpty);
      expect(repo.submittedPayload!.containsKey('governorate_id'), false);
    },
  );
  test(
    'retry after failed submit updates the same draft rather than duplicating it',
    () async {
      final repo = FakePropertyRepository()..failSubmit = true;
      final cubit = ListingCubit(repo);
      addTearDown(cubit.close);
      fill(cubit);
      await cubit.submit();
      expect(cubit.state.error, 'saveError');
      cubit.values['title'] = 'An updated title';
      repo.failSubmit = false;
      await cubit.submit();
      expect(repo.createCalls, 1);
      expect(repo.updateCalls, 1);
      expect(repo.submittedPayload!['title'], 'An updated title');
    },
  );
}
