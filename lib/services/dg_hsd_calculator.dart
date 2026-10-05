import '../core/constants/app_constants.dart';
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

  // DG Tank Level Properties
  final double tankCapacity;
  final double openingLitres;
  final double topUpLitres;
  final double fuelAfterTopUp;
  final double percentageAfterTopUp;
  final double closingLitres;
  final double consumedLitres;
  final bool exceedsCapacity;
  final String? validationError;

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
    this.tankCapacity = AppConstants.DG_TANK_CAPACITY,
    required this.openingLitres,
    required this.topUpLitres,
    required this.fuelAfterTopUp,
    required this.percentageAfterTopUp,
    required this.closingLitres,
    required this.consumedLitres,
    this.exceedsCapacity = false,
    this.validationError,
  });

  bool get isValid => validationError == null && !exceedsCapacity;
}

class DgHsdCalculator {
  // ignore: constant_identifier_names
  static const double DG_TANK_CAPACITY = AppConstants.DG_TANK_CAPACITY;
  static const double dgTankCapacity = DG_TANK_CAPACITY;

  static DgHsdCalculationResult calculate({
    required double fuelAdded,
    required double startPercentage,
    required double endPercentage,
    double? fuelConsumption,
    required double kwh,
    required double runningHours,
    double tankCapacity = DG_TANK_CAPACITY,
  }) {
    // 1. Calculate Fuel Quantities from Percentages & Tank Capacity
    // 1% = (tankCapacity / 100) L (e.g. 3.8 L for 380 L tank)
    final double openingLitres = (startPercentage / 100.0) * tankCapacity;
    final double topUpLitres = fuelAdded;
    final double fuelAfterTopUp = openingLitres + topUpLitres;
    final double percentageAfterTopUp =
        tankCapacity > 0 ? (fuelAfterTopUp / tankCapacity) * 100.0 : 0.0;
    final double closingLitres = (endPercentage / 100.0) * tankCapacity;
    final double calculatedConsumedLitres =
        openingLitres + topUpLitres - closingLitres;

    // 2. Validate inputs & capacity limits
    final bool fuelAddedValid = fuelAdded >= 0.0;
    final bool startPercentValid = startPercentage >= 0.0 && startPercentage <= 100.0;
    final bool endPercentValid = endPercentage >= 0.0 && endPercentage <= 100.0;
    final bool exceedsCapacity = fuelAfterTopUp > tankCapacity;

    String? validationError;
    if (!fuelAddedValid) {
      validationError = 'Top-up litres cannot be negative.';
    } else if (!startPercentValid) {
      validationError = 'Opening fuel level must be between 0% and 100%.';
    } else if (!endPercentValid) {
      validationError = 'Closing fuel level must be between 0% and 100%.';
    } else if (exceedsCapacity) {
      validationError =
          'Fuel after top-up (${fuelAfterTopUp.toStringAsFixed(1)} L / ${percentageAfterTopUp.toStringAsFixed(2)}%) exceeds DG tank capacity of ${tankCapacity.toStringAsFixed(0)} L.';
    } else if (calculatedConsumedLitres < 0) {
      validationError = 'Closing fuel level cannot exceed fuel after top-up.';
    }

    // 3. Determine effective fuel consumption
    // 3. Determine effective fuel consumption (strictly manual input)
    final double effectiveFuelConsumption = (fuelConsumption != null && fuelConsumption > 0)
        ? fuelConsumption
        : 0.0;

    final double percentageDrop = startPercentage - endPercentage;
    final double consumptionPerHour =
        runningHours > 0 ? (effectiveFuelConsumption / runningHours) : 0.0;
    final double unitsPerLitre =
        effectiveFuelConsumption > 0 ? (kwh / effectiveFuelConsumption) : 0.0;
    final double averageLoadKw =
        runningHours > 0 ? (kwh / runningHours) : 0.0;

    final steps = <BreakdownStep>[
      BreakdownStep(
        stepTitle: 'Step 1: Opening Fuel Level (Tank: ${tankCapacity.toStringAsFixed(0)} L)',
        formula: '(Opening % ÷ 100) × Tank Capacity',
        calculation:
            '(${startPercentage.toStringAsFixed(1)}% ÷ 100) × ${tankCapacity.toStringAsFixed(0)} L = ${openingLitres.toStringAsFixed(1)} L',
        note: '1% corresponds to ${(tankCapacity / 100).toStringAsFixed(1)} L fuel volume',
      ),
      BreakdownStep(
        stepTitle: 'Step 2: Fuel Top-up & Level After Top-up',
        formula: 'Opening Litres + Fuel Added (Top-up)',
        calculation: topUpLitres > 0
            ? '${openingLitres.toStringAsFixed(1)} L + ${topUpLitres.toStringAsFixed(1)} L = ${fuelAfterTopUp.toStringAsFixed(1)} L (${percentageAfterTopUp.toStringAsFixed(2)}%)'
            : 'No top-up entry (—)',
        note: exceedsCapacity
            ? '⚠️ WARNING: Calculated level exceeds tank capacity of ${tankCapacity.toStringAsFixed(0)} L'
            : (topUpLitres > 0
                ? '${topUpLitres.toStringAsFixed(1)} L added during shift'
                : 'No fuel added during this shift'),
      ),
      BreakdownStep(
        stepTitle: 'Step 3: Closing Fuel Level',
        formula: '(Closing % ÷ 100) × Tank Capacity',
        calculation:
            '(${endPercentage.toStringAsFixed(1)}% ÷ 100) × ${tankCapacity.toStringAsFixed(0)} L = ${closingLitres.toStringAsFixed(1)} L',
        note: 'Ending fuel level at shift conclusion',
      ),
      BreakdownStep(
        stepTitle: 'Step 4: Tank Consumption (Level Difference)',
        formula: 'Opening Litres + Top-up Litres - Closing Litres',
        calculation:
            '${openingLitres.toStringAsFixed(1)} L + ${topUpLitres.toStringAsFixed(1)} L - ${closingLitres.toStringAsFixed(1)} L = ${calculatedConsumedLitres.toStringAsFixed(1)} L',
        note: calculatedConsumedLitres >= 0
            ? 'Total diesel difference from tank level drop'
            : 'Check tank levels: closing level exceeds fuel after top-up',
      ),
      BreakdownStep(
        stepTitle: 'Step 5: Total Fuel Consumed (Manual Input)',
        formula: 'Manual Entry (Litres)',
        calculation: effectiveFuelConsumption > 0
            ? '${effectiveFuelConsumption.toStringAsFixed(1)} L'
            : '0.0 L (Awaiting manual entry)',
        note: 'Actual generator fuel consumed during the shift (manual input)',
      ),
      BreakdownStep(
        stepTitle: 'Step 6: Energy Generation Efficiency (Specific Yield)',
        formula: 'Energy Generated (kWh) ÷ Total Fuel Consumed (L)',
        calculation:
            '${kwh.toStringAsFixed(1)} kWh ÷ ${effectiveFuelConsumption.toStringAsFixed(1)} L = ${unitsPerLitre.toStringAsFixed(2)} kWh / Litre',
        note: 'Standard dairy plant DG benchmark: 3.0 to 3.8 units / Litre',
      ),
      BreakdownStep(
        stepTitle: 'Step 7: Fuel Consumption Rate',
        formula: 'Total Fuel Consumed (L) ÷ Running Hours (hr)',
        calculation:
            '${effectiveFuelConsumption.toStringAsFixed(1)} L ÷ ${runningHours.toStringAsFixed(1)} hrs = ${consumptionPerHour.toStringAsFixed(2)} L / hour',
        note: 'Average hourly DG diesel burn rate',
      ),
      if (runningHours > 0)
        BreakdownStep(
          stepTitle: 'Step 8: Average Plant Electrical Load on DG',
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
      fuelConsumption: effectiveFuelConsumption,
      kwh: kwh,
      runningHours: runningHours,
      consumptionPerHour: consumptionPerHour,
      unitsPerLitre: unitsPerLitre,
      averageLoadKw: averageLoadKw,
      breakdownSteps: steps,
      tankCapacity: tankCapacity,
      openingLitres: openingLitres,
      topUpLitres: topUpLitres,
      fuelAfterTopUp: fuelAfterTopUp,
      percentageAfterTopUp: percentageAfterTopUp,
      closingLitres: closingLitres,
      consumedLitres: calculatedConsumedLitres,
      exceedsCapacity: exceedsCapacity,
      validationError: validationError,
    );
  }
}
