import '../models/boiler_record.dart';
import '../services/api_service.dart';

class BoilerRepository {
  Future<List<BoilerRecord>> getRecords() async {
    return ApiService.fetchBoilerRecords();
  }

  Future<void> saveRecord(BoilerRecord record) async {
    await ApiService.saveBoilerRecord(record);
  }

  Future<void> updateRecord(BoilerRecord record) async {
    await ApiService.updateBoilerRecord(record);
  }

  Future<void> deleteRecord(String recordId) async {
    await ApiService.deleteBoilerRecord(recordId);
  }
}
