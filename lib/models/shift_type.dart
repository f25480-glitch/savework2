class ShiftType {
  static const auto = 'auto';

  static const morning = 'morning';
  static const morningOt = 'morning_ot';
  static const early = 'early';
  static const afternoon = 'afternoon';
  static const afternoonOt = 'afternoon_ot';
  static const night = 'night';
  static const nightOt = 'night_ot';
  static const young = 'young';

  static const holiday = 'holiday';

  static const holidayMorning1730 = 'holiday_morning_1730';
  static const holidayMorning2000 = 'holiday_morning_2000';
  static const holidayAfternoon2200 = 'holiday_afternoon_2200';
  static const holidayAfternoonOt = 'holiday_afternoon_ot';
  static const holidayNight0530 = 'holiday_night_0530';
  static const holidayNight0800 = 'holiday_night_0800';

  static bool isHolidayOff(String shift) => shift == holiday;

  static bool isHolidayWork(String shift) =>
      shift.startsWith('holiday_') && shift != holiday;

  static const allValues = [
    auto,
    morning,
    morningOt,
    early,
    afternoon,
    afternoonOt,
    night,
    nightOt,
    young,
    holiday,
    holidayMorning1730,
    holidayMorning2000,
    holidayAfternoon2200,
    holidayAfternoonOt,
    holidayNight0530,
    holidayNight0800,
  ];
}
