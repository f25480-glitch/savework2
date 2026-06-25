import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/company_wage_policy.dart';
import '../models/shift_type.dart';
import '../models/work_day_record.dart';
import '../services/work_day_storage.dart';
import '../theme/app_theme.dart';
import '../utils/time_utils.dart';
import '../utils/wage_calculator.dart';
import '../widgets/common_widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.storage});

  final WorkDayStorage storage;

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  late String today;
  WorkDayRecord? todayRecord;
  List<WorkDayRecord> history = [];
  int totalWorkDays = 0;
  double totalHours = 0;
  double totalWage = 0;

  @override
  void initState() {
    super.initState();
    today = TimeUtils.todayDateKey();
    refresh();
  }

  Future<void> refresh() async {
    todayRecord = await widget.storage.getRecordForDate(today);
    history = await widget.storage.getHistoryExcludingToday(today);
    totalWorkDays = await widget.storage.getTotalWorkDays();
    totalHours = await widget.storage.getTotalWorkHours();
    totalWage = await widget.storage.getTotalEarnings();
    if (mounted) setState(() {});
  }

  Future<void> handleCheckIn() async {
    var record = todayRecord;
    if (record != null && record.hasCheckIn) {
      _showToast(AppStrings.toastAlreadyCheckedIn);
      return;
    }

    if (record == null) {
      record = WorkDayRecord(
        date: today,
        checkIn: TimeUtils.currentTime(),
        shiftType: ShiftType.auto,
      );
    } else {
      record.checkIn = TimeUtils.currentTime();
    }
    await widget.storage.saveRecord(record);
    _showToast(AppStrings.toastCheckInSuccess);
    await refresh();
  }

  Future<void> handleCheckOut() async {
    final record = todayRecord;
    if (record == null || !record.hasCheckIn) {
      _showToast(AppStrings.toastCheckInFirst);
      return;
    }
    if (record.hasCheckOut) {
      _showToast(AppStrings.toastAlreadyCheckedOut);
      return;
    }

    record.checkOut = TimeUtils.currentTime();
    if (record.shiftType == ShiftType.auto) {
      record.shiftType = CompanyWagePolicy.detectShiftFromTime(
        record.checkIn,
        record.checkOut,
      );
    }
    await widget.storage.saveRecord(record);
    _showToast(AppStrings.toastCheckOutSuccess);
    await refresh();
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final record = todayRecord;
    final canCheckIn = record == null || !record.hasCheckIn;
    final canCheckOut =
        record != null && record.hasCheckIn && !record.hasCheckOut;

    return RefreshIndicator(
      onRefresh: refresh,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 16),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  AppStrings.titleToday,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  TimeUtils.formatDisplayDateToday(),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Divider(height: 32, color: AppColors.divider),
                Row(
                  children: [
                    Expanded(
                      child: _TimeColumn(
                        label: AppStrings.labelCheckIn,
                        value: record?.hasCheckIn == true
                            ? record!.checkIn
                            : AppStrings.labelNotRecorded,
                        color: AppColors.checkIn,
                      ),
                    ),
                    Expanded(
                      child: _TimeColumn(
                        label: AppStrings.labelCheckOut,
                        value: record?.hasCheckOut == true
                            ? record!.checkOut
                            : AppStrings.labelNotRecorded,
                        color: AppColors.checkOut,
                      ),
                    ),
                  ],
                ),
                if (record != null && record.isCountableWorkDay) ...[
                  const SizedBox(height: 12),
                  Text(
                    TimeUtils.formatDurationLabel(
                      TimeUtils.calculateDuration(
                        record.checkIn,
                        record.checkOut,
                      ),
                    ),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${AppStrings.labelDayWage}: ${WageCalculator.formatMoney(WageCalculator.calculatePay(record))}',
                    style: const TextStyle(
                      color: AppColors.money,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: canCheckIn ? handleCheckIn : null,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.checkIn,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text(AppStrings.btnCheckIn),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: FilledButton(
                        onPressed: canCheckOut ? handleCheckOut : null,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.checkOut,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text(AppStrings.btnCheckOut),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  AppStrings.labelWageSummary,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  AppStrings.labelWageAutoNote,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                const Divider(height: 32, color: AppColors.divider),
                _SummaryRow(
                  label: AppStrings.labelTotalWorkDays,
                  value: '$totalWorkDays วัน',
                ),
                const SizedBox(height: 12),
                _SummaryRow(
                  label: AppStrings.labelTotalHours,
                  value: WageCalculator.formatHours(totalHours),
                ),
                const SizedBox(height: 12),
                _SummaryRow(
                  label: AppStrings.labelTotalWage,
                  value: WageCalculator.formatMoney(totalWage),
                  valueStyle: const TextStyle(
                    color: AppColors.money,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(
              AppStrings.labelHistory,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (history.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Text(
                  AppStrings.labelNoHistory,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                ),
              ),
            )
          else
            ...history.map((item) => _HistoryTile(record: item)),
        ],
      ),
    );
  }
}

class _TimeColumn extends StatelessWidget {
  const _TimeColumn({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.valueStyle,
  });

  final String label;
  final String value;
  final TextStyle? valueStyle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: valueStyle ??
              const TextStyle(
                color: AppColors.primary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.record});

  final WorkDayRecord record;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            TimeUtils.formatDisplayDate(record.date),
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          if (record.isHolidayOff)
            const Text('วันหยุด', style: TextStyle(color: AppColors.primary))
          else ...[
            Row(
              children: [
                Expanded(
                  child: _MiniColumn(
                    label: AppStrings.labelCheckIn,
                    value: record.hasCheckIn ? record.checkIn : '—',
                    color: AppColors.checkIn,
                  ),
                ),
                Expanded(
                  child: _MiniColumn(
                    label: AppStrings.labelCheckOut,
                    value: record.hasCheckOut ? record.checkOut : '—',
                    color: AppColors.checkOut,
                  ),
                ),
                Expanded(
                  child: _MiniColumn(
                    label: AppStrings.labelWorkHours,
                    value: record.isCountableWorkDay
                        ? TimeUtils.calculateDuration(
                            record.checkIn,
                            record.checkOut,
                          )
                        : '—',
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            if (record.isCountableWorkDay) ...[
              const SizedBox(height: 8),
              Text(
                WageCalculator.formatPayLine(record),
                style: const TextStyle(
                  color: AppColors.money,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _MiniColumn extends StatelessWidget {
  const _MiniColumn({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
