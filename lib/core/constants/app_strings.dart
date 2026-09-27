/// App Strings & Labels
class AppStrings {
  // Navigation
  static const String dashboard = 'Dashboard';
  static const String productCalculator = 'Product Calculator';
  static const String milkStandardization = 'Milk Standardization';
  static const String boiler = 'Boiler';
  static const String production = 'Production';
  static const String dispatch = 'Dispatch';
  static const String packaging = 'Packaging';
  static const String stock = 'Stock';
  static const String reports = 'Reports';
  static const String productsMaster = 'Products Master';
  static const String settings = 'Settings & Users';

  // Common Actions
  static const String calculate = 'Calculate';
  static const String saveRecord = 'Save Record';
  static const String reset = 'Reset';
  static const String edit = 'Edit';
  static const String delete = 'Delete';
  static const String search = 'Search records...';
  static const String filterByDate = 'Filter by Date';
  static const String filterByShift = 'Filter by Shift';
  static const String exportExcel = 'Export CSV / Excel';
  static const String exportPdf = 'Export Report';
  static const String viewBreakdown = 'How was this calculated?';
  static const String viewCalculation = 'View Step-by-Step Calculation';

  // Validation
  static const String requiredField = 'This field is required';
  static const String enterValidNumber = 'Enter a valid positive number';
  static const String openingCmRequired = 'Opening CM cannot be empty';
  static const String closingCmRequired = 'Closing CM cannot be empty';
  static const String runningHoursRequired = 'Running hours cannot be empty or negative';
  static const String fatRangeError = 'Milk FAT must be between 0.1% and 15.0%';
  static const String snfRangeError = 'Milk SNF must be between 5.0% and 15.0%';
  static const String invalidClosingCm = 'Closing CM cannot exceed Opening CM (unless top-up occurred)';
}
