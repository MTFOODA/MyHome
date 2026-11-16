import 'number_input.dart';

/// Structural date validation only; document authenticity needs human review.
DateTime? nationalIdBirthDate(String input, {DateTime? today}) {
  final number = latinDigits(input);
  if (!RegExp(r'^[23][0-9]{13}$').hasMatch(number)) return null;
  final year =
      (number[0] == '2' ? 1900 : 2000) + int.parse(number.substring(1, 3));
  final month = int.parse(number.substring(3, 5));
  final day = int.parse(number.substring(5, 7));
  final date = DateTime(year, month, day);
  final now = today ?? DateTime.now();
  if (date.year != year ||
      date.month != month ||
      date.day != day ||
      !date.isBefore(DateTime(now.year, now.month, now.day))) {
    return null;
  }
  return date;
}

String identityDateText(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
