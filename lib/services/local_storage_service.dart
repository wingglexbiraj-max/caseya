import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';
import '../models/product_model.dart';
import '../models/boiler_record.dart';
import '../models/standardization_record.dart';
import '../models/product_calculation_record.dart';
import '../models/lab_record.dart';
import '../models/user_model.dart';
import '../models/operations_models.dart';

class LocalStorageService {
  static SharedPreferences? _prefs;

  static Future<SharedPreferences> get _instance async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  /// Initialize default data on first launch
  static Future<void> init() async {
    final prefs = await _instance;
    if (!prefs.containsKey(AppConstants.storageKeyProducts)) {
      await _seedInitialProducts(prefs);
    }
    if (!prefs.containsKey(AppConstants.storageKeyBoilerRecords)) {
      await _seedInitialBoilerRecords(prefs);
    }
    if (!prefs.containsKey(AppConstants.storageKeyStdRecords)) {
      await _seedInitialStandardizationRecords(prefs);
    }
    if (!prefs.containsKey(AppConstants.storageKeyStockRecords)) {
      await _seedInitialStockRecords(prefs);
    }
  }

  // ===========================================================================
  // PRODUCTS
  // ===========================================================================

  static Future<List<ProductModel>> getProducts() async {
    final prefs = await _instance;
    final jsonStr = prefs.getString(AppConstants.storageKeyProducts);
    if (jsonStr == null || jsonStr.isEmpty) {
      await _seedInitialProducts(prefs);
      return getProducts();
    }
    try {
      final List<dynamic> list = jsonDecode(jsonStr);
      return list.map((e) => ProductModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveProducts(List<ProductModel> products) async {
    final prefs = await _instance;
    final jsonStr = jsonEncode(products.map((e) => e.toJson()).toList());
    await prefs.setString(AppConstants.storageKeyProducts, jsonStr);
  }

  static Future<void> addOrUpdateProduct(ProductModel product) async {
    final list = await getProducts();
    final index = list.indexWhere((p) => p.productId == product.productId);
    if (index >= 0) {
      list[index] = product;
    } else {
      list.add(product);
    }
    await saveProducts(list);
  }

  static Future<void> deleteProduct(String productId) async {
    final list = await getProducts();
    list.removeWhere((p) => p.productId == productId);
    await saveProducts(list);
  }

  // ===========================================================================
  // BOILER RECORDS
  // ===========================================================================

  static Future<List<BoilerRecord>> getBoilerRecords() async {
    final prefs = await _instance;
    final jsonStr = prefs.getString(AppConstants.storageKeyBoilerRecords);
    if (jsonStr == null || jsonStr.isEmpty) return [];
    try {
      final List<dynamic> list = jsonDecode(jsonStr);
      final records = list.map((e) => BoilerRecord.fromJson(e as Map<String, dynamic>)).toList();
      records.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return records;
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveBoilerRecords(List<BoilerRecord> records) async {
    final prefs = await _instance;
    final jsonStr = jsonEncode(records.map((e) => e.toJson()).toList());
    await prefs.setString(AppConstants.storageKeyBoilerRecords, jsonStr);
  }

  static Future<void> addBoilerRecord(BoilerRecord record) async {
    final records = await getBoilerRecords();
    records.insert(0, record);
    await saveBoilerRecords(records);
  }

  static Future<void> updateBoilerRecord(BoilerRecord record) async {
    final records = await getBoilerRecords();
    final index = records.indexWhere((r) => r.recordId == record.recordId);
    if (index >= 0) {
      records[index] = record;
      await saveBoilerRecords(records);
    }
  }

  static Future<void> deleteBoilerRecord(String recordId) async {
    final records = await getBoilerRecords();
    records.removeWhere((r) => r.recordId == recordId);
    await saveBoilerRecords(records);
  }

  // ===========================================================================
  // STANDARDIZATION RECORDS
  // ===========================================================================

  static Future<List<StandardizationRecord>> getStandardizationRecords() async {
    final prefs = await _instance;
    final jsonStr = prefs.getString(AppConstants.storageKeyStdRecords);
    if (jsonStr == null || jsonStr.isEmpty) return [];
    try {
      final List<dynamic> list = jsonDecode(jsonStr);
      final records = list.map((e) => StandardizationRecord.fromJson(e as Map<String, dynamic>)).toList();
      records.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return records;
    } catch (_) {
      return [];
    }
  }

  static Future<void> addStandardizationRecord(StandardizationRecord record) async {
    final records = await getStandardizationRecords();
    records.insert(0, record);
    final prefs = await _instance;
    await prefs.setString(AppConstants.storageKeyStdRecords, jsonEncode(records.map((e) => e.toJson()).toList()));
  }

  static Future<void> deleteStandardizationRecord(String recordId) async {
    final records = await getStandardizationRecords();
    records.removeWhere((r) => r.recordId == recordId);
    final prefs = await _instance;
    await prefs.setString(AppConstants.storageKeyStdRecords, jsonEncode(records.map((e) => e.toJson()).toList()));
  }

  // ===========================================================================
  // PRODUCT CALCULATION RECORDS
  // ===========================================================================

  static Future<List<ProductCalculationRecord>> getProductCalcRecords() async {
    final prefs = await _instance;
    final jsonStr = prefs.getString(AppConstants.storageKeyProductCalcRecords);
    if (jsonStr == null || jsonStr.isEmpty) return [];
    try {
      final List<dynamic> list = jsonDecode(jsonStr);
      final records = list.map((e) => ProductCalculationRecord.fromJson(e as Map<String, dynamic>)).toList();
      records.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return records;
    } catch (_) {
      return [];
    }
  }

  static Future<void> addProductCalcRecord(ProductCalculationRecord record) async {
    final records = await getProductCalcRecords();
    records.insert(0, record);
    final prefs = await _instance;
    await prefs.setString(AppConstants.storageKeyProductCalcRecords, jsonEncode(records.map((e) => e.toJson()).toList()));
  }

  // ===========================================================================
  // LAB RECORDS
  // ===========================================================================

  static Future<LabRecord?> getTodayLabRecord(String date) async {
    // Returns lab test record matching today's date
    final todayIso = date;
    return LabRecord(
      recordId: 'LAB-${todayIso.replaceAll('-', '')}-01',
      date: todayIso,
      sampleTime: '08:30 AM',
      batchOrSiloNo: 'Raw Milk Silo #02',
      milkQuantity: 12500.0,
      fatPercent: 4.20,
      snfPercent: 8.65,
      clr: 29.5,
      acidity: 0.13,
      temperature: 4.2,
      analystName: 'P. Sharma (Sr. Chemist)',
      remarks: 'Fresh Morning Procurement Tanker Batch #TB-402',
    );
  }

  // ===========================================================================
  // STOCK & OPERATIONS RECORDS
  // ===========================================================================

  static Future<List<StockRecord>> getStockRecords() async {
    final prefs = await _instance;
    final jsonStr = prefs.getString(AppConstants.storageKeyStockRecords);
    if (jsonStr == null || jsonStr.isEmpty) return [];
    try {
      final List<dynamic> list = jsonDecode(jsonStr);
      return list.map((e) => StockRecord.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  // ===========================================================================
  // USER & SETTINGS
  // ===========================================================================

  static Future<UserModel> getCurrentUser() async {
    final prefs = await _instance;
    final jsonStr = prefs.getString(AppConstants.storageKeyUser);
    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        return UserModel.fromJson(jsonDecode(jsonStr));
      } catch (_) {}
    }
    return const UserModel(
      userId: 'EMP-0104',
      employeeCode: 'OPR-104',
      name: 'R. K. Baruah',
      email: 'rbaruah@caseya-plant.com',
      role: 'Supervisor',
      department: 'Processing & Operations',
    );
  }

  static Future<void> saveCurrentUser(UserModel user) async {
    final prefs = await _instance;
    await prefs.setString(AppConstants.storageKeyUser, jsonEncode(user.toJson()));
  }

  static Future<bool> getBoilerTopUpIncluded() async {
    final prefs = await _instance;
    return prefs.getBool('boiler_topup_included') ?? true;
  }

  static Future<void> setBoilerTopUpIncluded(bool value) async {
    final prefs = await _instance;
    await prefs.setBool('boiler_topup_included', value);
  }

  // ===========================================================================
  // SEED INITIAL DATA
  // ===========================================================================

  static Future<void> _seedInitialProducts(SharedPreferences prefs) async {
    final initialProducts = [
      const ProductModel(
        productId: '9900010',
        productName: 'Sweet Curd Cup 400g (S400)',
        itemCode: '9900010',
        shortCode: 'S400',
        category: 'Curd',
        unit: 'g',
        packSize: 400,
        packSizeDisplay: '400 g',
        piecesPerCrate: 15,
        perCrateQty: 6.0,
        perCrateQtyGrams: 6000.0,
        perCrateDisplay: '6.0 kg (6000.0 g)',
        pricePerPiece: 55.0,
        shelfLife: '12 Days',
        allowedInputModes: ['Pieces', 'Crates', 'Kg'],
        targetFat: 3.5,
        targetSnf: 10.0,
      ),
      const ProductModel(
        productId: '9900026',
        productName: 'Plain Curd Cup 80g (P80)',
        itemCode: '9900026',
        shortCode: 'P80',
        category: 'Curd',
        unit: 'g',
        packSize: 80,
        packSizeDisplay: '80 g',
        piecesPerCrate: 60,
        perCrateQty: 4.8,
        perCrateQtyGrams: 4800.0,
        perCrateDisplay: '4.8 kg (4800.0 g)',
        pricePerPiece: 15.0,
        shelfLife: '12 Days',
        allowedInputModes: ['Pieces', 'Crates', 'Kg'],
        targetFat: 3.2,
        targetSnf: 9.0,
      ),
      const ProductModel(
        productId: '9900013',
        productName: 'Plain Curd Cup 400g (P400)',
        itemCode: '9900013',
        shortCode: 'P400',
        category: 'Curd',
        unit: 'g',
        packSize: 400,
        packSizeDisplay: '400 g',
        piecesPerCrate: 15,
        perCrateQty: 6.0,
        perCrateQtyGrams: 6000.0,
        perCrateDisplay: '6.0 kg (6000.0 g)',
        pricePerPiece: 55.0,
        shelfLife: '12 Days',
        allowedInputModes: ['Pieces', 'Crates', 'Kg'],
        targetFat: 3.2,
        targetSnf: 9.0,
      ),
      const ProductModel(
        productId: '9900007',
        productName: 'Purabi Lassi 200 ml (PL200)',
        itemCode: '9900007',
        shortCode: 'PL200',
        category: 'Fermented',
        unit: 'ml',
        packSize: 200,
        packSizeDisplay: '200 ml',
        piecesPerCrate: 30,
        perCrateQty: 6.0,
        perCrateQtyGrams: 6000.0,
        perCrateDisplay: '6.0 L (6000.0 ml)',
        pricePerPiece: 20.0,
        shelfLife: '7 Days',
        allowedInputModes: ['Pieces', 'Crates', 'Litres'],
        targetFat: 2.5,
        targetSnf: 9.0,
      ),
      const ProductModel(
        productId: 'CP400',
        productName: 'Curd Pouch 400 g (CP400)',
        itemCode: 'NA',
        shortCode: 'CP400',
        category: 'Curd',
        unit: 'g',
        packSize: 400,
        packSizeDisplay: '400 g',
        piecesPerCrate: 30,
        perCrateQty: 12.0,
        perCrateQtyGrams: 12000.0,
        perCrateDisplay: '12.0 kg (12000.0 g)',
        pricePerPiece: 35.0,
        shelfLife: '12 Days',
        allowedInputModes: ['Pieces', 'Crates', 'Kg'],
        targetFat: 3.2,
        targetSnf: 9.5,
      ),
      const ProductModel(
        productId: 'CP1000',
        productName: 'Curd Pouch 1 kg (CP1000)',
        itemCode: 'NA',
        shortCode: 'CP1000',
        category: 'Curd',
        unit: 'g',
        packSize: 1000,
        packSizeDisplay: '1 kg (1000 g)',
        piecesPerCrate: 12,
        perCrateQty: 12.0,
        perCrateQtyGrams: 12000.0,
        perCrateDisplay: '12.0 kg (12000.0 g)',
        pricePerPiece: 75.0,
        shelfLife: '12 Days',
        allowedInputModes: ['Pieces', 'Crates', 'Kg'],
        targetFat: 3.2,
        targetSnf: 9.5,
      ),
    ];
    await prefs.setString(
      AppConstants.storageKeyProducts,
      jsonEncode(initialProducts.map((e) => e.toJson()).toList()),
    );
  }

  static Future<void> _seedInitialBoilerRecords(SharedPreferences prefs) async {
    final now = DateTime.now();
    final boilerSeeds = [
      BoilerRecord(
        recordId: 'BLR-20260927-01',
        date: '2026-09-27',
        time: '02:00 PM',
        shift: 'Shift A (06:00 - 14:00)',
        employeeId: 'EMP-0104',
        employeeName: 'R. K. Baruah',
        openingCm: 500.0,
        closingCm: 430.0,
        levelDifferenceCm: 70.0,
        calculatedLevelConsumption: 900.0,
        fuelTopUp: 0.0,
        netReportedConsumption: 900.0,
        runningHours: 8.5,
        consumptionPerHour: 105.88,
        remarks: 'Normal operation during morning pasteurization run',
        createdAt: now.subtract(const Duration(hours: 4)),
        updatedAt: now.subtract(const Duration(hours: 4)),
      ),
      BoilerRecord(
        recordId: 'BLR-20260926-02',
        date: '2026-09-26',
        shift: 'Shift B (14:00 - 22:00)',
        time: '10:00 PM',
        employeeId: 'EMP-0112',
        employeeName: 'M. Hazarika',
        openingCm: 430.0,
        closingCm: 368.0,
        levelDifferenceCm: 62.0,
        calculatedLevelConsumption: 797.14,
        fuelTopUp: 0.0,
        netReportedConsumption: 797.14,
        runningHours: 8.0,
        consumptionPerHour: 99.64,
        remarks: 'Evening pouch packing cycle',
        createdAt: now.subtract(const Duration(days: 1, hours: 2)),
        updatedAt: now.subtract(const Duration(days: 1, hours: 2)),
      ),
      BoilerRecord(
        recordId: 'BLR-20260925-01',
        date: '2026-09-25',
        shift: 'Shift A (06:00 - 14:00)',
        time: '02:15 PM',
        employeeId: 'EMP-0104',
        employeeName: 'R. K. Baruah',
        openingCm: 515.0,
        closingCm: 440.0,
        levelDifferenceCm: 75.0,
        calculatedLevelConsumption: 964.29,
        fuelTopUp: 100.0,
        netReportedConsumption: 1064.29,
        runningHours: 8.0,
        consumptionPerHour: 133.04,
        remarks: 'Tanker fuel replenishment + normal pasteurizer load',
        createdAt: now.subtract(const Duration(days: 2, hours: 3)),
        updatedAt: now.subtract(const Duration(days: 2, hours: 3)),
      ),
    ];
    await prefs.setString(
      AppConstants.storageKeyBoilerRecords,
      jsonEncode(boilerSeeds.map((e) => e.toJson()).toList()),
    );
  }

  static Future<void> _seedInitialStandardizationRecords(SharedPreferences prefs) async {
    final now = DateTime.now();
    final stdSeeds = [
      StandardizationRecord(
        recordId: 'STD-20260927-01',
        date: '2026-09-27',
        time: '09:20 AM',
        employeeId: 'EMP-0104',
        employeeName: 'R. K. Baruah',
        inputMilkQuantity: 5000.0,
        inputFat: 3.8,
        inputSnf: 8.4,
        targetProductId: 'PRD-005',
        targetProductName: 'Lassi 200 ml',
        targetFat: 2.5,
        targetSnf: 9.0,
        waterRequired: 2600.0,
        smpRequired: 275.0,
        sugarRequired: 608.0,
        finalQuantity: 8213.0,
        finalFat: 2.45,
        finalSnf: 9.02,
        calculationFormulaVersion: 'v1.2-Standard-Dairy-MassBalance',
        notes: 'Morning Lassi production batch #LS-0927',
        createdAt: now.subtract(const Duration(hours: 6)),
      ),
    ];
    await prefs.setString(
      AppConstants.storageKeyStdRecords,
      jsonEncode(stdSeeds.map((e) => e.toJson()).toList()),
    );
  }

  static Future<void> _seedInitialStockRecords(SharedPreferences prefs) async {
    final now = DateTime.now();
    final stockSeeds = [
      StockRecord(
        productId: 'PRD-001',
        productName: 'Purabi Plus Milk 500 ml',
        category: 'Milk',
        pieces: 4200,
        crates: 210,
        volumeLitres: 2100,
        unit: 'Litres',
        minThresholdLitres: 500,
        lastUpdated: now,
      ),
      StockRecord(
        productId: 'PRD-002',
        productName: 'Purabi Plus Milk 250 ml',
        category: 'Milk',
        pieces: 3600,
        crates: 90,
        volumeLitres: 900,
        unit: 'Litres',
        minThresholdLitres: 300,
        lastUpdated: now,
      ),
      StockRecord(
        productId: 'PRD-003',
        productName: 'Curd Pouch 400 g',
        category: 'Curd',
        pieces: 1800,
        crates: 72,
        volumeLitres: 720,
        unit: 'Kg',
        minThresholdLitres: 200,
        lastUpdated: now,
      ),
    ];
    await prefs.setString(
      AppConstants.storageKeyStockRecords,
      jsonEncode(stockSeeds.map((e) => e.toJson()).toList()),
    );
  }
}
