import '../models/shift_type.dart';
import '../models/work_day_record.dart';
import '../utils/shift_definitions.dart';
import '../utils/time_utils.dart';

class CompanyWagePolicy {
  static const dailyWage = 400.0;
  static const specialAllowance = 12.50;
  static const nightShiftAllowance = 165.0;
  static const nightMealAllowance = 65.0;
  static const nightMilkAllowance = 65.0;
  static const housingRentMonthly = 1000.0;

  static const hourlyRate = 50.0;
  static const regularOtMultiplier = 1.5;
  static const holidayWorkMultiplier = 2.0;
  static const holidayOtMultiplier = 3.0;

  static String resolveShift(WorkDayRecord record) {
    final shift = record.shiftType;
    if (shift.isNotEmpty && shift != ShiftType.auto) return shift;
    if (record.hasCheckIn) {
      return detectShiftFromTime(record.checkIn, record.checkOut);
    }
    return ShiftType.morning;
  }

  static String detectShiftFromTime(String checkIn, String checkOut) {
    if (checkIn.isEmpty) return ShiftType.morning;

    final startHour = TimeUtils.parseHour(checkIn);
    final worked = checkOut.isNotEmpty
        ? TimeUtils.minutesFromCheckIn(checkIn, checkOut)
        : 0;

    if (startHour >= 22) {
      return _detectNightEnd(checkOut, worked, true);
    }
    if (startHour >= 19 || startHour < 6) {
      return _detectNightEnd(checkOut, worked, false);
    }

    if (startHour >= 13 && startHour < 16) {
      if (worked > 8 * 60 + 30) return ShiftType.afternoonOt;
      return ShiftType.afternoon;
    }

    if (startHour >= 5 && startHour < 7) return ShiftType.early;

    if (worked >= 11 * 60 + 30) return ShiftType.morningOt;
    return ShiftType.morning;
  }

  static String _detectNightEnd(
    String checkOut,
    int workedMinutes,
    bool young,
  ) {
    if (young) return ShiftType.young;
    if (checkOut.isEmpty) return ShiftType.night;
    final outHour = TimeUtils.parseHour(checkOut);
    if (workedMinutes >= 11 * 60 || outHour >= 7) return ShiftType.nightOt;
    return ShiftType.night;
  }

  static double calculateDailyPay(WorkDayRecord record) {
    final shift = resolveShift(record);

    if (shift == ShiftType.holiday) return 0;
    if (!record.hasCompleteWorkTime && !ShiftType.isHolidayWork(shift)) {
      return 0;
    }
    if (!record.hasCompleteWorkTime) return 0;

    var base = dailyWage + specialAllowance;
    if (ShiftType.isHolidayWork(shift)) {
      base *= holidayWorkMultiplier;
    }

    var total = base;

    if (ShiftDefinitions.isNightAllowance(shift)) {
      total += nightShiftAllowance + nightMealAllowance + nightMilkAllowance;
    }

    total += calculateOtPay(record, shift);
    return total;
  }

  static double calculateOtPay(WorkDayRecord record, String shift) {
    if (!record.hasCompleteWorkTime) return 0;

    var otHours = getBuiltInOtHours(shift);

    final startMin = TimeUtils.toMinutesOfDay(record.checkIn);
    var standardEnd = ShiftDefinitions.standardEndMinutes(shift, record.checkIn);
    var standardDuration = standardEnd - startMin;
    if (standardDuration < 0) standardDuration += 24 * 60;

    final extraOtMin = TimeUtils.calculateOtMinutes(
      record.checkIn,
      record.checkOut,
      standardDuration,
    );
    otHours += extraOtMin / 60.0;

    if (otHours <= 0) return 0;

    final multiplier = ShiftType.isHolidayWork(shift)
        ? holidayOtMultiplier
        : regularOtMultiplier;
    return otHours * hourlyRate * multiplier;
  }

  static double getBuiltInOtHours(String shift) {
    switch (shift) {
      case ShiftType.morningOt:
      case ShiftType.holidayMorning2000:
        return 2.5;
      case ShiftType.nightOt:
      case ShiftType.holidayNight0800:
        return 2.5;
      case ShiftType.afternoonOt:
      case ShiftType.holidayAfternoonOt:
        return 2.0;
      default:
        return 0;
    }
  }

  static bool isNightShift(String shift) =>
      ShiftDefinitions.isNightAllowance(shift);
}
