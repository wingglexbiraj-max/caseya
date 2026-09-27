import '../models/lab_record.dart';
import '../services/api_service.dart';

class LabRepository {
  Future<LabRecord?> getTodayLabData(String date) async {
    return ApiService.fetchTodayLabData(date);
  }
}
