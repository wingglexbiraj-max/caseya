import '../models/operations_models.dart';
import '../models/product_model.dart';
import '../models/standardization_record.dart';
import '../services/local_storage_service.dart';

class ProductionRepository {
  Future<List<ProductionRecord>> getProductionRecords() async {
    return LocalStorageService.getProductionRecords();
  }

  Future<void> addProductionRecord(ProductionRecord record) async {
    await LocalStorageService.addProductionRecord(record);
  }

  Future<void> deleteProductionRecord(String recordId) async {
    await LocalStorageService.deleteProductionRecord(recordId);
  }

  Future<List<ProductModel>> getProducts() async {
    return LocalStorageService.getProducts();
  }

  Future<List<StandardizationRecord>> getStandardizationRecords() async {
    return LocalStorageService.getStandardizationRecords();
  }
}
