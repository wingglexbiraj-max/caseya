import '../models/boiler_record.dart';
import '../services/api_service.dart';
import '../services/local_storage_service.dart';

class BoilerRepository {
  Future<List<BoilerRecord>> getRecords() async {
    return ApiService.fetchBoilerRecords();
  }

  Future<void> saveRecord(BoilerRecord record) async {
    await ApiService.saveBoilerRecord(record);
  }

  Future<void> updateRecord(BoilerRecord record) async {
    await LocalStorageService.updateBoilerRecord(record);
  }

  Future<void> deleteRecord(String recordId) async {
    await LocalStorageService.deleteBoilerRecord(recordId);
  }
}
