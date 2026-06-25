import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/work_day_record.dart';
import '../utils/wage_calculator.dart';

class WorkDayStorage {
  static const _keyRecords = 'records';

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<List<WorkDayRecord>> getAllRecords() async {
    await init();
    final json = _prefs!.getString(_keyRecords) ?? '[]';
    final records = <WorkDayRecord>[];
    try {
      final list = jsonDecode(json) as List<dynamic>;
      for (final item in list) {
        final obj = item as Map<String, dynamic>;
        records.add(WorkDayRecord.fromJson(obj));
      }
    } catch (_) {
      return records;
    }
    records.sort((a, b) => b.date.compareTo(a.date));
    return records;
  }

  Future<WorkDayRecord?> getRecordForDate(String date) async {
    for (final record in await getAllRecords()) {
      if (record.date == date) return record;
    }
    return null;
  }

  Future<void> saveRecord(WorkDayRecord record) async {
    if (!record.hasContent) {
      await deleteRecord(record.date);
      return;
    }

    final records = await getAllRecords();
    var updated = false;
    for (var i = 0; i < records.length; i++) {
      if (records[i].date == record.date) {
        records[i] = record;
        updated = true;
        break;
      }
    }
    if (!updated) records.add(record);
    await _saveAll(records);
  }

  Future<void> deleteRecord(String date) async {
    final records = await getAllRecords();
    records.removeWhere((record) => record.date == date);
    await _saveAll(records);
  }

  Future<void> _saveAll(List<WorkDayRecord> records) async {
    await init();
    final array = records.map((r) => r.toJson()).toList();
    await _prefs!.setString(_keyRecords, jsonEncode(array));
  }

  Future<List<WorkDayRecord>> getHistoryExcludingToday(String today) async {
    final history = <WorkDayRecord>[];
    for (final record in await getAllRecords()) {
      if (record.date != today) history.add(record);
    }
    return history;
  }

  Future<double> getTotalEarnings() async =>
      WageCalculator.sumPay(await getAllRecords());

  Future<double> getTotalWorkHours() async =>
      WageCalculator.sumWorkHours(await getAllRecords());

  Future<int> getTotalWorkDays() async =>
      WageCalculator.countWorkDays(await getAllRecords());
}
