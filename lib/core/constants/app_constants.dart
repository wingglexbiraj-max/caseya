export '../theme/app_text_sizes.dart';

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

  /// Dynamically determines the active shift based on a DateTime timestamp
  static String determineShift(DateTime dt) {
    final hour = dt.hour;
    if (hour >= 6 && hour < 14) return 'Shift A (06:00 - 14:00)';
    if (hour >= 14 && hour < 22) return 'Shift B (14:00 - 22:00)';
    return 'Shift C (22:00 - 06:00)';
  }

  /// Parses 12-hour or 24-hour time string into a 24-hour hour integer (0-23)
  static int? parseHourFromTimeString(String timeStr) {
    try {
      final clean = timeStr.trim();
      final isPm = clean.toUpperCase().contains('PM');
      final isAm = clean.toUpperCase().contains('AM');
      final match = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(clean);
      if (match != null) {
        int h = int.parse(match.group(1)!);
        if (isPm && h < 12) h += 12;
        if (isAm && h == 12) h = 0;
        return h;
      }
    } catch (_) {}
    return null;
  }

  /// Determines shift from time string (e.g. '05:00 PM' -> Shift B, '10:30 AM' -> Shift A)
  static String determineShiftFromTimeString(String timeStr) {
    final hour = parseHourFromTimeString(timeStr);
    if (hour == null) return shifts.first;
    if (hour >= 6 && hour < 14) return 'Shift A (06:00 - 14:00)';
    if (hour >= 14 && hour < 22) return 'Shift B (14:00 - 22:00)';
    return 'Shift C (22:00 - 06:00)';
  }

  /// Validates whether a DateTime falls within the designated shift
  static bool isDateTimeValidForShift(DateTime dt, String shift) {
    final h = dt.hour;
    final s = shift.toLowerCase();
    if (s.contains('shift a')) return h >= 6 && h < 14;
    if (s.contains('shift b')) return h >= 14 && h < 22;
    if (s.contains('shift c')) return h >= 22 || h < 6;
    if (s.contains('general')) return h >= 9 && (h < 17 || (h == 17 && dt.minute <= 30));
    return true;
  }

  /// Validates whether a formatted time string falls within the designated shift
  static bool isTimeStringValidForShift(String timeStr, String shift) {
    final hour = parseHourFromTimeString(timeStr);
    if (hour == null) return true;
    final s = shift.toLowerCase();
    if (s.contains('shift a')) return hour >= 6 && hour < 14;
    if (s.contains('shift b')) return hour >= 14 && hour < 22;
    if (s.contains('shift c')) return hour >= 22 || hour < 6;
    if (s.contains('general')) return hour >= 9 && hour < 18;
    return true;
  }

  /// Adjusts a DateTime so its time of day is valid within the specified shift
  static DateTime alignDateTimeToShift(DateTime dt, String shift) {
    if (isDateTimeValidForShift(dt, shift)) return dt;
    final s = shift.toLowerCase();
    if (s.contains('shift a')) {
      return DateTime(dt.year, dt.month, dt.day, 10, 0); // 10:00 AM (mid Shift A)
    }
    if (s.contains('shift b')) {
      return DateTime(dt.year, dt.month, dt.day, 17, 0); // 05:00 PM (mid Shift B)
    }
    if (s.contains('shift c')) {
      return DateTime(dt.year, dt.month, dt.day, 23, 30); // 11:30 PM (mid Shift C)
    }
    if (s.contains('general')) {
      return DateTime(dt.year, dt.month, dt.day, 11, 0); // 11:00 AM (mid General)
    }
    return dt;
  }

  /// Returns a valid formatted time string (e.g. '10:00 AM') for the given shift
  static String alignTimeForShift(DateTime now, String shift) {
    final aligned = alignDateTimeToShift(now, shift);
    final hour12 = aligned.hour % 12 == 0 ? 12 : aligned.hour % 12;
    final amPm = aligned.hour >= 12 ? 'PM' : 'AM';
    final minuteStr = aligned.minute.toString().padLeft(2, '0');
    final hourStr = hour12.toString().padLeft(2, '0');
    return '$hourStr:$minuteStr $amPm';
  }

  /// Sanitizes shift against time string so they are never conflicting
  static String sanitizeShiftForTime(String shift, String timeStr) {
    if (timeStr.isEmpty) return shift;
    if (isTimeStringValidForShift(timeStr, shift)) {
      return shift;
    }
    return determineShiftFromTimeString(timeStr);
  }

  // User Roles
  static const String roleAdmin = 'Admin';
  static const String roleSupervisor = 'Supervisor';
  static const String roleOperator = 'Operator';

  // Local Storage Keys
  static const String storageKeyUser = 'caseya_current_user';
  static const String storageKeyProducts = 'caseya_products_master_v9';
  static const String storageKeyBoilerRecords = 'caseya_boiler_records';
  static const String storageKeyStdRecords = 'caseya_standardization_records';
  static const String storageKeyProductCalcRecords = 'caseya_product_calc_records';
  static const String storageKeyProductionRecords = 'caseya_production_records';
  static const String storageKeyDispatchRecords = 'caseya_dispatch_records';
  static const String storageKeyPackagingRecords = 'caseya_packaging_records';
  static const String storageKeyStockRecords = 'caseya_stock_records';
  static const String storageKeyBatchRecords = 'caseya_batch_records';
  static const String storageKeyDgHsdRecords = 'caseya_dg_hsd_records';
  static const String storageKeyLabMilkTests = 'caseya_lab_milk_tests';
  static const String storageKeySilos = 'caseya_silos_master';
  static const String storageKeySettings = 'caseya_system_settings';
  static const String storageKeyApiUrl = 'caseya_api_url';
}
