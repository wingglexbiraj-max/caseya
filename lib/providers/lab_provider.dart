import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/lab_milk_test.dart';
import '../models/silo_model.dart';
import '../repositories/lab_milk_test_repository.dart';
import '../core/utils/formatters.dart';

final labMilkTestRepositoryProvider = Provider((ref) => LabMilkTestRepository());

class LabState {
  final DateTime selectedDate;
  final TimeOfDay selectedTime;
  final String selectedSiloId;
  final double? fatInput;
  final double? snfInput;
  final String remarks;
  final List<SiloModel> silos;
  final List<LabMilkTest> allTests;
  final List<LabMilkTest> filteredHistory;
  final Map<String, LabMilkTest> todayLatestBySilo;
  final String searchQuery;
  final String? filterSiloId;
  final DateTime? filterDate;
  final LabMilkTest? editingTest;
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;

  const LabState({
    required this.selectedDate,
    required this.selectedTime,
    this.selectedSiloId = 'PMST',
    this.fatInput,
    this.snfInput,
    this.remarks = '',
    this.silos = const [],
    this.allTests = const [],
    this.filteredHistory = const [],
    this.todayLatestBySilo = const {},
    this.searchQuery = '',
    this.filterSiloId,
    this.filterDate,
    this.editingTest,
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
  });

  LabState copyWith({
    DateTime? selectedDate,
    TimeOfDay? selectedTime,
    String? selectedSiloId,
    double? fatInput,
    double? snfInput,
    String? remarks,
    List<SiloModel>? silos,
    List<LabMilkTest>? allTests,
    List<LabMilkTest>? filteredHistory,
    Map<String, LabMilkTest>? todayLatestBySilo,
    String? searchQuery,
    String? filterSiloId,
    DateTime? filterDate,
    LabMilkTest? editingTest,
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
    bool clearEditing = false,
    bool clearFilterSiloId = false,
    bool clearFilterDate = false,
    bool clearMessages = false,
  }) {
    return LabState(
      selectedDate: selectedDate ?? this.selectedDate,
      selectedTime: selectedTime ?? this.selectedTime,
      selectedSiloId: selectedSiloId ?? this.selectedSiloId,
      fatInput: fatInput ?? this.fatInput,
      snfInput: snfInput ?? this.snfInput,
      remarks: remarks ?? this.remarks,
      silos: silos ?? this.silos,
      allTests: allTests ?? this.allTests,
      filteredHistory: filteredHistory ?? this.filteredHistory,
      todayLatestBySilo: todayLatestBySilo ?? this.todayLatestBySilo,
      searchQuery: searchQuery ?? this.searchQuery,
      filterSiloId: clearFilterSiloId ? null : (filterSiloId ?? this.filterSiloId),
      filterDate: clearFilterDate ? null : (filterDate ?? this.filterDate),
      editingTest: clearEditing ? null : (editingTest ?? this.editingTest),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearMessages ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearMessages ? null : (successMessage ?? this.successMessage),
    );
  }
}

class LabNotifier extends StateNotifier<LabState> {
  final LabMilkTestRepository _repo;

  LabNotifier(this._repo)
      : super(LabState(
          selectedDate: DateTime.now(),
          selectedTime: TimeOfDay.now(),
        )) {
    init();
  }

  Future<void> init() async {
    state = state.copyWith(isLoading: true);
    final silos = await _repo.getSilos();
    final tests = await _repo.getTests();
    final todayStr = Formatters.formatDate(DateTime.now());
    final todayMap = await _repo.getLatestReadingsBySilo(todayDateStr: todayStr);

    state = state.copyWith(
      silos: silos,
      allTests: tests,
      filteredHistory: tests,
      todayLatestBySilo: todayMap,
      isLoading: false,
    );
  }

  void setDate(DateTime date) {
    state = state.copyWith(selectedDate: date);
  }

  void setTime(TimeOfDay time) {
    state = state.copyWith(selectedTime: time);
  }

  void setSiloId(String siloId) {
    state = state.copyWith(selectedSiloId: siloId);
  }

  void setFat(double? val) {
    state = state.copyWith(fatInput: val, clearMessages: true);
  }

  void setSnf(double? val) {
    state = state.copyWith(snfInput: val, clearMessages: true);
  }

  void setRemarks(String val) {
    state = state.copyWith(remarks: val);
  }

  void setSearchQuery(String q) {
    state = state.copyWith(searchQuery: q);
    _applyFilters();
  }

  void setFilterSiloId(String? siloId) {
    state = state.copyWith(filterSiloId: siloId, clearFilterSiloId: siloId == null);
    _applyFilters();
  }

  void setFilterDate(DateTime? date) {
    state = state.copyWith(filterDate: date, clearFilterDate: date == null);
    _applyFilters();
  }

  void _applyFilters() {
    var result = List<LabMilkTest>.from(state.allTests);

    if (state.filterSiloId != null && state.filterSiloId!.isNotEmpty) {
      result = result.where((r) => r.siloId == state.filterSiloId).toList();
    }

    if (state.filterDate != null) {
      final dateStr = Formatters.formatDate(state.filterDate!);
      result = result.where((r) => r.testDate == dateStr).toList();
    }

    if (state.searchQuery.isNotEmpty) {
      final q = state.searchQuery.toLowerCase();
      result = result.where((r) {
        return r.testDate.contains(q) ||
            r.siloName.toLowerCase().contains(q) ||
            r.labUserName.toLowerCase().contains(q) ||
            r.remarks.toLowerCase().contains(q);
      }).toList();
    }

    state = state.copyWith(filteredHistory: result);
  }

  void startEditing(LabMilkTest test) {
    final parsedDate = DateTime.tryParse(test.testDate) ?? DateTime.now();
    state = state.copyWith(
      editingTest: test,
      selectedDate: parsedDate,
      selectedSiloId: test.siloId,
      fatInput: test.fatPercentage,
      snfInput: test.snfPercentage,
      remarks: test.remarks,
    );
  }

  void cancelEditing() {
    state = state.copyWith(
      clearEditing: true,
      selectedDate: DateTime.now(),
      selectedTime: TimeOfDay.now(),
      fatInput: null,
      snfInput: null,
      remarks: '',
    );
  }

  Future<bool> saveReading({
    required String userId,
    required String userName,
  }) async {
    final fat = state.fatInput;
    final snf = state.snfInput;

    if (fat == null || fat <= 0) {
      state = state.copyWith(errorMessage: 'Milk Fat (%) must be greater than 0');
      return false;
    }
    if (snf == null || snf <= 0) {
      state = state.copyWith(errorMessage: 'Milk SNF (%) must be greater than 0');
      return false;
    }

    final dateStr = Formatters.formatDate(state.selectedDate);
    final timeStr = _formatTimeOfDay(state.selectedTime);

    // Resolve Silo Name
    final silo = state.silos.firstWhere(
      (s) => s.id == state.selectedSiloId,
      orElse: () => SiloModel(id: state.selectedSiloId, name: state.selectedSiloId, description: ''),
    );

    try {
      if (state.editingTest != null) {
        final updated = state.editingTest!.copyWith(
          testDate: dateStr,
          testTime: timeStr,
          siloId: silo.id,
          siloName: silo.name,
          fatPercentage: fat,
          snfPercentage: snf,
          labUserId: userId,
          labUserName: userName,
          remarks: state.remarks.trim(),
          updatedAt: DateTime.now(),
        );

        await _repo.updateTest(updated);

        final updatedList = state.allTests
            .map((t) => t.id == updated.id ? updated : t)
            .toList();

        final todayStr = Formatters.formatDate(DateTime.now());
        final todayMap = await _repo.getLatestReadingsBySilo(todayDateStr: todayStr);

        state = state.copyWith(
          allTests: updatedList,
          todayLatestBySilo: todayMap,
          clearEditing: true,
          successMessage: 'Lab test for ${silo.name} updated successfully.',
        );
        _applyFilters();
        return true;
      } else {
        final newTest = LabMilkTest(
          id: 'LAB-${DateTime.now().millisecondsSinceEpoch}',
          testDate: dateStr,
          testTime: timeStr,
          siloId: silo.id,
          siloName: silo.name,
          fatPercentage: fat,
          snfPercentage: snf,
          labUserId: userId,
          labUserName: userName,
          remarks: state.remarks.trim(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await _repo.saveTest(newTest);

        final newList = [newTest, ...state.allTests];
        final todayStr = Formatters.formatDate(DateTime.now());
        final todayMap = await _repo.getLatestReadingsBySilo(todayDateStr: todayStr);

        state = state.copyWith(
          allTests: newList,
          todayLatestBySilo: todayMap,
          successMessage: 'Lab test for ${silo.name} recorded. Fat: ${fat.toStringAsFixed(2)}%, SNF: ${snf.toStringAsFixed(2)}%',
        );
        _applyFilters();
        return true;
      }
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to save lab reading: $e');
      return false;
    }
  }

  Future<void> deleteReading(String testId) async {
    try {
      await _repo.deleteTest(testId);
      final newList = state.allTests.where((t) => t.id != testId).toList();
      final todayStr = Formatters.formatDate(DateTime.now());
      final todayMap = await _repo.getLatestReadingsBySilo(todayDateStr: todayStr);

      state = state.copyWith(
        allTests: newList,
        todayLatestBySilo: todayMap,
        successMessage: 'Lab reading deleted.',
      );
      _applyFilters();
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to delete reading: $e');
    }
  }

  String _formatTimeOfDay(TimeOfDay tod) {
    final hour = tod.hourOfPeriod == 0 ? 12 : tod.hourOfPeriod;
    final minute = tod.minute.toString().padLeft(2, '0');
    final period = tod.period == DayPeriod.am ? 'AM' : 'PM';
    return '${hour.toString().padLeft(2, '0')}:$minute $period';
  }
}

final labProvider = StateNotifierProvider<LabNotifier, LabState>((ref) {
  final repo = ref.watch(labMilkTestRepositoryProvider);
  return LabNotifier(repo);
});
