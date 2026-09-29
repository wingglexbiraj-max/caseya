import '../models/dg_hsd_record.dart';
import '../services/local_storage_service.dart';

class DgHsdRepository {
  Future<List<DgHsdRecord>> getRecords() async {
    return LocalStorageService.getDgHsdRecords();
  }

  Future<void> saveRecord(DgHsdRecord record) async {
    await LocalStorageService.addDgHsdRecord(record);
  }

  Future<void> updateRecord(DgHsdRecord record) async {
    await LocalStorageService.updateDgHsdRecord(record);
  }

  Future<void> deleteRecord(String recordId) async {
    await LocalStorageService.deleteDgHsdRecord(recordId);
  }
}
