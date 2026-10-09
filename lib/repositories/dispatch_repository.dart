import '../models/dispatch_record.dart';
import '../models/product_model.dart';
import '../services/local_storage_service.dart';
import '../services/supabase_service.dart';

class DispatchRepository {
  Future<List<VehicleDispatch>> getDispatches() async {
    if (SupabaseService.isInitialized) {
      final cloudRecords = await SupabaseService.fetchAllDispatches();
      if (cloudRecords.isNotEmpty) {
        await LocalStorageService.saveDispatches(cloudRecords);
        return cloudRecords;
      }
    }
    return LocalStorageService.getDispatches();
  }

  Future<void> saveDispatch(VehicleDispatch dispatch) async {
    // 1. Save locally for instantaneous offline/resilient reactivity
    await LocalStorageService.addDispatch(dispatch);

    // 2. Sync to Supabase
    if (SupabaseService.isInitialized) {
      await SupabaseService.saveVehicleDispatch(dispatch);
    }
  }

  Future<void> updateDispatch(VehicleDispatch dispatch) async {
    await LocalStorageService.updateDispatch(dispatch);
    if (SupabaseService.isInitialized) {
      await SupabaseService.saveVehicleDispatch(dispatch);
    }
  }

  Future<void> deleteDispatch(String dispatchId) async {
    await LocalStorageService.deleteDispatch(dispatchId);
    if (SupabaseService.isInitialized) {
      await SupabaseService.deleteVehicleDispatch(dispatchId);
    }
  }

  Future<List<ProductModel>> getProducts() async {
    if (SupabaseService.isInitialized) {
      final cloudProducts = await SupabaseService.fetchAllProducts();
      if (cloudProducts.isNotEmpty) {
        await LocalStorageService.saveProducts(cloudProducts);
        return cloudProducts;
      }
    }
    return LocalStorageService.getProducts();
  }
}
