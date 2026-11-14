String latinDigits(String input) {
  const source = '٠١٢٣٤٥٦٧٨٩۰۱۲۳۴۵۶۷۸۹';
  return input
      .split('')
      .map((character) {
        final index = source.indexOf(character);
        return index < 0 ? character : '${index % 10}';
      })
      .join()
      .replaceAll('٫', '.');
}
