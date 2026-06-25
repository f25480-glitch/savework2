import 'package:intl/intl.dart';

import '../l10n/app_strings.dart';
import '../models/company_wage_policy.dart';
import '../models/shift_type.dart';
import '../models/work_day_record.dart';
import '../utils/shift_labels.dart';
import '../utils/time_utils.dart';

class WageCalculator {
  static double calculatePay(WorkDayRecord record) =>
      CompanyWagePolicy.calculateDailyPay(record);

  static double sumPay(List<WorkDayRecord> records) {
    var total = 0.0;
    for (final record in records) {
      total += calculatePay(record);
    }
    return total;
  }

  static int countWorkDays(List<WorkDayRecord> records) {
    var count = 0;
    for (final record in records) {
      if (record.isCountableWorkDay) count++;
    }
    return count;
  }

  static double sumWorkHours(List<WorkDayRecord> records) {
    var total = 0.0;
    for (final record in records) {
      if (record.hasCompleteWorkTime && !record.isHolidayOff) {
        total += TimeUtils.calculateWorkMinutes(
              record.checkIn,
              record.checkOut,
            ) /
            60.0;
      }
    }
    return total;
  }

  static String formatMoney(double amount) {
    final formatter = NumberFormat('#,##0.00', 'en_US');
    return '${formatter.format(amount)} บาท';
  }

  static String formatHours(double hours) {
    final totalMinutes = (hours * 60).round();
    final hourPart = totalMinutes ~/ 60;
    final minutePart = totalMinutes % 60;
    return '$hourPart ชม. $minutePart น.';
  }

  static String formatPayLine(WorkDayRecord record) {
    if (record.isHolidayOff) return 'วันหยุด';
    if (!record.isCountableWorkDay) return '';
    final duration =
        TimeUtils.calculateDuration(record.checkIn, record.checkOut);
    final pay = calculatePay(record);
    return '$duration = ${formatMoney(pay)}';
  }

  static String formatPayBreakdown(WorkDayRecord record) {
    if (record.isHolidayOff) return AppStrings.shiftHoliday;
    if (!record.hasCompleteWorkTime) return '';

    final shift = record.effectiveShift;
    final shiftLabel = ShiftLabels.getLabel(shift);
    final pay = calculatePay(record);
    final otPay = CompanyWagePolicy.calculateOtPay(record, shift);

    final sb = StringBuffer();
    sb.writeln('${AppStrings.labelShift}: $shiftLabel');

    if (ShiftType.isHolidayWork(shift)) {
      sb.writeln(
        '${AppStrings.labelWageHoliday}: x${CompanyWagePolicy.holidayWorkMultiplier.toInt()}',
      );
    }

    sb.writeln(
      '${AppStrings.labelWageBase}: ${formatMoney(ShiftType.isHolidayWork(shift) ? CompanyWagePolicy.dailyWage * CompanyWagePolicy.holidayWorkMultiplier : CompanyWagePolicy.dailyWage)}',
    );
    sb.write(
      '${AppStrings.labelWageSpecial}: ${formatMoney(ShiftType.isHolidayWork(shift) ? CompanyWagePolicy.specialAllowance * CompanyWagePolicy.holidayWorkMultiplier : CompanyWagePolicy.specialAllowance)}',
    );

    if (CompanyWagePolicy.isNightShift(shift)) {
      sb.writeln('\n${AppStrings.labelWageNightShift}: ${formatMoney(CompanyWagePolicy.nightShiftAllowance)}');
      sb.writeln('${AppStrings.labelWageNightMeal}: ${formatMoney(CompanyWagePolicy.nightMealAllowance)}');
      sb.write('${AppStrings.labelWageNightMilk}: ${formatMoney(CompanyWagePolicy.nightMilkAllowance)}');
    }

    if (otPay > 0) {
      sb.writeln('\n${AppStrings.labelWageOt}: ${formatMoney(otPay)}');
    }

    sb.writeln('\n${AppStrings.labelDayWage}: ${formatMoney(pay)}');
    return sb.toString().trim();
  }
}
