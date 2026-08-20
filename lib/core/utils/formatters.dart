import 'package:intl/intl.dart';

/// Shared display formatting so currency and dates look identical everywhere.
class Formatters {
  const Formatters._();

  static final NumberFormat _rupees = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  static String fare(double value) => _rupees.format(value);

  static String historyDate(DateTime date) =>
      DateFormat('d MMM yyyy, h:mm a').format(date);

  static String distance(double km) => '${km.toStringAsFixed(1)} km';

  /// Seconds -> `m:ss`, used by the ETA countdown on the tracking screen.
  static String countdown(int totalSeconds) {
    final safe = totalSeconds < 0 ? 0 : totalSeconds;
    final minutes = safe ~/ 60;
    final seconds = safe % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
