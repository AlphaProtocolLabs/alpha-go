import 'package:intl/intl.dart';

/// The guide shows every time in Singapore time (UTC+8), wherever the phone is.
class Sgt {
  static const offset = Duration(hours: 8);

  static DateTime of(DateTime t) => t.toUtc().add(offset);

  static String time(DateTime t) => DateFormat('h:mm a').format(of(t));
  static String day(DateTime t) => DateFormat('EEE d MMM').format(of(t));

  /// A guide day runs 05:00 to 05:00 so late parties stay with their evening.
  static DateTime dayStart(DateTime t) {
    final s = of(t).subtract(const Duration(hours: 5));
    return DateTime.utc(s.year, s.month, s.day, 5).subtract(offset);
  }

  /// Mon 5 to Sun 11 October 2026, as UTC instants for 05:00 SGT.
  static final List<DateTime> week = List.generate(
      7, (i) => DateTime.utc(2026, 10, 5 + i, 5).subtract(offset));
}
