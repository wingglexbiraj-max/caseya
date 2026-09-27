import '../models/standardization_record.dart';
import '../models/product_calculation_record.dart';
import '../services/api_service.dart';
import '../services/local_storage_service.dart';

class StandardizationRepository {
  Future<List<StandardizationRecord>> getRecords() async {
    return ApiService.fetchStandardizationRecords();
  }

  Future<void> saveRecord(StandardizationRecord record) async {
    await ApiService.saveStandardizationRecord(record);
  }

  Future<void> deleteRecord(String recordId) async {
    await LocalStorageService.deleteStandardizationRecord(recordId);
  }

  Future<List<ProductCalculationRecord>> getProductCalcRecords() async {
    return LocalStorageService.getProductCalcRecords();
  }

  Future<void> saveProductCalcRecord(ProductCalculationRecord record) async {
    await LocalStorageService.addProductCalcRecord(record);
  }
}
