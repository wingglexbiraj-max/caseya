import '../models/dg_hsd_record.dart';
import '../services/api_service.dart';

class DgHsdRepository {
  Future<List<DgHsdRecord>> getRecords() async {
    return ApiService.fetchDgHsdRecords();
  }

  Future<void> saveRecord(DgHsdRecord record) async {
    await ApiService.saveDgHsdRecord(record);
  }

  Future<void> updateRecord(DgHsdRecord record) async {
    await ApiService.updateDgHsdRecord(record);
  }

  Future<void> deleteRecord(String recordId) async {
    await ApiService.deleteDgHsdRecord(recordId);
  }
}
