import '../core/widgets/calculation_breakdown.dart';

class DgHsdCalculationResult {
  final double fuelAdded;
  final double startPercentage;
  final double endPercentage;
  final double percentageDrop;
  final double fuelConsumption;
  final double kwh;
  final double runningHours;
  final double consumptionPerHour;
  final double unitsPerLitre;
  final double averageLoadKw;
  final List<BreakdownStep> breakdownSteps;

  const DgHsdCalculationResult({
    required this.fuelAdded,
    required this.startPercentage,
    required this.endPercentage,
    required this.percentageDrop,
    required this.fuelConsumption,
    required this.kwh,
    required this.runningHours,
    required this.consumptionPerHour,
    required this.unitsPerLitre,
    required this.averageLoadKw,
    required this.breakdownSteps,
  });
}

class DgHsdCalculator {
  static DgHsdCalculationResult calculate({
    required double fuelAdded,
    required double startPercentage,
    required double endPercentage,
    required double fuelConsumption,
    required double kwh,
    required double runningHours,
  }) {
    final double percentageDrop = startPercentage - endPercentage;
    final double consumptionPerHour =
        runningHours > 0 ? (fuelConsumption / runningHours) : 0.0;
    final double unitsPerLitre =
        fuelConsumption > 0 ? (kwh / fuelConsumption) : 0.0;
    final double averageLoadKw =
        runningHours > 0 ? (kwh / runningHours) : 0.0;

    final steps = <BreakdownStep>[
      BreakdownStep(
        stepTitle: 'Step 1: Fuel Tank Percentage Change',
        formula: 'Start Level (%) - End Level (%)',
        calculation:
            '${startPercentage.toStringAsFixed(1)}% - ${endPercentage.toStringAsFixed(1)}% = ${percentageDrop.toStringAsFixed(1)}% drop',
        note: fuelAdded > 0
            ? 'Includes ${fuelAdded.toStringAsFixed(1)} L added during shift'
            : 'No fuel added during this shift',
      ),
      BreakdownStep(
        stepTitle: 'Step 2: Reported Fuel Consumption',
        formula: 'Operator Logged Fuel Consumption',
        calculation: '${fuelConsumption.toStringAsFixed(1)} Litres HSD consumed',
        note: 'Manually logged meter/tank consumption for shift duration',
      ),
      BreakdownStep(
        stepTitle: 'Step 3: Energy Generation Efficiency (Specific Yield)',
        formula: 'Energy Generated (kWh) ÷ Fuel Consumed (L)',
        calculation:
            '${kwh.toStringAsFixed(1)} kWh ÷ ${fuelConsumption.toStringAsFixed(1)} L = ${unitsPerLitre.toStringAsFixed(2)} kWh / Litre',
        note: 'Standard dairy plant DG benchmark: 3.0 to 3.8 units / Litre',
      ),
      BreakdownStep(
        stepTitle: 'Step 4: Fuel Consumption Rate',
        formula: 'Fuel Consumed (L) ÷ Running Hours (hr)',
        calculation:
            '${fuelConsumption.toStringAsFixed(1)} L ÷ ${runningHours.toStringAsFixed(1)} hrs = ${consumptionPerHour.toStringAsFixed(2)} L / hour',
        note: 'Average hourly DG diesel consumption burn rate',
      ),
      if (runningHours > 0)
        BreakdownStep(
          stepTitle: 'Step 5: Average Plant Load on DG',
          formula: 'Energy Generated (kWh) ÷ Running Hours (hr)',
          calculation:
              '${kwh.toStringAsFixed(1)} kWh ÷ ${runningHours.toStringAsFixed(1)} hrs = ${averageLoadKw.toStringAsFixed(2)} kW',
          note: 'Average active electrical demand sustained during generator run',
        ),
    ];

    return DgHsdCalculationResult(
      fuelAdded: fuelAdded,
      startPercentage: startPercentage,
      endPercentage: endPercentage,
      percentageDrop: percentageDrop,
      fuelConsumption: fuelConsumption,
      kwh: kwh,
      runningHours: runningHours,
      consumptionPerHour: consumptionPerHour,
      unitsPerLitre: unitsPerLitre,
      averageLoadKw: averageLoadKw,
      breakdownSteps: steps,
    );
  }
}
