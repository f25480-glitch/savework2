class CalendarCell {
  CalendarCell({
    required this.dateKey,
    required this.dayOfMonth,
    required this.hasRecord,
    required this.isToday,
    required this.isSelected,
  });

  final String? dateKey;
  final int dayOfMonth;
  final bool hasRecord;
  final bool isToday;
  final bool isSelected;

  bool get isEmpty => dateKey == null;
}
