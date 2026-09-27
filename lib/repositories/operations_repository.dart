import '../models/operations_models.dart';
import '../services/local_storage_service.dart';

class OperationsRepository {
  Future<List<StockRecord>> getStockRecords() async {
    return LocalStorageService.getStockRecords();
  }
}
