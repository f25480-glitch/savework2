import '../models/calendar_cell.dart';
import 'time_utils.dart';

class CalendarMonthHelper {
  static List<CalendarCell> buildMonthGrid({
    required int year,
    required int month,
    required Set<String> recordedDates,
    required String selectedDateKey,
    required String todayDateKey,
  }) {
    final cells = <CalendarCell>[];
    final firstDay = DateTime(year, month + 1, 1);
    final startOffset = firstDay.weekday % 7;
    final daysInMonth = DateTime(year, month + 2, 0).day;

    for (var i = 0; i < startOffset; i++) {
      cells.add(CalendarCell(
        dateKey: null,
        dayOfMonth: 0,
        hasRecord: false,
        isToday: false,
        isSelected: false,
      ));
    }

    for (var day = 1; day <= daysInMonth; day++) {
      final dateKey = TimeUtils.dateKey(year, month, day);
      cells.add(CalendarCell(
        dateKey: dateKey,
        dayOfMonth: day,
        hasRecord: recordedDates.contains(dateKey),
        isToday: dateKey == todayDateKey,
        isSelected: dateKey == selectedDateKey,
      ));
    }

    while (cells.length % 7 != 0) {
      cells.add(CalendarCell(
        dateKey: null,
        dayOfMonth: 0,
        hasRecord: false,
        isToday: false,
        isSelected: false,
      ));
    }

    return cells;
  }
}
