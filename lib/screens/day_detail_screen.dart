import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/shift_type.dart';
import '../models/work_day_record.dart';
import '../services/work_day_storage.dart';
import '../theme/app_theme.dart';
import '../utils/shift_labels.dart';
import '../utils/time_utils.dart';
import '../utils/wage_calculator.dart';
import '../widgets/common_widgets.dart';

class DayDetailScreen extends StatefulWidget {
  const DayDetailScreen({
    super.key,
    required this.storage,
    required this.dateKey,
    required this.onChanged,
  });

  final WorkDayStorage storage;
  final String dateKey;
  final VoidCallback onChanged;

  @override
  State<DayDetailScreen> createState() => _DayDetailScreenState();
}

class _DayDetailScreenState extends State<DayDetailScreen> {
  final _checkInController = TextEditingController();
  final _checkOutController = TextEditingController();
  final _noteController = TextEditingController();

  String selectedShift = ShiftType.auto;
  WorkDayRecord? savedRecord;

  bool get isHolidayOff => selectedShift == ShiftType.holiday;

  @override
  void initState() {
    super.initState();
    _checkInController.addListener(_updatePreview);
    _checkOutController.addListener(_updatePreview);
    _loadExistingRecord();
  }

  @override
  void dispose() {
    _checkInController.dispose();
    _checkOutController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingRecord() async {
    final record = await widget.storage.getRecordForDate(widget.dateKey);
    if (record == null) {
      setState(() {});
      return;
    }
    _checkInController.text = record.checkIn;
    _checkOutController.text = record.checkOut;
    _noteController.text = record.note;
    selectedShift = record.shiftType;
    savedRecord = record;
    setState(() {});
  }

  Future<void> _pickTime(TextEditingController controller) async {
    final parts = TimeUtils.parseTimeOrNow(
      controller.text.isEmpty ? null : controller.text,
    );
    final picked = await pickTime(
      context,
      initial: TimeOfDay(hour: parts[0], minute: parts[1]),
    );
    if (picked != null) {
      controller.text = TimeUtils.formatTime(picked.hour, picked.minute);
    }
  }

  WorkDayRecord _previewRecord() => WorkDayRecord(
        date: widget.dateKey,
        checkIn: _checkInController.text.trim(),
        checkOut: _checkOutController.text.trim(),
        note: _noteController.text.trim(),
        shiftType: selectedShift,
      );

  void _updatePreview() => setState(() {});

  Future<void> _saveRecord() async {
    final checkIn = _checkInController.text.trim();
    final checkOut = _checkOutController.text.trim();
    final note = _noteController.text.trim();

    if (isHolidayOff) {
      await widget.storage.saveRecord(
        WorkDayRecord(
          date: widget.dateKey,
          note: note,
          shiftType: selectedShift,
        ),
      );
      _showToast(AppStrings.toastSaveSuccess);
      await _loadExistingRecord();
      widget.onChanged();
      return;
    }

    if (checkOut.isNotEmpty && checkIn.isEmpty) {
      _showToast(AppStrings.toastCheckInFirst);
      return;
    }

    if (checkIn.isNotEmpty &&
        checkOut.isNotEmpty &&
        !TimeUtils.isCheckOutAfterCheckIn(checkIn, checkOut)) {
      _showToast(AppStrings.toastInvalidTime);
      return;
    }

    await widget.storage.saveRecord(
      WorkDayRecord(
        date: widget.dateKey,
        checkIn: checkIn,
        checkOut: checkOut,
        note: note,
        shiftType: selectedShift,
      ),
    );
    _showToast(AppStrings.toastSaveSuccess);
    await _loadExistingRecord();
    widget.onChanged();
  }

  Future<void> _clearForm() async {
    _checkInController.clear();
    _checkOutController.clear();
    _noteController.clear();
    selectedShift = ShiftType.auto;
    await widget.storage.deleteRecord(widget.dateKey);
    savedRecord = null;
    _showToast(AppStrings.toastClearSuccess);
    widget.onChanged();
    setState(() {});
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  String? _previewDuration() {
    if (isHolidayOff) return null;
    final checkIn = _checkInController.text.trim();
    final checkOut = _checkOutController.text.trim();
    if (checkIn.isEmpty || checkOut.isEmpty) return null;
    final duration = TimeUtils.calculateDuration(checkIn, checkOut);
    if (duration.isEmpty) return null;
    return TimeUtils.formatDurationLabel(duration);
  }

  String? _previewWage() {
    if (isHolidayOff) return AppStrings.shiftHoliday;
    final record = _previewRecord();
    if (!record.hasCompleteWorkTime) return null;
    return WageCalculator.formatPayBreakdown(record);
  }

  String _savedPreviewText() {
    final record = savedRecord;
    if (record == null || !record.hasContent) return '';

    if (record.isHolidayOff) {
      return WageCalculator.formatPayBreakdown(record);
    }

    final preview = StringBuffer();
    if (record.hasCheckIn) {
      preview.writeln('${AppStrings.labelCheckIn} ${record.checkIn}');
    }
    if (record.hasCheckOut) {
      preview.writeln('${AppStrings.labelCheckOut} ${record.checkOut}');
    }
    if (record.isCountableWorkDay) {
      preview.write(WageCalculator.formatPayBreakdown(record));
    } else if (record.hasNote) {
      preview.write('${AppStrings.labelNote}: ${record.note}');
    }
    return preview.toString().trim();
  }

  @override
  Widget build(BuildContext context) {
    final previewDuration = _previewDuration();
    final previewWage = _previewWage();
    final savedPreview = _savedPreviewText();

    return Scaffold(
      appBar: AppBar(
        title: Text(TimeUtils.formatDisplayDate(widget.dateKey)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppCard(
            margin: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  AppStrings.labelDayDetail,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  TimeUtils.formatDisplayDate(widget.dateKey),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (!isHolidayOff) ...[
                  const SizedBox(height: 20),
                  TextField(
                    controller: _checkInController,
                    readOnly: true,
                    onTap: () => _pickTime(_checkInController),
                    decoration: InputDecoration(
                      labelText: AppStrings.labelCheckIn,
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.access_time),
                        onPressed: () => _pickTime(_checkInController),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _checkOutController,
                    readOnly: true,
                    onTap: () => _pickTime(_checkOutController),
                    decoration: InputDecoration(
                      labelText: AppStrings.labelCheckOut,
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.access_time),
                        onPressed: () => _pickTime(_checkOutController),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                DropdownMenu<String>(
                  initialSelection: selectedShift,
                  label: const Text(AppStrings.labelShift),
                  expandedInsets: EdgeInsets.zero,
                  dropdownMenuEntries: ShiftType.allValues
                      .map(
                        (value) => DropdownMenuEntry(
                          value: value,
                          label: ShiftLabels.getLabel(value),
                        ),
                      )
                      .toList(),
                  onSelected: (value) {
                    if (value == null) return;
                    setState(() => selectedShift = value);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _noteController,
                  minLines: 4,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    labelText: AppStrings.labelNote,
                    alignLabelWithHint: true,
                  ),
                ),
                if (previewDuration != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    previewDuration,
                    style: const TextStyle(color: AppColors.primary, fontSize: 15),
                  ),
                ],
                if (previewWage != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    previewWage,
                    style: const TextStyle(
                      color: AppColors.money,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      height: 1.4,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _clearForm,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(AppStrings.btnClear),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: FilledButton(
                        onPressed: _saveRecord,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(AppStrings.btnSave),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (savedPreview.isNotEmpty)
            AppCard(
              margin: const EdgeInsets.only(top: 16),
              color: AppColors.primaryLight,
              elevation: 0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    AppStrings.labelSavedData,
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    savedPreview,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
