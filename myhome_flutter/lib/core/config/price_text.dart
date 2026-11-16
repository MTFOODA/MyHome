/// Format exact decimal strings for display without changing financial values.
String priceText(String value) {
  final match = RegExp(r'^(\d+)(?:\.(\d{1,2}))?$').firstMatch(value);
  if (match == null) return value;
  final whole = match[1]!.replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+$)'),
    (match) => '${match[1]},',
  );
  final fraction = match[2];
  return fraction == null || int.parse(fraction) == 0
      ? whole
      : '$whole.$fraction';
}
