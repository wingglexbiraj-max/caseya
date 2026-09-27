import '../core/constants/app_constants.dart';
import '../core/widgets/calculation_breakdown.dart';
import '../core/utils/formatters.dart';

class BoilerCalculationResult {
  final double openingCm;
  final double closingCm;
  final double levelDifferenceCm;
  final double calculatedLevelConsumption;
  final double fuelTopUp;
  final double netReportedConsumption;
  final double runningHours;
  final double consumptionPerHour;
  final List<BreakdownStep> breakdownSteps;

  const BoilerCalculationResult({
    required this.openingCm,
    required this.closingCm,
    required this.levelDifferenceCm,
    required this.calculatedLevelConsumption,
    required this.fuelTopUp,
    required this.netReportedConsumption,
    required this.runningHours,
    required this.consumptionPerHour,
    required this.breakdownSteps,
  });
}

/// Dedicated Boiler Fuel Consumption Engine
///
/// Formula specified by plant:
/// Fuel Consumption (L) = ((Opening CM - Closing CM) × 900) / 70
///
/// Top-up configuration:
/// Configurable mode:
/// - Mode A (Standard): Net Consumption = Calculated Level Consumption + Fuel Top-up
/// - Mode B (Excluding Top-up): Net Consumption = Calculated Level Consumption (top-up tracked separately)
class BoilerCalculator {
  static BoilerCalculationResult calculate({
    required double openingCm,
    required double closingCm,
    required double runningHours,
    double fuelTopUp = 0.0,
    bool includeTopUpInNet = true,
  }) {
    // 1. Calculate Level Difference
    final double levelDifferenceCm = openingCm - closingCm;

    // 2. Calculate Level-based Fuel Consumption using exact plant formula
    // ((Opening CM - Closing CM) × 900) / 70
    final double calculatedLevelConsumption = levelDifferenceCm > 0
        ? ((levelDifferenceCm * AppConstants.boilerMultiplier) / AppConstants.boilerDivisor)
        : 0.0;

    // 3. Compute Net / Reported Consumption according to configuration
    final double netReportedConsumption = includeTopUpInNet
        ? (calculatedLevelConsumption + fuelTopUp)
        : calculatedLevelConsumption;

    // 4. Calculate Consumption Per Hour (prevent division by zero)
    final double consumptionPerHour = (runningHours > 0.0)
        ? (netReportedConsumption / runningHours)
        : 0.0;

    // 5. Construct step-by-step breakdown
    final List<BreakdownStep> steps = [
      BreakdownStep(
        stepTitle: 'Step 1: Level Difference (CM)',
        formula: 'Difference = Opening CM - Closing CM',
        calculation:
            '${Formatters.formatSmart(openingCm)} CM - ${Formatters.formatSmart(closingCm)} CM = ${Formatters.formatSmart(levelDifferenceCm)} CM',
      ),
      BreakdownStep(
        stepTitle: 'Step 2: Level-Based Fuel Consumption (L)',
        formula: 'Consumption (L) = (Level Difference × 900) ÷ 70',
        calculation:
            '(${Formatters.formatSmart(levelDifferenceCm)} CM × 900) ÷ 70 = ${Formatters.formatSmart(calculatedLevelConsumption)} Litres',
        note: 'Plant calibration factor: 900 L per 70 CM level drop',
      ),
    ];

    if (fuelTopUp > 0.0) {
      steps.add(BreakdownStep(
        stepTitle: 'Step 3: Fuel Top-up Adjustment',
        formula: includeTopUpInNet
            ? 'Net Consumption = Level Consumption + Top-up'
            : 'Top-up Recorded Separately',
        calculation: includeTopUpInNet
            ? '${Formatters.formatSmart(calculatedLevelConsumption)} L + ${Formatters.formatSmart(fuelTopUp)} L = ${Formatters.formatSmart(netReportedConsumption)} Litres'
            : 'Top-up: ${Formatters.formatSmart(fuelTopUp)} L (Excluded from shift level burn)',
      ));
    }

    steps.add(BreakdownStep(
      stepTitle: 'Step ${fuelTopUp > 0.0 ? 4 : 3}: Consumption per Hour',
      formula: 'Consumption / Hour = Total Consumption ÷ Running Hours',
      calculation: runningHours > 0
          ? '${Formatters.formatSmart(netReportedConsumption)} L ÷ ${Formatters.formatSmart(runningHours)} hrs = ${Formatters.formatDecimal(consumptionPerHour)} L/hr'
          : 'Running hours is 0 hr (0.00 L/hr)',
    ));

    return BoilerCalculationResult(
      openingCm: openingCm,
      closingCm: closingCm,
      levelDifferenceCm: levelDifferenceCm,
      calculatedLevelConsumption: calculatedLevelConsumption,
      fuelTopUp: fuelTopUp,
      netReportedConsumption: netReportedConsumption,
      runningHours: runningHours,
      consumptionPerHour: consumptionPerHour,
      breakdownSteps: steps,
    );
  }
}
