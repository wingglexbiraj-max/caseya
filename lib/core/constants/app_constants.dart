/// Application Constants
class AppConstants {
  static const String appName = 'CASEYA';
  static const String appSubtitle = 'Dairy Plant Operations & Calculation System';
  static const String appVersion = '1.0.0';
  static const String plantName = 'Central Dairy Processing Facility';
  static const String formulaVersion = 'v1.2-Standard-2026';

  // Responsive Breakpoints
  static const double mobileBreakpoint = 650;
  static const double tabletBreakpoint = 1050;
  static const double desktopBreakpoint = 1440;

  // Boiler Formula Constants: ((Opening CM - Closing CM) * 900) / 70
  static const double boilerMultiplier = 900.0;
  static const double boilerDivisor = 70.0;

  // Standard Shift Names
  static const List<String> shifts = [
    'Shift A (06:00 - 14:00)',
    'Shift B (14:00 - 22:00)',
    'Shift C (22:00 - 06:00)',
    'General Shift (09:00 - 17:30)',
  ];

  // User Roles
  static const String roleAdmin = 'Admin';
  static const String roleSupervisor = 'Supervisor';
  static const String roleOperator = 'Operator';

  // Local Storage Keys
  static const String storageKeyUser = 'caseya_current_user';
  static const String storageKeyProducts = 'caseya_products_master';
  static const String storageKeyBoilerRecords = 'caseya_boiler_records';
  static const String storageKeyStdRecords = 'caseya_standardization_records';
  static const String storageKeyProductCalcRecords = 'caseya_product_calc_records';
  static const String storageKeyProductionRecords = 'caseya_production_records';
  static const String storageKeyDispatchRecords = 'caseya_dispatch_records';
  static const String storageKeyPackagingRecords = 'caseya_packaging_records';
  static const String storageKeyStockRecords = 'caseya_stock_records';
  static const String storageKeySettings = 'caseya_system_settings';
  static const String storageKeyApiUrl = 'caseya_api_url';
}
