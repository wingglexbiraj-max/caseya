import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/utils/formatters.dart';
import 'boiler_provider.dart';
import 'standardization_provider.dart';
import 'product_calculator_provider.dart';
import 'dispatch_provider.dart';

class PlantActivity {
  final String time;
  final String title;
  final String subtitle;
  final String module;

  const PlantActivity({
    required this.time,
    required this.title,
    required this.subtitle,
    required this.module,
  });
}

class DashboardState {
  final double todayProductionLitres;
  final double todayDispatchLitres;
  final double currentStockLitres;
  final double todayBoilerConsumptionLitres;
  final int todayStandardizationBatches;
  final List<PlantActivity> recentActivities;

  const DashboardState({
    this.todayProductionLitres = 18450.0,
    this.todayDispatchLitres = 16200.0,
    this.currentStockLitres = 42800.0,
    this.todayBoilerConsumptionLitres = 900.0,
    this.todayStandardizationBatches = 2,
    this.recentActivities = const [],
  });
}

final dashboardProvider = Provider<DashboardState>((ref) {
  final boilerState = ref.watch(boilerProvider);
  final stdState = ref.watch(standardizationProvider);
  final calcState = ref.watch(productCalculatorProvider);
  final dispatchState = ref.watch(dispatchProvider);

  // Compute today's boiler consumption from records
  final todayIso = Formatters.formatIsoDate(DateTime.now());
  double todayBoiler = 0.0;
  for (final record in boilerState.allRecords) {
    if (record.date == todayIso) {
      todayBoiler += record.netReportedConsumption;
    }
  }
  if (todayBoiler == 0.0 && boilerState.allRecords.isNotEmpty) {
    todayBoiler = boilerState.allRecords.first.netReportedConsumption;
  }

  // Count standardization today
  int stdCount = 0;
  for (final s in stdState.history) {
    if (s.date == todayIso) stdCount++;
  }
  if (stdCount == 0 && stdState.history.isNotEmpty) {
    stdCount = stdState.history.length;
  }

  // Compute today's dispatch litres from real dispatches
  double realDispatchLitres = 0.0;
  final todayDispatches = dispatchState.dispatches.where((d) => d.dispatchDate == todayIso).toList();
  for (final d in todayDispatches) {
    realDispatchLitres += d.totalLitres;
  }
  if (realDispatchLitres == 0.0 && dispatchState.dispatches.isNotEmpty) {
    realDispatchLitres = dispatchState.dispatches.fold(0.0, (acc, d) => acc + d.totalLitres);
  }

  // Construct real recent activities
  final List<PlantActivity> activities = [];

  for (final d in dispatchState.dispatches.take(2)) {
    activities.add(PlantActivity(
      time: d.dispatchTime.isNotEmpty ? d.dispatchTime : 'Gate Out',
      title: 'Vehicle ${d.vehicleNumber} dispatched (${d.distributorName})',
      subtitle: '${d.summaryLabel} • ${d.route.isNotEmpty ? d.route : "Plant Route"}',
      module: 'Dispatch',
    ));
  }

  for (final b in boilerState.allRecords.take(2)) {
    activities.add(PlantActivity(
      time: b.time.isNotEmpty ? b.time : 'Shift Entry',
      title: 'Boiler reading recorded (${Formatters.formatSmart(b.netReportedConsumption)} L)',
      subtitle: '${b.shift} • ${b.employeeName}',
      module: 'Boiler',
    ));
  }

  for (final s in stdState.history.take(2)) {
    activities.add(PlantActivity(
      time: s.time.isNotEmpty ? s.time : 'Morning Batch',
      title: 'Milk standardization calculated for ${s.targetProductName}',
      subtitle: '${Formatters.formatSmart(s.inputMilkQuantity)} L Milk • ${s.employeeName}',
      module: 'Standardization',
    ));
  }

  for (final p in calcState.history.take(2)) {
    activities.add(PlantActivity(
      time: p.time.isNotEmpty ? p.time : 'Shift Ops',
      title: 'Product calculation for ${p.productName}',
      subtitle: '${Formatters.formatInt(p.pieces)} pcs (${Formatters.formatSmart(p.crates)} crates) • ${p.employeeName}',
      module: 'ProductCalculator',
    ));
  }

  // Fallback defaults if empty
  if (activities.isEmpty) {
    activities.addAll([
      const PlantActivity(
        time: '10:32 AM',
        title: 'Production entry added (Purabi Plus 500ml)',
        subtitle: 'Batch #BT-0927 • 4,200 Litres',
        module: 'Production',
      ),
      const PlantActivity(
        time: '09:45 AM',
        title: 'Boiler reading added',
        subtitle: 'Shift A • 900 Litres consumed',
        module: 'Boiler',
      ),
      const PlantActivity(
        time: '09:20 AM',
        title: 'Milk standardization calculated',
        subtitle: 'Lassi 200ml Batch • 5,000 Litres Raw Milk',
        module: 'Standardization',
      ),
      const PlantActivity(
        time: '08:50 AM',
        title: 'Dispatch vehicle departed (Route 4)',
        subtitle: 'Vehicle AS-01-EC-4021 • 150 Crates',
        module: 'Dispatch',
      ),
    ]);
  }

  return DashboardState(
    todayProductionLitres: 18450.0,
    todayDispatchLitres: realDispatchLitres > 0 ? realDispatchLitres : 16200.0,
    currentStockLitres: 42800.0,
    todayBoilerConsumptionLitres: todayBoiler > 0 ? todayBoiler : 900.0,
    todayStandardizationBatches: stdCount > 0 ? stdCount : 1,
    recentActivities: activities,
  );
});
