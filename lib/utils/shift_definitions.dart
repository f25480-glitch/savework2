import '../models/shift_type.dart';

class ShiftDefinitions {
  static bool isNightAllowance(String shift) {
    return shift == ShiftType.night ||
        shift == ShiftType.nightOt ||
        shift == ShiftType.holidayNight0530 ||
        shift == ShiftType.holidayNight0800 ||
        shift == ShiftType.young;
  }

  static int standardEndMinutes(String shift, String checkIn) {
    switch (shift) {
      case ShiftType.morning:
      case ShiftType.holidayMorning1730:
        return 17 * 60 + 30;
      case ShiftType.morningOt:
      case ShiftType.holidayMorning2000:
        return 20 * 60;
      case ShiftType.early:
        return 14 * 60;
      case ShiftType.afternoon:
      case ShiftType.holidayAfternoon2200:
        return 22 * 60;
      case ShiftType.afternoonOt:
      case ShiftType.holidayAfternoonOt:
        return 24 * 60;
      case ShiftType.night:
      case ShiftType.holidayNight0530:
        return 24 * 60 + 5 * 60 + 30;
      case ShiftType.nightOt:
      case ShiftType.holidayNight0800:
        return 24 * 60 + 8 * 60;
      case ShiftType.young:
        return 24 * 60 + 6 * 60;
      default:
        return 17 * 60 + 30;
    }
  }

  static bool requiresWorkTime(String shift) => shift != ShiftType.holiday;
}
