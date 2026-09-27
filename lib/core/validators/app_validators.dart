class AppValidators {
  /// Validate non-empty string
  static String? required(String? value, [String? fieldName]) {
    if (value == null || value.trim().isEmpty) {
      return fieldName != null ? '$fieldName cannot be empty' : 'This field is required';
    }
    return null;
  }

  /// Validate positive non-zero number
  static String? positiveNumber(String? value, [String? fieldName]) {
    final reqError = required(value, fieldName);
    if (reqError != null) return reqError;

    final cleaned = value!.replaceAll(',', '').trim();
    final parsed = double.tryParse(cleaned);
    if (parsed == null) {
      return 'Enter a valid number';
    }
    if (parsed <= 0) {
      return fieldName != null ? '$fieldName must be greater than zero' : 'Must be greater than zero';
    }
    if (parsed > 100000000) {
      return 'Value is unusually large. Please verify';
    }
    return null;
  }

  /// Validate non-negative number (>= 0 allowed, e.g. top-up can be 0)
  static String? nonNegativeNumber(String? value, [String? fieldName]) {
    if (value == null || value.trim().isEmpty) return null; // allow empty if optional, or check required first

    final cleaned = value.replaceAll(',', '').trim();
    final parsed = double.tryParse(cleaned);
    if (parsed == null) {
      return 'Enter a valid number';
    }
    if (parsed < 0) {
      return fieldName != null ? '$fieldName cannot be negative' : 'Cannot be negative';
    }
    return null;
  }

  /// Validate Milk FAT percentage (typically 0.1% to 15.0% for raw/whole/buffalo milk)
  static String? milkFat(String? value) {
    final reqError = required(value, 'Milk FAT');
    if (reqError != null) return reqError;

    final cleaned = value!.replaceAll(',', '').trim();
    final parsed = double.tryParse(cleaned);
    if (parsed == null) return 'Enter a valid decimal percentage';
    if (parsed <= 0.0 || parsed > 15.0) {
      return 'Milk FAT must be between 0.1% and 15.0%';
    }
    return null;
  }

  /// Validate Milk SNF percentage (typically 5.0% to 15.0%)
  static String? milkSnf(String? value) {
    final reqError = required(value, 'Milk SNF');
    if (reqError != null) return reqError;

    final cleaned = value!.replaceAll(',', '').trim();
    final parsed = double.tryParse(cleaned);
    if (parsed == null) return 'Enter a valid decimal percentage';
    if (parsed <= 0.0 || parsed > 16.0) {
      return 'Milk SNF must be between 5.0% and 16.0%';
    }
    return null;
  }

  /// Validate Boiler Levels: Opening vs Closing
  static String? boilerLevels(double openingCm, double closingCm, {bool allowTopUpScenario = false}) {
    if (openingCm < 0) return 'Opening CM cannot be negative';
    if (closingCm < 0) return 'Closing CM cannot be negative';
    if (!allowTopUpScenario && closingCm > openingCm) {
      return 'Closing CM ($closingCm cm) is greater than Opening CM ($openingCm cm). If fuel was filled, please specify Top-up.';
    }
    return null;
  }
}
