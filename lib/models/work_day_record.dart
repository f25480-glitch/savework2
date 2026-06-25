import 'company_wage_policy.dart';
import 'shift_type.dart';

class WorkDayRecord {
  WorkDayRecord({
    required this.date,
    String? checkIn,
    String? checkOut,
    String? note,
    String? shiftType,
  })  : checkIn = checkIn ?? '',
        checkOut = checkOut ?? '',
        note = note ?? '',
        shiftType = _normalizeShift(shiftType);

  final String date;
  String checkIn;
  String checkOut;
  String note;
  String shiftType;

  String get effectiveShift => CompanyWagePolicy.resolveShift(this);

  bool get hasCheckIn => checkIn.isNotEmpty;
  bool get hasCheckOut => checkOut.isNotEmpty;
  bool get hasNote => note.isNotEmpty;

  bool get hasContent =>
      shiftType == ShiftType.holiday || hasCheckIn || hasCheckOut || hasNote;

  bool get isHolidayOff => shiftType == ShiftType.holiday;

  bool get hasCompleteWorkTime {
    if (shiftType == ShiftType.holiday) return true;
    return hasCheckIn && hasCheckOut;
  }

  bool get isCountableWorkDay {
    if (shiftType == ShiftType.holiday) return false;
    return hasCompleteWorkTime;
  }

  static String _normalizeShift(String? shiftType) {
    if (shiftType == null || shiftType.isEmpty) return ShiftType.auto;
    return shiftType;
  }

  Map<String, dynamic> toJson() => {
        'date': date,
        'checkIn': checkIn,
        'checkOut': checkOut,
        'note': note,
        'shiftType': shiftType,
      };

  factory WorkDayRecord.fromJson(Map<String, dynamic> json) => WorkDayRecord(
        date: json['date'] as String,
        checkIn: json['checkIn'] as String? ?? '',
        checkOut: json['checkOut'] as String? ?? '',
        note: json['note'] as String? ?? '',
        shiftType: json['shiftType'] as String? ?? ShiftType.auto,
      );
}
