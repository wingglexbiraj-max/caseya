import '../models/dispatch_record.dart';
import '../models/product_model.dart';
import '../services/local_storage_service.dart';
import '../services/supabase_service.dart';

class DispatchRepository {
  Future<List<VehicleDispatch>> getDispatches() async {
    final localRecords = await LocalStorageService.getDispatches();
    if (SupabaseService.isInitialized) {
      final cloudRecords = await SupabaseService.fetchAllDispatches();
      if (cloudRecords.isNotEmpty) {
        final localMap = {for (final l in localRecords) l.id: l};
        final merged = cloudRecords.map((c) {
          final local = localMap[c.id];
          if (local != null) {
            final pCrates = c.productCrates > 0 ? c.productCrates : local.productCrates;
            final mCrates = c.milkCrates > 0 ? c.milkCrates : local.milkCrates;
            return c.copyWith(productCrates: pCrates, milkCrates: mCrates);
          }
          return c;
        }).toList();
        await LocalStorageService.saveDispatches(merged);
        return merged;
      }
    }
    return localRecords;
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
