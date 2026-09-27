/// Architecture & Schema Mapping for Google Sheets Backend Store
///
/// IMPORTANT SECURITY NOTICE:
/// Plant security regulations dictate that Google Service Account JSON keys
/// and OAuth private credentials MUST NEVER reside inside Flutter Web client code.
/// This service encapsulates the schema specifications and mapping logic
/// implemented on the FastAPI backend layer (see `backend/google_sheets_client.py`).
class GoogleSheetsSchema {
  // Google Sheets Tab Names
  static const String sheetUsers = 'Users';
  static const String sheetProducts = 'Products';
  static const String sheetLabData = 'Lab_Data';
  static const String sheetStandardization = 'Standardization';
  static const String sheetBoiler = 'Boiler';
  static const String sheetProduction = 'Production';
  static const String sheetDispatch = 'Dispatch';
  static const String sheetPackaging = 'Packaging';
  static const String sheetStock = 'Stock';
  static const String sheetAuditLog = 'Audit_Log';

  /// Standard column headers for the Boiler sheet
  static const List<String> boilerHeaders = [
    'record_id',
    'date',
    'time',
    'shift',
    'employee_id',
    'employee_name',
    'opening_cm',
    'closing_cm',
    'level_difference_cm',
    'calculated_level_consumption',
    'fuel_top_up',
    'net_reported_consumption',
    'running_hours',
    'consumption_per_hour',
    'remarks',
    'created_at',
    'updated_at',
  ];

  /// Standard column headers for Standardization sheet
  static const List<String> standardizationHeaders = [
    'record_id',
    'date',
    'time',
    'employee_id',
    'employee_name',
    'input_milk_quantity',
    'input_unit',
    'input_fat',
    'input_snf',
    'target_product_id',
    'target_product_name',
    'target_fat',
    'target_snf',
    'water_required',
    'smp_required',
    'sugar_required',
    'final_quantity',
    'final_fat',
    'final_snf',
    'calculation_formula_version',
    'notes',
    'created_at',
  ];

  /// Standard column headers for Products sheet
  static const List<String> productHeaders = [
    'product_id',
    'product_name',
    'category',
    'unit',
    'pack_size',
    'pack_size_display',
    'pieces_per_crate',
    'allowed_input_modes',
    'target_fat',
    'target_snf',
    'active',
  ];
}
