import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';
import '../models/product_model.dart';
import '../models/boiler_record.dart';
import '../models/standardization_record.dart';
import '../models/product_calculation_record.dart';
import '../models/lab_record.dart';
import '../models/user_model.dart';
import '../models/operations_models.dart' hide DispatchItem, DispatchRecord;
import '../models/batch_record_model.dart';
import '../models/dg_hsd_record.dart';
import '../models/silo_model.dart';
import '../models/lab_milk_test.dart';
import '../models/dispatch_record.dart';

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
    if (!prefs.containsKey(AppConstants.storageKeyDgHsdRecords)) {
      await _seedInitialDgHsdRecords(prefs);
    }
    if (!prefs.containsKey(AppConstants.storageKeySilos)) {
      await _seedInitialSilos(prefs);
    }
    if (!prefs.containsKey(AppConstants.storageKeyLabMilkTests)) {
      await _seedInitialLabMilkTests(prefs);
    }
    if (!prefs.containsKey(AppConstants.storageKeyDispatchRecords)) {
      await _seedInitialDispatches(prefs);
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

      // Canonical product definitions matching official plant metadata
      const pp250 = ProductModel(
        productId: '9900095',
        productName: 'Purabi Plus 250 ml (PP250)',
        itemCode: '9900095',
        shortCode: 'PP250',
        category: 'Milk',
        unit: 'ml',
        packSize: 250,
        packSizeDisplay: '250 ml',
        piecesPerCrate: 48,
        perCrateQty: 12.0,
        perCrateQtyGrams: 12000.0,
        perCrateDisplay: '12.0 L (12000.0 ml)',
        pricePerPiece: 18.0,
        shelfLife: '2 Days',
        allowedInputModes: ['Pieces', 'Crates', 'Litres'],
        targetFat: 4.5,
        targetSnf: 8.5,
      );

      const pp500 = ProductModel(
        productId: '9900027',
        productName: 'Purabi Plus 500 ml (PP500)',
        itemCode: '9900027',
        shortCode: 'PP500',
        category: 'Milk',
        unit: 'ml',
        packSize: 500,
        packSizeDisplay: '500 ml',
        piecesPerCrate: 24,
        perCrateQty: 12.0,
        perCrateQtyGrams: 12000.0,
        perCrateDisplay: '12.0 L (12000.0 ml)',
        pricePerPiece: 35.0,
        shelfLife: '2 Days',
        allowedInputModes: ['Pieces', 'Crates', 'Litres'],
        targetFat: 4.5,
        targetSnf: 8.5,
      );

      const smart500 = ProductModel(
        productId: 'SMART500',
        productName: 'Purabi Smart + 500 ml (smart+500)',
        itemCode: 'NA',
        shortCode: 'smart+500',
        category: 'Milk',
        unit: 'ml',
        packSize: 500,
        packSizeDisplay: '500 ml',
        piecesPerCrate: 24,
        perCrateQty: 12.0,
        perCrateQtyGrams: 12000.0,
        perCrateDisplay: '12.0 L (12000.0 ml)',
        pricePerPiece: 0.0,
        priceCustomLabel: 'Defence Supply',
        shelfLife: '2 Days',
        allowedInputModes: ['Pieces', 'Crates', 'Litres'],
        targetFat: 3.0,
        targetSnf: 8.5,
      );

      const s80 = ProductModel(
        productId: '9900025',
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
      );

      const s200 = ProductModel(
        productId: '9900011',
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
      );

      const s400 = ProductModel(
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
      );

      const p80 = ProductModel(
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
      );

      const p400 = ProductModel(
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
      );

      const pl200 = ProductModel(
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
      );

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

      void syncCanonical(ProductModel canonical, List<String> matchIdentifiers) {
        final idx = products.indexWhere((p) =>
            matchIdentifiers.contains(p.productId) ||
            matchIdentifiers.contains(p.shortCode) ||
            matchIdentifiers.contains(p.itemCode));
        if (idx >= 0) {
          final curr = products[idx];
          if (curr.piecesPerCrate != canonical.piecesPerCrate ||
              curr.pricePerPiece != canonical.pricePerPiece ||
              curr.priceCustomLabel != canonical.priceCustomLabel ||
              curr.perCrateQty != canonical.perCrateQty ||
              curr.itemCode != canonical.itemCode ||
              curr.shortCode != canonical.shortCode ||
              curr.shelfLife != canonical.shelfLife ||
              curr.productName != canonical.productName) {
            products[idx] = canonical;
            needsResave = true;
          }
        } else {
          products.add(canonical);
          needsResave = true;
        }
      }

      syncCanonical(pp250, ['9900095', 'PP250', 'STD250', 'STD 250', '9900002']);
      syncCanonical(pp500, ['9900027', 'PP500', 'STD500', 'STD 500', '9900001']);
      syncCanonical(smart500, ['SMART500', 'smart+500', 'SM500', 'SM+ 500', '9900003']);
      syncCanonical(s80, ['9900025', 'S80']);
      syncCanonical(s200, ['9900011', 'S200']);
      syncCanonical(s400, ['9900010', 'S400']);
      syncCanonical(p80, ['9900026', 'P80']);
      syncCanonical(p400, ['9900013', 'P400']);
      syncCanonical(pl200, ['9900007', 'PL200']);
      syncCanonical(cp400, ['CP400']);
      syncCanonical(cp1000, ['CP1000']);
      syncCanonical(p200, ['P200']);

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

  static const String storageKeyStdConfig = 'caseya_std_formula_config_v4';

  static Future<Map<String, dynamic>> getStandardizationConfig() async {
    final prefs = await _instance;
    final jsonStr = prefs.getString(storageKeyStdConfig);
    if (jsonStr == null || jsonStr.isEmpty) {
      return {
        'smp_factor': 95.0,
        'water_method': 'standard',
        'product_specs': {
          'STD_MILK': {'target_snf': 8.5, 'sugar_percent': 0.0, 'target_fat': 4.5},
          'ARMY_MILK': {'target_snf': 8.5, 'sugar_percent': 0.0, 'target_fat': 3.5},
          'PLAIN_CURD_CUP': {'target_snf': 14.0, 'sugar_percent': 0.0, 'target_fat': 3.0},
          'PLAIN_CURD_POUCH': {'target_snf': 11.0, 'sugar_percent': 0.0, 'target_fat': 3.0},
          'SWEET_CURD': {'target_snf': 14.0, 'sugar_percent': 12.0, 'target_fat': 3.0},
          'LASSI': {'target_snf': 7.0, 'sugar_percent': 15.0, 'target_fat': 1.5},
        }
      };
    }
    try {
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (_) {
      return {'smp_factor': 95.0, 'water_method': 'standard'};
    }
  }

  static Future<void> saveStandardizationConfig(Map<String, dynamic> config) async {
    final prefs = await _instance;
    await prefs.setString(storageKeyStdConfig, jsonEncode(config));
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
        final user = UserModel.fromJson(jsonDecode(jsonStr));
        if (user.name == 'R. K. Baruah' || user.name.isEmpty) {
          final updated = UserModel(
            userId: user.userId.isEmpty ? 'EMP-0101' : user.userId,
            employeeCode: user.employeeCode.isEmpty ? 'ADMIN-01' : user.employeeCode,
            name: 'Biraj Goswami',
            email: 'biraj.goswami@caseya-plant.com',
            role: user.role,
            department: user.department,
            active: true,
          );
          await saveCurrentUser(updated);
          return updated;
        }
        return user;
      } catch (_) {}
    }
    return const UserModel(
      userId: 'EMP-0101',
      employeeCode: 'ADMIN-01',
      name: 'Biraj Goswami',
      email: 'biraj.goswami@caseya-plant.com',
      role: 'Admin',
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
      // 1. Purabi Plus 500 ml (PP500)
      const ProductModel(
        productId: '9900027',
        productName: 'Purabi Plus 500 ml (PP500)',
        itemCode: '9900027',
        shortCode: 'PP500',
        category: 'Milk',
        unit: 'ml',
        packSize: 500,
        packSizeDisplay: '500 ml',
        piecesPerCrate: 24,
        perCrateQty: 12.0,
        perCrateQtyGrams: 12000.0,
        perCrateDisplay: '12.0 L (12000.0 ml)',
        pricePerPiece: 35.0,
        shelfLife: '2 Days',
        allowedInputModes: ['Pieces', 'Crates', 'Litres'],
        targetFat: 4.5,
        targetSnf: 8.5,
      ),
      // 2. Purabi Plus 250 ml (PP250)
      const ProductModel(
        productId: '9900095',
        productName: 'Purabi Plus 250 ml (PP250)',
        itemCode: '9900095',
        shortCode: 'PP250',
        category: 'Milk',
        unit: 'ml',
        packSize: 250,
        packSizeDisplay: '250 ml',
        piecesPerCrate: 48,
        perCrateQty: 12.0,
        perCrateQtyGrams: 12000.0,
        perCrateDisplay: '12.0 L (12000.0 ml)',
        pricePerPiece: 18.0,
        shelfLife: '2 Days',
        allowedInputModes: ['Pieces', 'Crates', 'Litres'],
        targetFat: 4.5,
        targetSnf: 8.5,
      ),
      // 3. Purabi Smart + 500 ml (smart+500)
      const ProductModel(
        productId: 'SMART500',
        productName: 'Purabi Smart + 500 ml (smart+500)',
        itemCode: 'NA',
        shortCode: 'smart+500',
        category: 'Milk',
        unit: 'ml',
        packSize: 500,
        packSizeDisplay: '500 ml',
        piecesPerCrate: 24,
        perCrateQty: 12.0,
        perCrateQtyGrams: 12000.0,
        perCrateDisplay: '12.0 L (12000.0 ml)',
        pricePerPiece: 0.0,
        priceCustomLabel: 'Defence Supply',
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
        employeeId: 'EMP-0101',
        employeeName: 'Biraj Goswami',
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
        employeeId: 'EMP-0101',
        employeeName: 'Biraj Goswami',
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
        employeeId: 'EMP-0101',
        employeeName: 'Biraj Goswami',
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
        crates: 175,
        volumeLitres: 2100,
        unit: 'Litres',
        minThresholdLitres: 500,
        lastUpdated: now,
      ),
      StockRecord(
        productId: 'PRD-002',
        productName: 'Purabi Plus Milk 250 ml (PP250)',
        category: 'Milk',
        pieces: 3600,
        crates: 75,
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
        operatorName: 'Biraj Goswami',
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
        operatorName: 'Biraj Goswami',
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
        operatorName: 'Biraj Goswami',
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

  // ===========================================================================
  // DG HSD FUEL RECORDS
  // ===========================================================================

  static Future<List<DgHsdRecord>> getDgHsdRecords() async {
    final prefs = await _instance;
    final jsonStr = prefs.getString(AppConstants.storageKeyDgHsdRecords);
    if (jsonStr == null || jsonStr.isEmpty) return [];
    try {
      final List<dynamic> list = jsonDecode(jsonStr);
      final records = list.map((e) => DgHsdRecord.fromJson(e as Map<String, dynamic>)).toList();
      records.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return records;
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveDgHsdRecords(List<DgHsdRecord> records) async {
    final prefs = await _instance;
    final jsonStr = jsonEncode(records.map((e) => e.toJson()).toList());
    await prefs.setString(AppConstants.storageKeyDgHsdRecords, jsonStr);
  }

  static Future<void> addDgHsdRecord(DgHsdRecord record) async {
    final records = await getDgHsdRecords();
    records.insert(0, record);
    await saveDgHsdRecords(records);
  }

  static Future<void> updateDgHsdRecord(DgHsdRecord record) async {
    final records = await getDgHsdRecords();
    final index = records.indexWhere((r) => r.recordId == record.recordId);
    if (index >= 0) {
      records[index] = record;
      await saveDgHsdRecords(records);
    }
  }

  static Future<void> deleteDgHsdRecord(String recordId) async {
    final records = await getDgHsdRecords();
    records.removeWhere((r) => r.recordId == recordId);
    await saveDgHsdRecords(records);
  }

  static Future<void> _seedInitialDgHsdRecords(SharedPreferences prefs) async {
    final now = DateTime.now();
    final initialRecords = [
      DgHsdRecord(
        recordId: 'DG-20260928-A',
        date: '2026-09-28',
        time: '02:00 PM',
        shift: 'Shift A (06:00 - 14:00)',
        employeeId: 'EMP-001',
        employeeName: 'Biraj Goswami',
        fuelAdded: 200.0,
        startPercentage: 85.0,
        endPercentage: 62.0,
        percentageDrop: 23.0,
        fuelConsumption: 75.0,
        kwh: 260.0,
        runningHours: 4.5,
        consumptionPerHour: 16.67,
        unitsPerLitre: 3.47,
        remarks: 'DG operated smoothly during peak pasteurizer operation',
        createdAt: now.subtract(const Duration(hours: 18)),
        updatedAt: now.subtract(const Duration(hours: 18)),
      ),
      DgHsdRecord(
        recordId: 'DG-20260927-B',
        date: '2026-09-27',
        time: '10:00 PM',
        shift: 'Shift B (14:00 - 22:00)',
        employeeId: 'EMP-002',
        employeeName: 'M. Hazarika',
        fuelAdded: 0.0,
        startPercentage: 62.0,
        endPercentage: 48.0,
        percentageDrop: 14.0,
        fuelConsumption: 48.0,
        kwh: 165.0,
        runningHours: 3.0,
        consumptionPerHour: 16.0,
        unitsPerLitre: 3.44,
        remarks: 'Power grid cut from 17:30 to 20:30; cold room backup sustained',
        createdAt: now.subtract(const Duration(hours: 38)),
        updatedAt: now.subtract(const Duration(hours: 38)),
      ),
    ];

    await prefs.setString(
      AppConstants.storageKeyDgHsdRecords,
      jsonEncode(initialRecords.map((e) => e.toJson()).toList()),
    );
  }

  // ===========================================================================
  // SILOS MASTER
  // ===========================================================================

  static Future<List<SiloModel>> getSilos() async {
    final prefs = await _instance;
    final jsonStr = prefs.getString(AppConstants.storageKeySilos);
    if (jsonStr == null || jsonStr.isEmpty) {
      await _seedInitialSilos(prefs);
      return SiloModel.defaultSilos;
    }
    try {
      final List<dynamic> list = jsonDecode(jsonStr);
      return list.map((e) => SiloModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return SiloModel.defaultSilos;
    }
  }

  static Future<void> saveSilos(List<SiloModel> silos) async {
    final prefs = await _instance;
    final jsonStr = jsonEncode(silos.map((e) => e.toJson()).toList());
    await prefs.setString(AppConstants.storageKeySilos, jsonStr);
  }

  static Future<void> addSilo(SiloModel silo) async {
    final list = await getSilos();
    list.add(silo);
    await saveSilos(list);
  }

  static Future<void> _seedInitialSilos(SharedPreferences prefs) async {
    final jsonStr = jsonEncode(SiloModel.defaultSilos.map((e) => e.toJson()).toList());
    await prefs.setString(AppConstants.storageKeySilos, jsonStr);
  }

  // ===========================================================================
  // LAB MILK TESTS (FAT & SNF)
  // ===========================================================================

  static Future<List<LabMilkTest>> getLabMilkTests() async {
    final prefs = await _instance;
    final jsonStr = prefs.getString(AppConstants.storageKeyLabMilkTests);
    if (jsonStr == null || jsonStr.isEmpty) return [];
    try {
      final List<dynamic> list = jsonDecode(jsonStr);
      final records = list.map((e) => LabMilkTest.fromJson(e as Map<String, dynamic>)).toList();
      records.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return records;
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveLabMilkTests(List<LabMilkTest> records) async {
    final prefs = await _instance;
    final jsonStr = jsonEncode(records.map((e) => e.toJson()).toList());
    await prefs.setString(AppConstants.storageKeyLabMilkTests, jsonStr);
  }

  static Future<void> addLabMilkTest(LabMilkTest record) async {
    final records = await getLabMilkTests();
    records.insert(0, record);
    await saveLabMilkTests(records);
  }

  static Future<void> updateLabMilkTest(LabMilkTest record) async {
    final records = await getLabMilkTests();
    final index = records.indexWhere((r) => r.id == record.id);
    if (index >= 0) {
      records[index] = record;
      await saveLabMilkTests(records);
    }
  }

  static Future<void> deleteLabMilkTest(String recordId) async {
    final records = await getLabMilkTests();
    records.removeWhere((r) => r.id == recordId);
    await saveLabMilkTests(records);
  }

  /// Get the latest valid lab reading for a specific silo.
  /// If [todayDateStr] is provided (YYYY-MM-DD), only returns today's latest reading.
  /// If null, returns the most recent recorded reading overall for that silo.
  static Future<LabMilkTest?> getLatestReadingForSilo(String siloId, {String? todayDateStr}) async {
    final records = await getLabMilkTests();
    final matching = records.where((r) {
      if (r.siloId != siloId) return false;
      if (todayDateStr != null && r.testDate != todayDateStr) return false;
      return true;
    }).toList();

    if (matching.isEmpty) return null;
    matching.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return matching.first;
  }

  /// Get a map of latest readings for all silos for a given date (defaults to today).
  static Future<Map<String, LabMilkTest>> getLatestReadingsBySilo({String? todayDateStr}) async {
    final records = await getLabMilkTests();
    final Map<String, LabMilkTest> map = {};

    for (final r in records) {
      if (todayDateStr != null && r.testDate != todayDateStr) continue;
      if (!map.containsKey(r.siloId)) {
        map[r.siloId] = r;
      }
    }
    return map;
  }

  static Future<void> _seedInitialLabMilkTests(SharedPreferences prefs) async {
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final initialTests = [
      LabMilkTest(
        id: 'LAB-${now.millisecondsSinceEpoch}-01',
        testDate: todayStr,
        testTime: '08:35 AM',
        siloId: 'PMST',
        siloName: 'PMST',
        fatPercentage: 4.30,
        snfPercentage: 8.33,
        labUserId: 'LAB-01',
        labUserName: 'Lab User',
        remarks: 'Morning pasteurized milk tank sample approved',
        createdAt: now.subtract(const Duration(minutes: 45)),
        updatedAt: now.subtract(const Duration(minutes: 45)),
      ),
      LabMilkTest(
        id: 'LAB-${now.millisecondsSinceEpoch}-02',
        testDate: todayStr,
        testTime: '08:20 AM',
        siloId: 'RMST',
        siloName: 'RMST',
        fatPercentage: 4.20,
        snfPercentage: 8.31,
        labUserId: 'LAB-01',
        labUserName: 'Lab User',
        remarks: 'Reception raw milk reception composite sample',
        createdAt: now.subtract(const Duration(hours: 1)),
        updatedAt: now.subtract(const Duration(hours: 1)),
      ),
    ];

    await prefs.setString(
      AppConstants.storageKeyLabMilkTests,
      jsonEncode(initialTests.map((e) => e.toJson()).toList()),
    );
  }

  // ===========================================================================
  // DISPATCH RECORDS (VEHICLE-WISE PLANT DISPATCH)
  // ===========================================================================

  static Future<List<VehicleDispatch>> getDispatches() async {
    final prefs = await _instance;
    final jsonStr = prefs.getString(AppConstants.storageKeyDispatchRecords);
    if (jsonStr == null || jsonStr.isEmpty) {
      await _seedInitialDispatches(prefs);
      final seeded = prefs.getString(AppConstants.storageKeyDispatchRecords);
      if (seeded == null || seeded.isEmpty) return [];
      final List<dynamic> list = jsonDecode(seeded);
      return list.map((e) => VehicleDispatch.fromJson(e as Map<String, dynamic>)).toList();
    }
    try {
      final List<dynamic> list = jsonDecode(jsonStr);
      final records = list.map((e) => VehicleDispatch.fromJson(e as Map<String, dynamic>)).toList();
      records.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return records;
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveDispatches(List<VehicleDispatch> records) async {
    final prefs = await _instance;
    final jsonStr = jsonEncode(records.map((e) => e.toJson()).toList());
    await prefs.setString(AppConstants.storageKeyDispatchRecords, jsonStr);
  }

  static Future<void> addDispatch(VehicleDispatch record) async {
    final records = await getDispatches();
    records.insert(0, record);
    await saveDispatches(records);
  }

  static Future<void> updateDispatch(VehicleDispatch record) async {
    final records = await getDispatches();
    final index = records.indexWhere((r) => r.id == record.id);
    if (index >= 0) {
      records[index] = record;
      await saveDispatches(records);
    }
  }

  static Future<void> deleteDispatch(String recordId) async {
    final records = await getDispatches();
    records.removeWhere((r) => r.id == recordId);
    await saveDispatches(records);
  }

  static Future<List<VehicleDispatch>> getDispatchesByDate(String dateStr) async {
    final records = await getDispatches();
    return records.where((r) => r.dispatchDate == dateStr).toList();
  }

  static Future<void> _seedInitialDispatches(SharedPreferences prefs) async {
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final yesterday = now.subtract(const Duration(days: 1));
    final yesterdayStr = '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';

    final initialDispatches = [
      // Today: Vehicle 1 - Distributor A (AS01AB1234)
      VehicleDispatch(
        id: 'DISP-${now.millisecondsSinceEpoch}-01',
        dispatchDate: todayStr,
        distributorName: 'Distributor A',
        vehicleNumber: 'AS01AB1234',
        driverName: 'Ramesh Sharma',
        route: 'Route 01 - Guwahati Central',
        dispatchTime: '08:35 AM',
        remarks: 'Morning dispatch batch completed on schedule',
        createdBy: 'Dispatch Officer',
        createdAt: now.subtract(const Duration(hours: 3)),
        updatedAt: now.subtract(const Duration(hours: 3)),
        items: [
          DispatchItem(
            id: 'ITEM-${now.millisecondsSinceEpoch}-01',
            dispatchId: 'DISP-${now.millisecondsSinceEpoch}-01',
            productId: '9900007',
            productName: 'Purabi Lassi 200 ml (PL200)',
            shortCode: 'PL200',
            itemCode: '9900007',
            inputMode: 'Crates',
            inputQuantity: 10.0,
            crates: 10.0,
            pieces: 300,
            normalizedQuantity: 60.0,
            normalizedUnit: 'Litres',
            packSize: 200.0,
            packSizeDisplay: '200 ml',
            piecesPerCrate: 30,
            createdAt: now.subtract(const Duration(hours: 3)),
          ),
          DispatchItem(
            id: 'ITEM-${now.millisecondsSinceEpoch}-02',
            dispatchId: 'DISP-${now.millisecondsSinceEpoch}-01',
            productId: '9900095',
            productName: 'Purabi Plus 250 ml (PP250)',
            shortCode: 'PP250',
            itemCode: '9900095',
            inputMode: 'Crates',
            inputQuantity: 20.0,
            crates: 20.0,
            pieces: 960,
            normalizedQuantity: 240.0,
            normalizedUnit: 'Litres',
            packSize: 250.0,
            packSizeDisplay: '250 ml',
            piecesPerCrate: 48,
            createdAt: now.subtract(const Duration(hours: 3)),
          ),
          DispatchItem(
            id: 'ITEM-${now.millisecondsSinceEpoch}-03',
            dispatchId: 'DISP-${now.millisecondsSinceEpoch}-01',
            productId: '9900026',
            productName: 'Sweet Curd Cup 400g (S400)',
            shortCode: 'S400',
            itemCode: '9900026',
            inputMode: 'Crates',
            inputQuantity: 5.0,
            crates: 5.0,
            pieces: 75,
            normalizedQuantity: 30.0,
            normalizedUnit: 'Kg',
            packSize: 400.0,
            packSizeDisplay: '400 g',
            piecesPerCrate: 15,
            createdAt: now.subtract(const Duration(hours: 3)),
          ),
        ],
      ),

      // Today: Vehicle 2 - Distributor B (AS02CD5678)
      VehicleDispatch(
        id: 'DISP-${now.millisecondsSinceEpoch}-02',
        dispatchDate: todayStr,
        distributorName: 'Distributor B',
        vehicleNumber: 'AS02CD5678',
        driverName: 'Bikash Kalita',
        route: 'Route 04 - Dispur & Beltola',
        dispatchTime: '09:15 AM',
        remarks: 'Cold chain vehicle pre-cooled to 4°C',
        createdBy: 'Dispatch Officer',
        createdAt: now.subtract(const Duration(hours: 2)),
        updatedAt: now.subtract(const Duration(hours: 2)),
        items: [
          DispatchItem(
            id: 'ITEM-${now.millisecondsSinceEpoch}-04',
            dispatchId: 'DISP-${now.millisecondsSinceEpoch}-02',
            productId: '9900007',
            productName: 'Purabi Lassi 200 ml (PL200)',
            shortCode: 'PL200',
            itemCode: '9900007',
            inputMode: 'Crates',
            inputQuantity: 15.0,
            crates: 15.0,
            pieces: 450,
            normalizedQuantity: 90.0,
            normalizedUnit: 'Litres',
            packSize: 200.0,
            packSizeDisplay: '200 ml',
            piecesPerCrate: 30,
            createdAt: now.subtract(const Duration(hours: 2)),
          ),
          DispatchItem(
            id: 'ITEM-${now.millisecondsSinceEpoch}-05',
            dispatchId: 'DISP-${now.millisecondsSinceEpoch}-02',
            productId: '9900010',
            productName: 'Plain Curd Cup 400g (P400)',
            shortCode: 'P400',
            itemCode: '9900010',
            inputMode: 'Crates',
            inputQuantity: 10.0,
            crates: 10.0,
            pieces: 150,
            normalizedQuantity: 60.0,
            normalizedUnit: 'Kg',
            packSize: 400.0,
            packSizeDisplay: '400 g',
            piecesPerCrate: 15,
            createdAt: now.subtract(const Duration(hours: 2)),
          ),
        ],
      ),

      // Yesterday: Sample Dispatch
      VehicleDispatch(
        id: 'DISP-${yesterday.millisecondsSinceEpoch}-03',
        dispatchDate: yesterdayStr,
        distributorName: 'Distributor A',
        vehicleNumber: 'AS01AB1234',
        driverName: 'Ramesh Sharma',
        route: 'Route 01 - Guwahati Central',
        dispatchTime: '08:10 AM',
        remarks: 'Regular daily run',
        createdBy: 'Dispatch Officer',
        createdAt: yesterday.subtract(const Duration(hours: 4)),
        updatedAt: yesterday.subtract(const Duration(hours: 4)),
        items: [
          DispatchItem(
            id: 'ITEM-${yesterday.millisecondsSinceEpoch}-06',
            dispatchId: 'DISP-${yesterday.millisecondsSinceEpoch}-03',
            productId: '9900007',
            productName: 'Purabi Lassi 200 ml (PL200)',
            shortCode: 'PL200',
            itemCode: '9900007',
            inputMode: 'Crates',
            inputQuantity: 12.0,
            crates: 12.0,
            pieces: 360,
            normalizedQuantity: 72.0,
            normalizedUnit: 'Litres',
            packSize: 200.0,
            packSizeDisplay: '200 ml',
            piecesPerCrate: 30,
            createdAt: yesterday.subtract(const Duration(hours: 4)),
          ),
        ],
      ),
    ];

    await prefs.setString(
      AppConstants.storageKeyDispatchRecords,
      jsonEncode(initialDispatches.map((e) => e.toJson()).toList()),
    );
  }
}
