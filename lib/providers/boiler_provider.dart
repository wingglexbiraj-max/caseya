import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/boiler_record.dart';
import '../services/boiler_calculator.dart';
import '../services/local_storage_service.dart';
import '../repositories/boiler_repository.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/formatters.dart';

final boilerRepositoryProvider = Provider((ref) => BoilerRepository());

class BoilerState {
  final DateTime selectedDate;
  final String selectedShift;
  final double openingCm;
  final double closingCm;
  final double runningHours;
  final double fuelTopUp;
  final String remarks;
  final bool includeTopUpInNet;
  final BoilerCalculationResult? liveResult;
  final List<BoilerRecord> allRecords;
  final List<BoilerRecord> filteredRecords;
  final String searchQuery;
  final String? filterShift;
  final DateTime? filterDate;
  final BoilerRecord? editingRecord;
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;

  const BoilerState({
    required this.selectedDate,
    this.selectedShift = 'Shift A (06:00 - 14:00)',
    this.openingCm = 500.0,
    this.closingCm = 430.0,
    this.runningHours = 8.5,
    this.fuelTopUp = 0.0,
    this.remarks = '',
    this.includeTopUpInNet = true,
    this.liveResult,
    this.allRecords = const [],
    this.filteredRecords = const [],
    this.searchQuery = '',
    this.filterShift,
    this.filterDate,
    this.editingRecord,
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
  });

  BoilerState copyWith({
    DateTime? selectedDate,
    String? selectedShift,
    double? openingCm,
    double? closingCm,
    double? runningHours,
    double? fuelTopUp,
    String? remarks,
    bool? includeTopUpInNet,
    BoilerCalculationResult? liveResult,
    List<BoilerRecord>? allRecords,
    List<BoilerRecord>? filteredRecords,
    String? searchQuery,
    String? filterShift,
    DateTime? filterDate,
    BoilerRecord? editingRecord,
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
    bool clearEditing = false,
    bool clearFilterShift = false,
    bool clearFilterDate = false,
    bool clearMessages = false,
  }) {
    return BoilerState(
      selectedDate: selectedDate ?? this.selectedDate,
      selectedShift: selectedShift ?? this.selectedShift,
      openingCm: openingCm ?? this.openingCm,
      closingCm: closingCm ?? this.closingCm,
      runningHours: runningHours ?? this.runningHours,
      fuelTopUp: fuelTopUp ?? this.fuelTopUp,
      remarks: remarks ?? this.remarks,
      includeTopUpInNet: includeTopUpInNet ?? this.includeTopUpInNet,
      liveResult: liveResult ?? this.liveResult,
      allRecords: allRecords ?? this.allRecords,
      filteredRecords: filteredRecords ?? this.filteredRecords,
      searchQuery: searchQuery ?? this.searchQuery,
      filterShift: clearFilterShift ? null : (filterShift ?? this.filterShift),
      filterDate: clearFilterDate ? null : (filterDate ?? this.filterDate),
      editingRecord: clearEditing ? null : (editingRecord ?? this.editingRecord),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearMessages ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearMessages ? null : (successMessage ?? this.successMessage),
    );
  }
}

class BoilerNotifier extends StateNotifier<BoilerState> {
  final BoilerRepository _repo;

  BoilerNotifier(this._repo)
      : super(BoilerState(selectedDate: DateTime.now())) {
    init();
  }

  Future<void> init() async {
    state = state.copyWith(isLoading: true);
    final topUpIncluded = await LocalStorageService.getBoilerTopUpIncluded();
    final records = await _repo.getRecords();

    final initialResult = BoilerCalculator.calculate(
      openingCm: state.openingCm,
      closingCm: state.closingCm,
      runningHours: state.runningHours,
      fuelTopUp: state.fuelTopUp,
      includeTopUpInNet: topUpIncluded,
    );

    state = state.copyWith(
      includeTopUpInNet: topUpIncluded,
      allRecords: records,
      filteredRecords: records,
      liveResult: initialResult,
      isLoading: false,
    );
  }

  void _recalculate() {
    final result = BoilerCalculator.calculate(
      openingCm: state.openingCm,
      closingCm: state.closingCm,
      runningHours: state.runningHours,
      fuelTopUp: state.fuelTopUp,
      includeTopUpInNet: state.includeTopUpInNet,
    );
    state = state.copyWith(liveResult: result, clearMessages: true);
  }

  void setDate(DateTime date) {
    state = state.copyWith(selectedDate: date);
  }

  void setShift(String shift) {
    state = state.copyWith(selectedShift: shift);
  }

  void setOpeningCm(double cm) {
    state = state.copyWith(openingCm: cm);
    _recalculate();
  }

  void setClosingCm(double cm) {
    state = state.copyWith(closingCm: cm);
    _recalculate();
  }

  void setRunningHours(double hours) {
    state = state.copyWith(runningHours: hours);
    _recalculate();
  }

  void setFuelTopUp(double topUp) {
    state = state.copyWith(fuelTopUp: topUp);
    _recalculate();
  }

  void setRemarks(String remarks) {
    state = state.copyWith(remarks: remarks);
  }

  void toggleTopUpInclusion(bool included) {
    state = state.copyWith(includeTopUpInNet: included);
    LocalStorageService.setBoilerTopUpIncluded(included);
    _recalculate();
  }

  Future<bool> saveOrUpdateRecord({
    required String employeeId,
    required String employeeName,
  }) async {
    if (state.liveResult == null) return false;

    // Validation
    if (state.closingCm > state.openingCm && state.fuelTopUp <= 0) {
      state = state.copyWith(
        errorMessage: 'Closing CM cannot exceed Opening CM unless fuel was added (enter Fuel Top-up).',
      );
      return false;
    }
    if (state.runningHours < 0) {
      state = state.copyWith(errorMessage: 'Running hours cannot be negative.');
      return false;
    }

    final now = DateTime.now();
    final isEditing = state.editingRecord != null;

    final record = BoilerRecord(
      recordId: isEditing
          ? state.editingRecord!.recordId
          : 'BLR-${const Uuid().v4().substring(0, 8).toUpperCase()}',
      date: Formatters.formatIsoDate(state.selectedDate),
      time: Formatters.formatTime(now),
      shift: state.selectedShift,
      employeeId: employeeId,
      employeeName: employeeName,
      openingCm: state.openingCm,
      closingCm: state.closingCm,
      levelDifferenceCm: state.liveResult!.levelDifferenceCm,
      calculatedLevelConsumption: state.liveResult!.calculatedLevelConsumption,
      fuelTopUp: state.fuelTopUp,
      netReportedConsumption: state.liveResult!.netReportedConsumption,
      runningHours: state.runningHours,
      consumptionPerHour: state.liveResult!.consumptionPerHour,
      remarks: state.remarks,
      createdAt: isEditing ? state.editingRecord!.createdAt : now,
      updatedAt: now,
    );

    if (isEditing) {
      await _repo.updateRecord(record);
    } else {
      await _repo.saveRecord(record);
    }

    final records = await _repo.getRecords();
    state = state.copyWith(
      allRecords: records,
      clearEditing: true,
      successMessage: isEditing
          ? '✓ Boiler record updated successfully.'
          : '✓ New boiler consumption entry recorded.',
    );
    _applyFilters();
    return true;
  }

  void startEditing(BoilerRecord record) {
    state = state.copyWith(
      editingRecord: record,
      selectedDate: DateTime.tryParse(record.date) ?? DateTime.now(),
      selectedShift: record.shift,
      openingCm: record.openingCm,
      closingCm: record.closingCm,
      runningHours: record.runningHours,
      fuelTopUp: record.fuelTopUp,
      remarks: record.remarks,
      clearMessages: true,
    );
    _recalculate();
  }

  void cancelEditing() {
    state = state.copyWith(clearEditing: true);
  }

  Future<void> deleteRecord(String recordId) async {
    await _repo.deleteRecord(recordId);
    final records = await _repo.getRecords();
    state = state.copyWith(
      allRecords: records,
      successMessage: 'Boiler record deleted.',
    );
    _applyFilters();
  }

  void setSearchQuery(String q) {
    state = state.copyWith(searchQuery: q);
    _applyFilters();
  }

  void setFilterShift(String? shift) {
    state = state.copyWith(filterShift: shift);
    _applyFilters();
  }

  void setFilterDate(DateTime? date) {
    state = state.copyWith(filterDate: date);
    _applyFilters();
  }

  void clearFilters() {
    state = state.copyWith(
      searchQuery: '',
      clearFilterShift: true,
      clearFilterDate: true,
    );
    _applyFilters();
  }

  void _applyFilters() {
    var list = List<BoilerRecord>.from(state.allRecords);

    if (state.searchQuery.trim().isNotEmpty) {
      final q = state.searchQuery.toLowerCase().trim();
      list = list.where((r) {
        return r.date.contains(q) ||
            r.shift.toLowerCase().contains(q) ||
            r.employeeName.toLowerCase().contains(q) ||
            r.remarks.toLowerCase().contains(q);
      }).toList();
    }

    if (state.filterShift != null && state.filterShift!.isNotEmpty) {
      list = list.where((r) => r.shift == state.filterShift).toList();
    }

    if (state.filterDate != null) {
      final iso = Formatters.formatIsoDate(state.filterDate!);
      list = list.where((r) => r.date == iso).toList();
    }

    state = state.copyWith(filteredRecords: list);
  }
}

final boilerProvider = StateNotifierProvider<BoilerNotifier, BoilerState>((ref) {
  final repo = ref.watch(boilerRepositoryProvider);
  return BoilerNotifier(repo);
});
