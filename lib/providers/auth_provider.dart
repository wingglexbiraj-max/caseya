import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/local_storage_service.dart';

final authProvider = StateNotifierProvider<AuthNotifier, UserModel>((ref) {
  return AuthNotifier();
});

class AuthNotifier extends StateNotifier<UserModel> {
  AuthNotifier()
      : super(const UserModel(
          userId: 'EMP-0101',
          employeeCode: 'ADMIN-01',
          name: 'Biraj Goswami',
          email: 'biraj.goswami@caseya-plant.com',
          role: 'Admin',
          department: 'Processing & Operations',
        )) {
    loadUser();
  }

  Future<void> loadUser() async {
    final user = await LocalStorageService.getCurrentUser();
    if (user.name == 'R. K. Baruah' || user.name.isEmpty) {
      final updated = UserModel(
        userId: user.userId.isEmpty ? 'EMP-0101' : user.userId,
        employeeCode: user.employeeCode.isEmpty ? 'ADMIN-01' : user.employeeCode,
        name: 'Biraj Goswami',
        email: 'biraj.goswami@caseya-plant.com',
        role: user.role,
        department: user.department,
        active: true,
      );
      state = updated;
      await LocalStorageService.saveCurrentUser(updated);
    } else {
      state = user;
    }
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
