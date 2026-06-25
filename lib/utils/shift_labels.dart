import '../l10n/app_strings.dart';
import '../models/shift_type.dart';

class ShiftLabels {
  static String getLabel(String shiftType) {
    switch (shiftType) {
      case ShiftType.morning:
        return AppStrings.shiftMorning;
      case ShiftType.morningOt:
        return AppStrings.shiftMorningOt;
      case ShiftType.early:
        return AppStrings.shiftEarly;
      case ShiftType.afternoon:
        return AppStrings.shiftAfternoon;
      case ShiftType.afternoonOt:
        return AppStrings.shiftAfternoonOt;
      case ShiftType.night:
        return AppStrings.shiftNight;
      case ShiftType.nightOt:
        return AppStrings.shiftNightOt;
      case ShiftType.young:
        return AppStrings.shiftYoung;
      case ShiftType.holiday:
        return AppStrings.shiftHoliday;
      case ShiftType.holidayMorning1730:
        return AppStrings.shiftHolidayMorning1730;
      case ShiftType.holidayMorning2000:
        return AppStrings.shiftHolidayMorning2000;
      case ShiftType.holidayAfternoon2200:
        return AppStrings.shiftHolidayAfternoon2200;
      case ShiftType.holidayAfternoonOt:
        return AppStrings.shiftHolidayAfternoonOt;
      case ShiftType.holidayNight0530:
        return AppStrings.shiftHolidayNight0530;
      case ShiftType.holidayNight0800:
        return AppStrings.shiftHolidayNight0800;
      case ShiftType.auto:
      default:
        return AppStrings.shiftAuto;
    }
  }
}
