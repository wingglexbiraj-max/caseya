import 'package:intl/intl.dart';

class Formatters {
  static final NumberFormat _integerFormat = NumberFormat('#,##0');
  static final NumberFormat _decimalFormat = NumberFormat('#,##0.00');
  static final NumberFormat _oneDecimalFormat = NumberFormat('#,##0.0');
  static final DateFormat _dateFormat = DateFormat('dd MMM yyyy');
  static final DateFormat _timeFormat = DateFormat('hh:mm a');
  static final DateFormat _timeWithSecondsFormat = DateFormat('HH:mm:ss');
  static final DateFormat _isoDateFormat = DateFormat('yyyy-MM-dd');

  /// Format Time with seconds, e.g. 13:08:25
  static String formatTimeWithSeconds(DateTime dateTime) {
    return _timeWithSecondsFormat.format(dateTime);
  }

  /// Format an integer quantity with commas, e.g. 3,000
  static String formatInt(num value) {
    return _integerFormat.format(value.round());
  }

  /// Format decimal with 2 decimal places, e.g. 105.88
  static String formatDecimal(double value) {
    if (value.isInfinite || value.isNaN) return '0.00';
    return _decimalFormat.format(value);
  }

  /// Format decimal with smart trimming (e.g. 1500 instead of 1500.00 if whole)
  static String formatSmart(double value) {
    if (value.isInfinite || value.isNaN) return '0';
    if (value == value.roundToDouble()) {
      return _integerFormat.format(value.toInt());
    }
    return _decimalFormat.format(value);
  }

  /// Format percentage e.g. 4.50 %
  static String formatPercent(double value) {
    if (value.isInfinite || value.isNaN) return '0.0 %';
    return '${_oneDecimalFormat.format(value)} %';
  }

  /// Format Date, e.g. 24 Sep 2026
  static String formatDate(DateTime date) {
    return _dateFormat.format(date);
  }

  /// Format Time, e.g. 10:32 AM
  static String formatTime(DateTime dateTime) {
    return _timeFormat.format(dateTime);
  }

  /// Format ISO Date, e.g. 2026-09-24
  static String formatIsoDate(DateTime date) {
    return _isoDateFormat.format(date);
  }

  /// Parse string to double safely
  static double parseDouble(String? text, {double defaultValue = 0.0}) {
    if (text == null || text.trim().isEmpty) return defaultValue;
    final cleaned = text.replaceAll(',', '').trim();
    return double.tryParse(cleaned) ?? defaultValue;
  }
}
