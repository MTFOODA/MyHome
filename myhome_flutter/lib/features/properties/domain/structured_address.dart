String structuredAddress(
  Map<String, dynamic> values,
  String place, {
  required bool arabic,
}) {
  final street = '${values['street_address'] ?? ''}'.trim();
  return [
    if (street.isNotEmpty) '${values['building_number'] ?? ''} $street'.trim(),
    if (place.isNotEmpty) place,
    if (values['floor_number'] != null)
      arabic
          ? (values['floor_number'].toString() == '0'
                ? 'الدور الأرضي'
                : 'الدور ${values['floor_number']}')
          : 'Floor ${values['floor_number']}',
    if ('${values['unit_number'] ?? ''}'.isNotEmpty)
      arabic
          ? 'شقة رقم ${values['unit_number']}'
          : 'Apartment ${values['unit_number']}',
  ].join(arabic ? '، ' : ', ');
}
