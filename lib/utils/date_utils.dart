import 'package:intl/intl.dart';

// Check if two dates are the same day (ignoring time)
bool isSameDay(DateTime? a, DateTime? b) {
  if (a == null || b == null) return false;
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

// Normalize a DateTime to midnight
DateTime normalizeDate(DateTime date) {
  return DateTime(date.year, date.month, date.day);
}

// Format date as YYYY-MM-DD
String formatDate(DateTime date) {
  return DateFormat('yyyy-MM-dd').format(date);
}

// Format date as YYYY년 MM월 DD일
String formatDateKorean(DateTime date) {
  return DateFormat('yyyy년 MM월 dd일').format(date);
}

// Format number with thousand separators
String formatNumber(int number) {
  return NumberFormat('#,###').format(number);
}

// Parse formatted number string to int
int parseFormattedNumber(String text) {
  if (text.isEmpty) return 0;
  final cleaned = text.replaceAll(',', '');
  return int.tryParse(cleaned) ?? 0;
}
