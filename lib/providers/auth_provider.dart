import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/local_storage_service.dart';

final authProvider = StateNotifierProvider<AuthNotifier, UserModel>((ref) {
  return AuthNotifier();
});

class AuthNotifier extends StateNotifier<UserModel> {
  AuthNotifier()
      : super(const UserModel(
          userId: 'EMP-0104',
          employeeCode: 'OPR-104',
          name: 'R. K. Baruah',
          email: 'rbaruah@caseya-plant.com',
          role: 'Supervisor',
          department: 'Processing & Operations',
        )) {
    loadUser();
  }

  Future<void> loadUser() async {
    final user = await LocalStorageService.getCurrentUser();
    state = user;
  }

  Future<void> switchRole(String role) async {
    final updated = UserModel(
      userId: state.userId,
      employeeCode: state.employeeCode,
      name: state.name,
      email: state.email,
      role: role,
      department: state.department,
      active: true,
    );
    state = updated;
    await LocalStorageService.saveCurrentUser(updated);
  }

  Future<void> updateUser(UserModel user) async {
    state = user;
    await LocalStorageService.saveCurrentUser(user);
  }
}
