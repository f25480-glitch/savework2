import 'package:intl/intl.dart';

class TimeUtils {
  static final _dateKeyFormat = DateFormat('yyyy-MM-dd');
  static final _timeFormat = DateFormat('HH:mm');
  static final _displayDateFormat = DateFormat('d MMMM yyyy', 'th');
  static final _monthYearFormat = DateFormat('MMMM yyyy', 'th');

  static String todayDateKey() => _dateKeyFormat.format(DateTime.now());

  static String currentTime() => _timeFormat.format(DateTime.now());

  static String formatDisplayDate(String dateKey) {
    try {
      return _displayDateFormat.format(_dateKeyFormat.parse(dateKey));
    } catch (_) {
      return dateKey;
    }
  }

  static String formatDisplayDateToday() =>
      _displayDateFormat.format(DateTime.now());

  static String calculateDuration(String checkIn, String checkOut) {
    final minutes = calculateWorkMinutes(checkIn, checkOut);
    if (minutes <= 0) return '';
    return '${minutes ~/ 60} ชม. ${minutes % 60} น.';
  }

  static int calculateWorkMinutes(String checkIn, String checkOut) {
    try {
      final inDate = _timeFormat.parse(checkIn);
      final outDate = _timeFormat.parse(checkOut);
      var diffMs = outDate.difference(inDate).inMilliseconds;
      if (diffMs < 0) diffMs += 24 * 60 * 60 * 1000;
      if (diffMs < 0) return 0;
      return diffMs ~/ (60 * 1000);
    } catch (_) {
      return 0;
    }
  }

  static String formatDurationLabel(String duration) {
    if (duration.isEmpty) return '';
    return 'ชั่วโมงทำงาน: $duration';
  }

  static String formatTime(int hour, int minute) =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  static int parseHour(String timeText) => parseTimeOrNow(timeText)[0];

  static int toMinutesOfDay(String timeText) {
    final parts = parseTimeOrNow(timeText);
    return parts[0] * 60 + parts[1];
  }

  static int minutesFromCheckIn(String checkIn, String checkOut) {
    final inMin = toMinutesOfDay(checkIn);
    final outMin = toMinutesOfDay(checkOut);
    if (outMin >= inMin) return outMin - inMin;
    return (24 * 60 - inMin) + outMin;
  }

  static int calculateOtMinutes(
    String checkIn,
    String checkOut,
    int standardEndFromStart,
  ) {
    final worked = minutesFromCheckIn(checkIn, checkOut);
    return (worked - standardEndFromStart).clamp(0, worked);
  }

  static List<int> parseTimeOrNow(String? timeText) {
    if (timeText != null && timeText.isNotEmpty) {
      try {
        final date = _timeFormat.parse(timeText);
        return [date.hour, date.minute];
      } catch (_) {}
    }
    final now = DateTime.now();
    return [now.hour, now.minute];
  }

  static bool isCheckOutAfterCheckIn(String checkIn, String checkOut) {
    if (checkIn.isEmpty || checkOut.isEmpty) return false;
    return minutesFromCheckIn(checkIn, checkOut) > 0;
  }

  static String dateKey(int year, int month, int dayOfMonth) =>
      _dateKeyFormat.format(DateTime(year, month + 1, dayOfMonth));

  static String formatMonthYear(int year, int month) =>
      _monthYearFormat.format(DateTime(year, month + 1));
}
