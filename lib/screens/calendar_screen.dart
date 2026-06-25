import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/calendar_cell.dart';
import '../models/work_day_record.dart';
import '../services/work_day_storage.dart';
import '../theme/app_theme.dart';
import '../utils/calendar_month_helper.dart';
import '../utils/shift_labels.dart';
import '../utils/time_utils.dart';
import '../utils/wage_calculator.dart';
import '../widgets/common_widgets.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({
    super.key,
    required this.storage,
    required this.onOpenDayDetail,
  });

  final WorkDayStorage storage;
  final Future<void> Function(String dateKey) onOpenDayDetail;

  @override
  State<CalendarScreen> createState() => CalendarScreenState();
}

class CalendarScreenState extends State<CalendarScreen> {
  late int displayYear;
  late int displayMonth;
  late String selectedDateKey;
  late String todayDateKey;

  List<CalendarCell> cells = [];
  Set<String> recordedDates = {};
  WorkDayRecord? selectedRecord;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    displayYear = now.year;
    displayMonth = now.month - 1;
    todayDateKey = TimeUtils.todayDateKey();
    selectedDateKey = todayDateKey;
    refresh();
  }

  Future<void> refresh() async {
    recordedDates = {};
    for (final record in await widget.storage.getAllRecords()) {
      if (record.hasContent) recordedDates.add(record.date);
    }
    cells = CalendarMonthHelper.buildMonthGrid(
      year: displayYear,
      month: displayMonth,
      recordedDates: recordedDates,
      selectedDateKey: selectedDateKey,
      todayDateKey: todayDateKey,
    );
    selectedRecord = await widget.storage.getRecordForDate(selectedDateKey);
    if (mounted) setState(() {});
  }

  void changeMonth(int delta) {
    final date = DateTime(displayYear, displayMonth + 1 + delta);
    displayYear = date.year;
    displayMonth = date.month - 1;
    refresh();
  }

  Future<void> selectDay(String dateKey) async {
    selectedDateKey = dateKey;
    await refresh();
  }

  Future<void> openDayDetail(String dateKey) async {
    await selectDay(dateKey);
    await widget.onOpenDayDetail(dateKey);
    await refresh();
  }

  String _selectedDetailText() {
    final record = selectedRecord;
    if (record == null || !record.hasContent) {
      return AppStrings.labelNoRecordDay;
    }
    if (record.isHolidayOff) return AppStrings.shiftHoliday;

    final detail = StringBuffer();
    if (record.hasCheckIn) {
      detail.write('${AppStrings.labelCheckIn} ${record.checkIn}');
    }
    if (record.hasCheckOut) {
      if (detail.isNotEmpty) detail.write('  ');
      detail.write('${AppStrings.labelCheckOut} ${record.checkOut}');
    }
    if (record.isCountableWorkDay) {
      detail.writeln();
      detail.write(
        TimeUtils.formatDurationLabel(
          TimeUtils.calculateDuration(record.checkIn, record.checkOut),
        ),
      );
      detail.writeln();
      detail.write(
        '${AppStrings.labelDayWage}: ${WageCalculator.formatMoney(WageCalculator.calculatePay(record))}',
      );
      detail.writeln();
      detail.write(
        '${AppStrings.labelShift}: ${ShiftLabels.getLabel(record.effectiveShift)}',
      );
    }
    if (record.hasNote) {
      detail.writeln();
      detail.write('${AppStrings.labelNote}: ${record.note}');
    }
    return detail.toString();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: refresh,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 16),
        children: [
          AppCard(
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => changeMonth(-1),
                      tooltip: AppStrings.btnPrevMonth,
                      icon: const Icon(Icons.chevron_left, color: AppColors.primary),
                    ),
                    Expanded(
                      child: Text(
                        TimeUtils.formatMonthYear(displayYear, displayMonth),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => changeMonth(1),
                      tooltip: AppStrings.btnNextMonth,
                      icon: const Icon(Icons.chevron_right, color: AppColors.primary),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: AppStrings.weekdayLabels
                      .map(
                        (label) => Expanded(
                          child: Text(
                            label,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 8),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    childAspectRatio: 1.1,
                  ),
                  itemCount: cells.length,
                  itemBuilder: (context, index) {
                    final cell = cells[index];
                    if (cell.isEmpty) return const SizedBox.shrink();
                    return _CalendarDayTile(
                      cell: cell,
                      onTap: () => openDayDetail(cell.dateKey!),
                    );
                  },
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () => openDayDetail(selectedDateKey),
            borderRadius: BorderRadius.circular(16),
            child: AppCard(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    AppStrings.labelSelectedDay,
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    TimeUtils.formatDisplayDate(selectedDateKey),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _selectedDetailText(),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    AppStrings.labelTapToEdit,
                    style: TextStyle(color: AppColors.primary, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarDayTile extends StatelessWidget {
  const _CalendarDayTile({
    required this.cell,
    required this.onTap,
  });

  final CalendarCell cell;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    Color? bgColor;
    Color textColor = AppColors.textPrimary;
    var fontWeight = FontWeight.normal;

    if (cell.isSelected) {
      bgColor = AppColors.primary;
      textColor = Colors.white;
      fontWeight = FontWeight.bold;
    } else if (cell.isToday) {
      bgColor = AppColors.primaryLight;
      fontWeight = FontWeight.bold;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${cell.dayOfMonth}',
                style: TextStyle(
                  color: textColor,
                  fontWeight: fontWeight,
                ),
              ),
              if (cell.hasRecord)
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(top: 2),
                  decoration: BoxDecoration(
                    color: cell.isSelected ? Colors.white : AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
