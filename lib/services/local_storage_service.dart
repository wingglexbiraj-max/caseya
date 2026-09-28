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
import '../models/batch_record_model.dart';

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
    if (!prefs.containsKey(AppConstants.storageKeyBatchRecords)) {
      await _seedInitialBatchRecords(prefs);
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
      var products = list.map((e) => ProductModel.fromJson(e as Map<String, dynamic>)).toList();

      bool needsResave = false;
      const cp400 = ProductModel(
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
      );

      const cp1000 = ProductModel(
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
      );

      const p200 = ProductModel(
        productId: 'P200',
        productName: 'Plain Curd Cup 200g (P200)',
        itemCode: 'NA',
        shortCode: 'P200',
        category: 'Curd',
        unit: 'g',
        packSize: 200,
        packSizeDisplay: '200 g',
        piecesPerCrate: 30,
        perCrateQty: 6.0,
        perCrateQtyGrams: 6000.0,
        perCrateDisplay: '6.0 kg (6000.0 g)',
        pricePerPiece: 30.0,
        shelfLife: '12 Days',
        allowedInputModes: ['Pieces', 'Crates', 'Kg'],
        targetFat: 3.2,
        targetSnf: 9.0,
      );

      final initialLength = products.length;
      products.removeWhere((p) =>
          p.productId == 'PCP400' ||
          p.productId == 'PCP1000' ||
          p.productId == 'SCP400' ||
          p.productId == 'SCP1000');
      if (products.length != initialLength) needsResave = true;

      final idx400 = products.indexWhere((p) => p.productId == 'CP400' || p.shortCode == 'CP400');
      if (idx400 >= 0) {
        if (products[idx400].piecesPerCrate != 30 ||
            products[idx400].pricePerPiece != 35.0 ||
            products[idx400].productName != 'Curd Pouch 400 g (CP400)') {
          products[idx400] = cp400;
          needsResave = true;
        }
      } else {
        products.add(cp400);
        needsResave = true;
      }

      final idx1000 = products.indexWhere((p) => p.productId == 'CP1000' || p.shortCode == 'CP1000');
      if (idx1000 >= 0) {
        if (products[idx1000].piecesPerCrate != 12 ||
            products[idx1000].pricePerPiece != 75.0 ||
            products[idx1000].productName != 'Curd Pouch 1 kg (CP1000)') {
          products[idx1000] = cp1000;
          needsResave = true;
        }
      } else {
        products.add(cp1000);
        needsResave = true;
      }

      final idx200 = products.indexWhere((p) => p.productId == 'P200' || p.shortCode == 'P200');
      if (idx200 < 0) {
        products.add(p200);
        needsResave = true;
      }

      if (needsResave) {
        await saveProducts(products);
      }
      return products;
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
      // 1. Purabi Plus 500 ml (STD 500)
      const ProductModel(
        productId: 'STD500',
        productName: 'Purabi Plus 500 ml (STD 500)',
        itemCode: '9900001',
        shortCode: 'STD 500',
        category: 'Milk',
        unit: 'ml',
        packSize: 500,
        packSizeDisplay: '500 ml',
        piecesPerCrate: 20,
        perCrateQty: 10.0,
        perCrateQtyGrams: 10000.0,
        perCrateDisplay: '10.0 L (10000.0 ml)',
        pricePerPiece: 28.0,
        shelfLife: '2 Days',
        allowedInputModes: ['Pieces', 'Crates', 'Litres'],
        targetFat: 4.5,
        targetSnf: 8.5,
      ),
      // 2. Purabi Plus 250 ml (STD 250)
      const ProductModel(
        productId: 'STD250',
        productName: 'Purabi Plus 250 ml (STD 250)',
        itemCode: '9900002',
        shortCode: 'STD 250',
        category: 'Milk',
        unit: 'ml',
        packSize: 250,
        packSizeDisplay: '250 ml',
        piecesPerCrate: 40,
        perCrateQty: 10.0,
        perCrateQtyGrams: 10000.0,
        perCrateDisplay: '10.0 L (10000.0 ml)',
        pricePerPiece: 15.0,
        shelfLife: '2 Days',
        allowedInputModes: ['Pieces', 'Crates', 'Litres'],
        targetFat: 4.5,
        targetSnf: 8.5,
      ),
      // 3. Purabi Smart Plus 500 ml (SM+ 500)
      const ProductModel(
        productId: 'SM500',
        productName: 'Purabi Smart Plus 500 ml (SM+ 500)',
        itemCode: '9900003',
        shortCode: 'SM+ 500',
        category: 'Milk',
        unit: 'ml',
        packSize: 500,
        packSizeDisplay: '500 ml',
        piecesPerCrate: 20,
        perCrateQty: 10.0,
        perCrateQtyGrams: 10000.0,
        perCrateDisplay: '10.0 L (10000.0 ml)',
        pricePerPiece: 26.0,
        shelfLife: '2 Days',
        allowedInputModes: ['Pieces', 'Crates', 'Litres'],
        targetFat: 3.0,
        targetSnf: 8.5,
      ),
      // 4. Sweet Curd Cup 80g (S80)
      const ProductModel(
        productId: 'S80',
        productName: 'Sweet Curd Cup 80g (S80)',
        itemCode: '9900025',
        shortCode: 'S80',
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
        targetFat: 3.5,
        targetSnf: 10.0,
      ),
      // 5. Sweet Curd Cup 200g (S200)
      const ProductModel(
        productId: 'S200',
        productName: 'Sweet Curd Cup 200g (S200)',
        itemCode: '9900011',
        shortCode: 'S200',
        category: 'Curd',
        unit: 'g',
        packSize: 200,
        packSizeDisplay: '200 g',
        piecesPerCrate: 30,
        perCrateQty: 6.0,
        perCrateQtyGrams: 6000.0,
        perCrateDisplay: '6.0 kg (6000.0 g)',
        pricePerPiece: 30.0,
        shelfLife: '12 Days',
        allowedInputModes: ['Pieces', 'Crates', 'Kg'],
        targetFat: 3.5,
        targetSnf: 10.0,
      ),
      // 6. Sweet Curd Cup 400g (S400)
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
      // 7. Plain Curd Cup 80g (P80)
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
      // 8. Plain Curd Cup 200g (P200)
      const ProductModel(
        productId: 'P200',
        productName: 'Plain Curd Cup 200g (P200)',
        itemCode: 'NA',
        shortCode: 'P200',
        category: 'Curd',
        unit: 'g',
        packSize: 200,
        packSizeDisplay: '200 g',
        piecesPerCrate: 30,
        perCrateQty: 6.0,
        perCrateQtyGrams: 6000.0,
        perCrateDisplay: '6.0 kg (6000.0 g)',
        pricePerPiece: 30.0,
        shelfLife: '12 Days',
        allowedInputModes: ['Pieces', 'Crates', 'Kg'],
        targetFat: 3.2,
        targetSnf: 9.0,
      ),
      // 9. Plain Curd Cup 400g (P400)
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
      // 10. Purabi Lassi 200 ml (PL200)
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
      // 11. Curd Pouch 400 g (CP400)
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
      // 12. Curd Pouch 1 kg (CP1000)
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
        productId: 'CP400',
        productName: 'Curd Pouch 400 g',
        category: 'Curd',
        pieces: 1800,
        crates: 60,
        volumeLitres: 720,
        unit: 'Kg',
        minThresholdLitres: 200,
        lastUpdated: now,
      ),
      StockRecord(
        productId: 'CP1000',
        productName: 'Curd Pouch 1 kg',
        category: 'Curd',
        pieces: 1200,
        crates: 100,
        volumeLitres: 1200,
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

  // ===========================================================================
  // DAILY BATCH MAKING RECORDS
  // ===========================================================================

  static Future<List<BatchRecordModel>> getBatchRecords() async {
    final prefs = await _instance;
    final jsonStr = prefs.getString(AppConstants.storageKeyBatchRecords);
    if (jsonStr == null || jsonStr.isEmpty) {
      await _seedInitialBatchRecords(prefs);
      final seededStr = prefs.getString(AppConstants.storageKeyBatchRecords);
      if (seededStr == null || seededStr.isEmpty) return [];
      try {
        final List<dynamic> list = jsonDecode(seededStr);
        return list.map((e) => BatchRecordModel.fromJson(e as Map<String, dynamic>)).toList();
      } catch (_) {
        return [];
      }
    }
    try {
      final List<dynamic> list = jsonDecode(jsonStr);
      return list.map((e) => BatchRecordModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveBatchRecords(List<BatchRecordModel> records) async {
    final prefs = await _instance;
    final jsonStr = jsonEncode(records.map((e) => e.toJson()).toList());
    await prefs.setString(AppConstants.storageKeyBatchRecords, jsonStr);
  }

  static Future<void> addBatchRecord(BatchRecordModel record) async {
    final list = await getBatchRecords();
    list.insert(0, record);
    await saveBatchRecords(list);
  }

  static Future<void> updateBatchRecord(BatchRecordModel record) async {
    final list = await getBatchRecords();
    final index = list.indexWhere((b) => b.id == record.id);
    if (index >= 0) {
      list[index] = record;
    } else {
      list.insert(0, record);
    }
    await saveBatchRecords(list);
  }

  static Future<void> deleteBatchRecord(String id) async {
    final list = await getBatchRecords();
    list.removeWhere((b) => b.id == id);
    await saveBatchRecords(list);
  }

  static Future<void> _seedInitialBatchRecords(SharedPreferences prefs) async {
    final now = DateTime.now();
    final initialBatches = [
      BatchRecordModel(
        id: 'BATCH-20260928-01',
        productionDate: '2026-09-28',
        productId: 'LASSI',
        productName: 'Lassi',
        batchNumber: 'BT-20260928-01',
        batchQuantity: 500.0,
        batchUnit: 'L',
        shift: 'Shift A (06:00 - 14:00)',
        operatorName: 'R. K. Baruah',
        notes: 'Standard sweet lassi formulation batch 1',
        ingredients: const [
          BatchIngredientModel(id: 'ING-01', batchId: 'BATCH-20260928-01', ingredientName: 'Milk', quantity: 300.0, unit: 'L'),
          BatchIngredientModel(id: 'ING-02', batchId: 'BATCH-20260928-01', ingredientName: 'Water', quantity: 200.0, unit: 'L'),
          BatchIngredientModel(id: 'ING-03', batchId: 'BATCH-20260928-01', ingredientName: 'SMP', quantity: 29.0, unit: 'kg'),
          BatchIngredientModel(id: 'ING-04', batchId: 'BATCH-20260928-01', ingredientName: 'Sugar', quantity: 46.0, unit: 'kg'),
        ],
        createdAt: now.subtract(const Duration(hours: 4)),
        updatedAt: now.subtract(const Duration(hours: 4)),
      ),
      BatchRecordModel(
        id: 'BATCH-20260928-02',
        productionDate: '2026-09-28',
        productId: 'CURD',
        productName: 'Curd',
        batchNumber: 'BT-20260928-02',
        batchQuantity: 1000.0,
        batchUnit: 'L',
        shift: 'Shift A (06:00 - 14:00)',
        operatorName: 'R. K. Baruah',
        notes: 'Plain curd bulk vat incubation',
        ingredients: const [
          BatchIngredientModel(id: 'ING-05', batchId: 'BATCH-20260928-02', ingredientName: 'Milk', quantity: 1000.0, unit: 'L'),
        ],
        createdAt: now.subtract(const Duration(hours: 3)),
        updatedAt: now.subtract(const Duration(hours: 3)),
      ),
      BatchRecordModel(
        id: 'BATCH-20260928-03',
        productionDate: '2026-09-28',
        productId: 'LASSI',
        productName: 'Lassi',
        batchNumber: 'BT-20260928-03',
        batchQuantity: 1000.0,
        batchUnit: 'L',
        shift: 'Shift B (14:00 - 22:00)',
        operatorName: 'M. Hazarika',
        notes: 'Standard sweet lassi second shift batch',
        ingredients: const [
          BatchIngredientModel(id: 'ING-06', batchId: 'BATCH-20260928-03', ingredientName: 'Milk', quantity: 500.0, unit: 'L'),
          BatchIngredientModel(id: 'ING-07', batchId: 'BATCH-20260928-03', ingredientName: 'Water', quantity: 200.0, unit: 'L'),
          BatchIngredientModel(id: 'ING-08', batchId: 'BATCH-20260928-03', ingredientName: 'SMP', quantity: 29.0, unit: 'kg'),
          BatchIngredientModel(id: 'ING-09', batchId: 'BATCH-20260928-03', ingredientName: 'Sugar', quantity: 46.0, unit: 'kg'),
        ],
        createdAt: now.subtract(const Duration(hours: 1)),
        updatedAt: now.subtract(const Duration(hours: 1)),
      ),
      BatchRecordModel(
        id: 'BATCH-20260929-01',
        productionDate: '2026-09-29',
        productId: 'MILK_POUCH',
        productName: 'Milk Pouch',
        batchNumber: 'BT-20260929-01',
        batchQuantity: 2000.0,
        batchUnit: 'L',
        shift: 'Shift A (06:00 - 14:00)',
        operatorName: 'D. Kalita',
        notes: 'Pasteurized standardized milk pouch batch',
        ingredients: const [
          BatchIngredientModel(id: 'ING-10', batchId: 'BATCH-20260929-01', ingredientName: 'Milk', quantity: 2000.0, unit: 'L'),
        ],
        createdAt: now,
        updatedAt: now,
      ),
      BatchRecordModel(
        id: 'BATCH-20260929-02',
        productionDate: '2026-09-29',
        productId: 'LASSI',
        productName: 'Lassi',
        batchNumber: 'BT-20260929-02',
        batchQuantity: 500.0,
        batchUnit: 'L',
        shift: 'Shift A (06:00 - 14:00)',
        operatorName: 'R. K. Baruah',
        notes: 'Morning sweet lassi production',
        ingredients: const [
          BatchIngredientModel(id: 'ING-11', batchId: 'BATCH-20260929-02', ingredientName: 'Milk', quantity: 300.0, unit: 'L'),
          BatchIngredientModel(id: 'ING-12', batchId: 'BATCH-20260929-02', ingredientName: 'Water', quantity: 200.0, unit: 'L'),
          BatchIngredientModel(id: 'ING-13', batchId: 'BATCH-20260929-02', ingredientName: 'SMP', quantity: 29.0, unit: 'kg'),
          BatchIngredientModel(id: 'ING-14', batchId: 'BATCH-20260929-02', ingredientName: 'Sugar', quantity: 46.0, unit: 'kg'),
        ],
        createdAt: now,
        updatedAt: now,
      ),
    ];

    await prefs.setString(
      AppConstants.storageKeyBatchRecords,
      jsonEncode(initialBatches.map((e) => e.toJson()).toList()),
    );
  }
}
