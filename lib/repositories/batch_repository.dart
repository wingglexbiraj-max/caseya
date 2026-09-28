import '../models/batch_record_model.dart';
import '../services/local_storage_service.dart';

class BatchRepository {
  Future<List<BatchRecordModel>> getBatches() async {
    return LocalStorageService.getBatchRecords();
  }

  Future<void> addBatch(BatchRecordModel batch) async {
    await LocalStorageService.addBatchRecord(batch);
  }

  Future<void> updateBatch(BatchRecordModel batch) async {
    await LocalStorageService.updateBatchRecord(batch);
  }

  Future<void> deleteBatch(String id) async {
    await LocalStorageService.deleteBatchRecord(id);
  }
}
