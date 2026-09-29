import '../models/dispatch_record.dart';
import '../models/product_model.dart';
import '../services/local_storage_service.dart';

class DispatchRepository {
  Future<List<VehicleDispatch>> getDispatches() async {
    return LocalStorageService.getDispatches();
  }

  Future<void> saveDispatch(VehicleDispatch dispatch) async {
    await LocalStorageService.addDispatch(dispatch);
  }

  Future<void> updateDispatch(VehicleDispatch dispatch) async {
    await LocalStorageService.updateDispatch(dispatch);
  }

  Future<void> deleteDispatch(String dispatchId) async {
    await LocalStorageService.deleteDispatch(dispatchId);
  }

  Future<List<ProductModel>> getProducts() async {
    return LocalStorageService.getProducts();
  }
}
