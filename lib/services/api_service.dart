import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product_model.dart';
import '../models/boiler_record.dart';
import '../models/standardization_record.dart';
import '../models/lab_record.dart';
import 'local_storage_service.dart';

/// Central API Service for CASEYA
///
/// Communicates with FastAPI backend (`/api/v1/...`).
/// If backend is unreachable or in standalone mode, automatically falls back
/// to LocalStorageService for instantaneous, resilient plant operations.
class ApiService {
  static String baseUrl = 'http://localhost:8000/api/v1';
  static bool useBackend = false; // Toggled in Settings

  static Future<List<ProductModel>> fetchProducts() async {
    if (useBackend) {
      try {
        final res = await http.get(Uri.parse('$baseUrl/products')).timeout(const Duration(seconds: 4));
        if (res.statusCode == 200) {
          final List<dynamic> data = jsonDecode(res.body);
          return data.map((e) => ProductModel.fromJson(e as Map<String, dynamic>)).toList();
        }
      } catch (_) {
        // Fallback to local storage
      }
    }
    return LocalStorageService.getProducts();
  }

  static Future<LabRecord?> fetchTodayLabData(String date) async {
    if (useBackend) {
      try {
        final res = await http.get(Uri.parse('$baseUrl/lab/today?date=$date')).timeout(const Duration(seconds: 4));
        if (res.statusCode == 200) {
          return LabRecord.fromJson(jsonDecode(res.body));
        }
      } catch (_) {}
    }
    return LocalStorageService.getTodayLabRecord(date);
  }

  static Future<List<BoilerRecord>> fetchBoilerRecords() async {
    if (useBackend) {
      try {
        final res = await http.get(Uri.parse('$baseUrl/boiler')).timeout(const Duration(seconds: 4));
        if (res.statusCode == 200) {
          final List<dynamic> data = jsonDecode(res.body);
          return data.map((e) => BoilerRecord.fromJson(e as Map<String, dynamic>)).toList();
        }
      } catch (_) {}
    }
    return LocalStorageService.getBoilerRecords();
  }

  static Future<void> saveBoilerRecord(BoilerRecord record) async {
    await LocalStorageService.addBoilerRecord(record);
    if (useBackend) {
      try {
        await http.post(
          Uri.parse('$baseUrl/boiler'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(record.toJson()),
        ).timeout(const Duration(seconds: 4));
      } catch (_) {}
    }
  }

  static Future<List<StandardizationRecord>> fetchStandardizationRecords() async {
    if (useBackend) {
      try {
        final res = await http.get(Uri.parse('$baseUrl/standardization')).timeout(const Duration(seconds: 4));
        if (res.statusCode == 200) {
          final List<dynamic> data = jsonDecode(res.body);
          return data.map((e) => StandardizationRecord.fromJson(e as Map<String, dynamic>)).toList();
        }
      } catch (_) {}
    }
    return LocalStorageService.getStandardizationRecords();
  }

  static Future<void> saveStandardizationRecord(StandardizationRecord record) async {
    await LocalStorageService.addStandardizationRecord(record);
    if (useBackend) {
      try {
        await http.post(
          Uri.parse('$baseUrl/standardization'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(record.toJson()),
        ).timeout(const Duration(seconds: 4));
      } catch (_) {}
    }
  }
}
