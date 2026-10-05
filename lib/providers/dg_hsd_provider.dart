import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/dg_hsd_record.dart';
import '../services/dg_hsd_calculator.dart';
import '../repositories/dg_hsd_repository.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/formatters.dart';

final dgHsdRepositoryProvider = Provider((ref) => DgHsdRepository());

class DgHsdState {
  final DateTime selectedDate;
  final TimeOfDay? selectedTime;
  final bool isLiveTime;
  final String selectedShift;
  final double fuelAdded;
  final double startPercentage;
  final double endPercentage;
  final double fuelConsumption;
  final double kwh;
  final double runningHours;
  final String remarks;
  final DgHsdCalculationResult? liveResult;
  final List<DgHsdRecord> allRecords;
  final List<DgHsdRecord> filteredRecords;
  final String searchQuery;
  final String? filterShift;
  final DgHsdRecord? editingRecord;
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;

  const DgHsdState({
    required this.selectedDate,
    this.selectedTime,
    this.isLiveTime = true,
    this.selectedShift = 'Shift A (06:00 - 14:00)',
    this.fuelAdded = 0.0,
    this.startPercentage = 0.0,
    this.endPercentage = 0.0,
    this.fuelConsumption = 0.0,
    this.kwh = 0.0,
    this.runningHours = 0.0,
    this.remarks = '',
    this.liveResult,
    this.allRecords = const [],
    this.filteredRecords = const [],
    this.searchQuery = '',
    this.filterShift,
    this.editingRecord,
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
  });

  DgHsdState copyWith({
    DateTime? selectedDate,
    TimeOfDay? selectedTime,
    bool? isLiveTime,
    String? selectedShift,
    double? fuelAdded,
    double? startPercentage,
    double? endPercentage,
    double? fuelConsumption,
    double? kwh,
    double? runningHours,
    String? remarks,
    DgHsdCalculationResult? liveResult,
    List<DgHsdRecord>? allRecords,
    List<DgHsdRecord>? filteredRecords,
    String? searchQuery,
    String? filterShift,
    DgHsdRecord? editingRecord,
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
    bool clearEditing = false,
    bool clearFilterShift = false,
    bool clearSelectedTime = false,
    bool clearMessages = false,
  }) {
    return DgHsdState(
      selectedDate: selectedDate ?? this.selectedDate,
      selectedTime: clearSelectedTime ? null : (selectedTime ?? this.selectedTime),
      isLiveTime: isLiveTime ?? this.isLiveTime,
      selectedShift: selectedShift ?? this.selectedShift,
      fuelAdded: fuelAdded ?? this.fuelAdded,
      startPercentage: startPercentage ?? this.startPercentage,
      endPercentage: endPercentage ?? this.endPercentage,
      fuelConsumption: fuelConsumption ?? this.fuelConsumption,
      kwh: kwh ?? this.kwh,
      runningHours: runningHours ?? this.runningHours,
      remarks: remarks ?? this.remarks,
      liveResult: liveResult ?? this.liveResult,
      allRecords: allRecords ?? this.allRecords,
      filteredRecords: filteredRecords ?? this.filteredRecords,
      searchQuery: searchQuery ?? this.searchQuery,
      filterShift: clearFilterShift ? null : (filterShift ?? this.filterShift),
      editingRecord: clearEditing ? null : (editingRecord ?? this.editingRecord),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearMessages ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearMessages ? null : (successMessage ?? this.successMessage),
    );
  }
}

class DgHsdNotifier extends StateNotifier<DgHsdState> {
  final DgHsdRepository _repo;

  DgHsdNotifier(this._repo)
      : super(DgHsdState(
          selectedDate: DateTime.now(),
          selectedShift: AppConstants.determineShift(DateTime.now()),
        )) {
    init();
  }

  Future<void> init() async {
    state = state.copyWith(isLoading: true);
    final records = await _repo.getRecords();

    final initialResult = DgHsdCalculator.calculate(
      fuelAdded: state.fuelAdded,
      startPercentage: state.startPercentage,
      endPercentage: state.endPercentage,
      fuelConsumption: state.fuelConsumption,
      kwh: state.kwh,
      runningHours: state.runningHours,
    );

    state = state.copyWith(
      allRecords: records,
      filteredRecords: records,
      liveResult: initialResult,
      isLoading: false,
    );
  }

  void _recalculate() {
    final result = DgHsdCalculator.calculate(
      fuelAdded: state.fuelAdded,
      startPercentage: state.startPercentage,
      endPercentage: state.endPercentage,
      fuelConsumption: state.fuelConsumption > 0 ? state.fuelConsumption : null,
      kwh: state.kwh,
      runningHours: state.runningHours,
    );
    state = state.copyWith(
      liveResult: result,
      errorMessage: result.validationError,
      clearMessages: result.validationError == null,
    );
  }

  void setDate(DateTime date) {
    state = state.copyWith(selectedDate: date);
  }

  void setTime(TimeOfDay time) {
    state = state.copyWith(selectedTime: time, isLiveTime: false);
  }

  void resetToLiveTime() {
    state = state.copyWith(isLiveTime: true, clearSelectedTime: true);
  }

  void setShift(String shift) {
    state = state.copyWith(selectedShift: shift);
  }

  void setFuelAdded(double val) {
    state = state.copyWith(fuelAdded: val);
    _recalculate();
  }

  void setStartPercentage(double val) {
    state = state.copyWith(startPercentage: val);
    _recalculate();
  }

  void setEndPercentage(double val) {
    state = state.copyWith(endPercentage: val);
    _recalculate();
  }

  void setFuelConsumption(double val) {
    state = state.copyWith(fuelConsumption: val);
    _recalculate();
  }

  void setKwh(double val) {
    state = state.copyWith(kwh: val);
    _recalculate();
  }

  void setRunningHours(double val) {
    state = state.copyWith(runningHours: val);
    _recalculate();
  }

  void setRemarks(String val) {
    state = state.copyWith(remarks: val);
  }

  void setSearchQuery(String q) {
    state = state.copyWith(searchQuery: q);
    _applyFilters();
  }

  void setFilterShift(String? shift) {
    state = state.copyWith(filterShift: shift, clearFilterShift: shift == null);
    _applyFilters();
  }

  void _applyFilters() {
    var result = List<DgHsdRecord>.from(state.allRecords);

    if (state.filterShift != null && state.filterShift!.isNotEmpty) {
      result = result.where((r) => r.shift.contains(state.filterShift!)).toList();
    }

    if (state.searchQuery.isNotEmpty) {
      final q = state.searchQuery.toLowerCase();
      result = result.where((r) {
        return r.date.contains(q) ||
            r.shift.toLowerCase().contains(q) ||
            r.employeeName.toLowerCase().contains(q) ||
            r.remarks.toLowerCase().contains(q);
      }).toList();
    }

    state = state.copyWith(filteredRecords: result);
  }

  void startEditing(DgHsdRecord record) {
    final parsedDate = DateTime.tryParse(record.date) ?? DateTime.now();
    state = state.copyWith(
      editingRecord: record,
      selectedDate: parsedDate,
      selectedShift: record.shift,
      fuelAdded: record.fuelAdded,
      startPercentage: record.startPercentage,
      endPercentage: record.endPercentage,
      fuelConsumption: record.fuelConsumption,
      kwh: record.kwh,
      runningHours: record.runningHours,
      remarks: record.remarks,
    );
    _recalculate();
  }

  void cancelEditing() {
    state = state.copyWith(
      clearEditing: true,
      fuelAdded: 0.0,
      startPercentage: 0.0,
      endPercentage: 0.0,
      fuelConsumption: 0.0,
      kwh: 0.0,
      runningHours: 0.0,
      remarks: '',
    );
    _recalculate();
  }

  Future<bool> saveOrUpdateRecord({
    required String employeeId,
    required String employeeName,
  }) async {
    final result = state.liveResult;
    if (result == null) return false;

    if (state.fuelAdded < 0) {
      state = state.copyWith(errorMessage: 'Top-up litres cannot be negative.');
      return false;
    }

    if (state.startPercentage < 0 || state.startPercentage > 100) {
      state = state.copyWith(errorMessage: 'Opening fuel level must be between 0% and 100%.');
      return false;
    }

    if (state.endPercentage < 0 || state.endPercentage > 100) {
      state = state.copyWith(errorMessage: 'Closing fuel level must be between 0% and 100%.');
      return false;
    }

    if (result.exceedsCapacity) {
      state = state.copyWith(
        errorMessage: 'Fuel level after top-up (${Formatters.formatSmart(result.fuelAfterTopUp)} L / ${Formatters.formatDecimal(result.percentageAfterTopUp)}%) exceeds DG tank capacity of ${Formatters.formatSmart(result.tankCapacity)} L.',
      );
      return false;
    }

    if (result.consumedLitres < 0) {
      state = state.copyWith(errorMessage: 'Closing fuel level cannot exceed fuel level after top-up.');
      return false;
    }

    if (state.runningHours <= 0) {
      state = state.copyWith(errorMessage: 'Running hours must be greater than 0.');
      return false;
    }

    final double effectiveFuelConsumption = state.fuelConsumption > 0
        ? state.fuelConsumption
        : (result.consumedLitres > 0 ? result.consumedLitres : 0.0);

    final dateStr = Formatters.formatDate(state.selectedDate);
    final now = DateTime.now();
    final String timeStr;
    if (state.editingRecord != null) {
      timeStr = state.editingRecord!.time;
    } else if (state.isLiveTime) {
      timeStr = DateFormat('hh:mm a').format(DateTime.now());
    } else {
      final hour = state.selectedTime!.hour;
      final minute = state.selectedTime!.minute;
      final dt = DateTime(now.year, now.month, now.day, hour, minute);
      timeStr = DateFormat('hh:mm a').format(dt);
    }
    final effectiveShift = state.isLiveTime
        ? AppConstants.determineShift(DateTime.now())
        : (state.selectedTime != null
            ? AppConstants.determineShift(DateTime(now.year, now.month, now.day, state.selectedTime!.hour, state.selectedTime!.minute))
            : state.selectedShift);

    try {
      if (state.editingRecord != null) {
        final updated = state.editingRecord!.copyWith(
          date: dateStr,
          time: timeStr,
          shift: effectiveShift,
          employeeId: employeeId,
          employeeName: employeeName,
          fuelAdded: state.fuelAdded,
          startPercentage: state.startPercentage,
          endPercentage: state.endPercentage,
          percentageDrop: result.percentageDrop,
          fuelConsumption: effectiveFuelConsumption,
          kwh: state.kwh,
          runningHours: state.runningHours,
          consumptionPerHour: result.consumptionPerHour,
          unitsPerLitre: result.unitsPerLitre,
          remarks: state.remarks.trim(),
          updatedAt: DateTime.now(),
        );

        await _repo.updateRecord(updated);

        final updatedList = state.allRecords
            .map((r) => r.recordId == updated.recordId ? updated : r)
            .toList();

        state = state.copyWith(
          allRecords: updatedList,
          clearEditing: true,
          successMessage: 'DG HSD record updated successfully.',
        );
        _applyFilters();
        return true;
      } else {
        final newRecord = DgHsdRecord(
          recordId: 'DG-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
          date: dateStr,
          time: timeStr,
          shift: effectiveShift,
          employeeId: employeeId,
          employeeName: employeeName,
          fuelAdded: state.fuelAdded,
          startPercentage: state.startPercentage,
          endPercentage: state.endPercentage,
          percentageDrop: result.percentageDrop,
          fuelConsumption: effectiveFuelConsumption,
          kwh: state.kwh,
          runningHours: state.runningHours,
          consumptionPerHour: result.consumptionPerHour,
          unitsPerLitre: result.unitsPerLitre,
          remarks: state.remarks.trim(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await _repo.saveRecord(newRecord);

        final newList = [newRecord, ...state.allRecords];
        state = state.copyWith(
          allRecords: newList,
          successMessage: 'DG HSD fuel entry recorded successfully.',
        );
        _applyFilters();
        return true;
      }
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to save DG HSD entry: $e');
      return false;
    }
  }

  Future<void> deleteRecord(String recordId) async {
    try {
      await _repo.deleteRecord(recordId);
      final newList = state.allRecords.where((r) => r.recordId != recordId).toList();
      state = state.copyWith(
        allRecords: newList,
        successMessage: 'DG entry deleted.',
      );
      _applyFilters();
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to delete record: $e');
    }
  }
}

final dgHsdProvider = StateNotifierProvider<DgHsdNotifier, DgHsdState>((ref) {
  final repo = ref.watch(dgHsdRepositoryProvider);
  return DgHsdNotifier(repo);
});
