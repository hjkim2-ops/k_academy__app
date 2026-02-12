import 'package:flutter/services.dart';

// Custom input formatter for thousand separators
class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Remove all non-digit characters
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    if (digitsOnly.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    // Format with thousand separators
    final formatted = _formatWithCommas(digitsOnly);

    // Calculate new cursor position
    final oldCommaCount = oldValue.text.split(',').length - 1;
    final newCommaCount = formatted.split(',').length - 1;
    final commaDiff = newCommaCount - oldCommaCount;

    var newOffset = newValue.selection.end + commaDiff;
    newOffset = newOffset.clamp(0, formatted.length);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: newOffset),
    );
  }

  String _formatWithCommas(String value) {
    if (value.isEmpty) return '';

    // Reverse the string to make it easier to add commas
    final reversed = value.split('').reversed.join();
    final chunks = <String>[];

    for (var i = 0; i < reversed.length; i += 3) {
      final end = (i + 3 < reversed.length) ? i + 3 : reversed.length;
      chunks.add(reversed.substring(i, end));
    }

    // Join chunks with comma and reverse back
    return chunks.join(',').split('').reversed.join();
  }
}

// Helper function to parse formatted number
int parseFormattedNumber(String text) {
  if (text.isEmpty) return 0;
  final cleaned = text.replaceAll(',', '');
  return int.tryParse(cleaned) ?? 0;
}

// Helper function to format number with commas
String formatNumber(int number) {
  if (number == 0) return '0';

  final str = number.toString();
  final reversed = str.split('').reversed.join();
  final chunks = <String>[];

  for (var i = 0; i < reversed.length; i += 3) {
    final end = (i + 3 < reversed.length) ? i + 3 : reversed.length;
    chunks.add(reversed.substring(i, end));
  }

  return chunks.join(',').split('').reversed.join();
}
