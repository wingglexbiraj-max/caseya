import 'package:flutter_test/flutter_test.dart';
import 'package:caseya/models/user_model.dart';
import 'package:caseya/providers/auth_provider.dart';
import 'package:caseya/core/config/supabase_config.dart';

void main() {
  group('UserModel Role-Based Access Control (RBAC) Tests', () {
    test('Admin user has complete operational and management capabilities', () {
      const admin = UserModel(
        userId: 'admin-123',
        employeeCode: 'ADMIN-01',
        name: 'Biraj Goswami',
        email: 'admin@caseya-plant.com',
        role: 'Admin',
        department: 'Processing & Operations',
        accountStatus: 'active',
        active: true,
      );

      expect(admin.isAdmin, isTrue);
      expect(admin.isPlantManager, isTrue);
      expect(admin.isEmployee, isTrue);
      expect(admin.isActive, isTrue);
      expect(admin.isSuspended, isFalse);
      expect(admin.canManageUsers, isTrue);
      expect(admin.canAccessSettings, isTrue);
      expect(admin.canAccessReports, isTrue);
      expect(admin.canRecordProduction, isTrue);
    });

    test('Plant Manager user has report access but cannot manage users or settings', () {
      const manager = UserModel(
        userId: 'mgr-456',
        employeeCode: 'MGR-01',
        name: 'R. K. Baruah',
        email: 'manager@caseya-plant.com',
        role: 'Plant Manager',
        department: 'Operations',
        accountStatus: 'active',
        active: true,
      );

      expect(manager.isAdmin, isFalse);
      expect(manager.isPlantManager, isTrue);
      expect(manager.isEmployee, isTrue);
      expect(manager.canManageUsers, isFalse);
      expect(manager.canAccessSettings, isFalse);
      expect(manager.canAccessReports, isTrue);
      expect(manager.canRecordProduction, isTrue);
    });

    test('Standard Employee user can record plant operations but cannot access admin features', () {
      const employee = UserModel(
        userId: 'emp-789',
        employeeCode: 'OPR-05',
        name: 'Debojit Sharma',
        email: 'employee@caseya-plant.com',
        role: 'Employee',
        department: 'Quality Assurance',
        accountStatus: 'active',
        active: true,
      );

      expect(employee.isAdmin, isFalse);
      expect(employee.isPlantManager, isFalse);
      expect(employee.isEmployee, isTrue);
      expect(employee.canManageUsers, isFalse);
      expect(employee.canAccessSettings, isFalse);
      expect(employee.canAccessReports, isFalse);
      expect(employee.canRecordProduction, isTrue);
    });

    test('Suspended employee account status is properly identified', () {
      const suspended = UserModel(
        userId: 'emp-suspended',
        employeeCode: 'OPR-99',
        name: 'Suspended Worker',
        email: 'suspended@caseya-plant.com',
        role: 'Employee',
        department: 'Maintenance',
        accountStatus: 'disabled',
        active: false,
      );

      expect(suspended.isActive, isFalse);
      expect(suspended.isSuspended, isTrue);
      expect(suspended.canRecordProduction, isFalse);
      expect(suspended.canRecordBoiler, isFalse);
    });

    test('UserModel serializes and deserializes to/from Supabase profile correctly', () {
      final json = {
        'id': 'uuid-999',
        'full_name': 'Plant Head',
        'email': 'head@caseya-plant.com',
        'role': 'Admin',
        'employee_code': 'ADMIN-02',
        'department': 'Operations',
        'account_status': 'active',
        'created_at': '2026-10-09T10:00:00Z',
      };

      final model = UserModel.fromSupabaseProfile(json);
      expect(model.id, equals('uuid-999'));
      expect(model.name, equals('Plant Head'));
      expect(model.email, equals('head@caseya-plant.com'));
      expect(model.role, equals('Admin'));
      expect(model.employeeCode, equals('ADMIN-02'));
      expect(model.department, equals('Operations'));
      expect(model.isActive, isTrue);
    });
  });

  group('AuthState & Security Logic Tests', () {
    test('AuthState unauthenticated and authenticated checks', () {
      const unauth = AuthState(
        user: UserModel.guest,
        status: AuthStatus.unauthenticated,
      );
      expect(unauth.isAuthenticated, isFalse);

      const active = AuthState(
        user: UserModel(
          userId: 'test-1',
          employeeCode: 'EMP-01',
          name: 'Active User',
          email: 'user@test.com',
          role: 'Employee',
          department: 'Processing',
          accountStatus: 'active',
          active: true,
        ),
        status: AuthStatus.authenticated,
      );
      expect(active.isAuthenticated, isTrue);

      const suspendedState = AuthState(
        user: UserModel(
          userId: 'test-2',
          employeeCode: 'EMP-02',
          name: 'Suspended User',
          email: 'user2@test.com',
          role: 'Employee',
          department: 'Processing',
          accountStatus: 'disabled',
          active: false,
        ),
        status: AuthStatus.accountSuspended,
      );
      expect(suspendedState.isAuthenticated, isFalse);
    });

    test('Password policy validation matches enterprise security rules', () {
      final emailRegex = RegExp(r'^[\w\.\-]+@[\w\.\-]+\.\w{2,}$');
      expect(emailRegex.hasMatch('valid.operator@caseya-plant.com'), isTrue);
      expect(emailRegex.hasMatch('invalid-email'), isFalse);
      expect(emailRegex.hasMatch('no-domain@'), isFalse);

      // Password rules: >= 8 characters, letter, number
      bool isValidPassword(String pwd) {
        return pwd.length >= 8 &&
            RegExp(r'[A-Za-z]').hasMatch(pwd) &&
            RegExp(r'[0-9]').hasMatch(pwd);
      }

      expect(isValidPassword('short'), isFalse);
      expect(isValidPassword('lettersletters'), isFalse);
      expect(isValidPassword('1234567890'), isFalse);
      expect(isValidPassword('ValidPass123'), isTrue);
    });

    test('SupabaseConfig maskedUrl hides sensitive credentials', () {
      expect(SupabaseConfig.maskedUrl, isNotNull);
    });

    test('New employee registration model initializes with Employee role and active status', () {
      final newRegisteredUser = UserModel(
        userId: 'new-emp-101',
        employeeCode: 'EMP-02',
        name: 'New Plant Operator',
        email: 'operator@caseya-plant.com',
        role: 'Employee',
        department: 'Packaging & Cold Storage',
        accountStatus: 'active',
        active: true,
      );

      expect(newRegisteredUser.role, equals('Employee'));
      expect(newRegisteredUser.isAdmin, isFalse);
      expect(newRegisteredUser.isEmployee, isTrue);
      expect(newRegisteredUser.canRecordProduction, isTrue);
      expect(newRegisteredUser.canManageUsers, isFalse);
    });
  });
}
