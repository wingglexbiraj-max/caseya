import '../models/lab_milk_test.dart';
import '../models/silo_model.dart';
import '../services/local_storage_service.dart';

class LabMilkTestRepository {
  Future<List<SiloModel>> getSilos() async {
    return LocalStorageService.getSilos();
  }

  Future<void> addSilo(SiloModel silo) async {
    await LocalStorageService.addSilo(silo);
  }

  Future<List<LabMilkTest>> getTests() async {
    return LocalStorageService.getLabMilkTests();
  }

  Future<void> saveTest(LabMilkTest test) async {
    await LocalStorageService.addLabMilkTest(test);
  }

  Future<void> updateTest(LabMilkTest test) async {
    await LocalStorageService.updateLabMilkTest(test);
  }

  Future<void> deleteTest(String testId) async {
    await LocalStorageService.deleteLabMilkTest(testId);
  }

  Future<LabMilkTest?> getLatestReadingForSilo(String siloId, {String? todayDateStr}) async {
    return LocalStorageService.getLatestReadingForSilo(siloId, todayDateStr: todayDateStr);
  }

  Future<Map<String, LabMilkTest>> getLatestReadingsBySilo({String? todayDateStr}) async {
    return LocalStorageService.getLatestReadingsBySilo(todayDateStr: todayDateStr);
  }

  Future<Map<String, dynamic>> calculateCurrentSiloStock() async {
    return LocalStorageService.calculateCurrentSiloStock();
  }

  Future<void> recordMilkStock({
    required double pmstLitres,
    required double rmstLitres,
    String? notes,
    String? recordedBy,
  }) async {
    await LocalStorageService.recordMilkStock(
      pmstLitres: pmstLitres,
      rmstLitres: rmstLitres,
      notes: notes,
      recordedBy: recordedBy,
    );
  }
}
