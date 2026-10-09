/// Production-Ready Employee & User Model for CASEYA Dairy Plant ERP
///
/// Integrated with Supabase Auth (`auth.users`) and Postgres (`employee_profiles`).
class UserModel {
  final String userId;
  final String employeeCode;
  final String name;
  final String email;
  final String role; // 'Admin', 'Plant Manager', 'Employee'
  final String department; // 'Processing & Operations', 'Quality Assurance', etc.
  final String accountStatus; // 'active', 'disabled', 'invited'
  final bool active;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserModel({
    required this.userId,
    required this.employeeCode,
    required this.name,
    required this.email,
    required this.role,
    required this.department,
    this.accountStatus = 'active',
    this.active = true,
    this.createdAt,
    this.updatedAt,
  });

  /// Alias for userId matching Supabase auth.users.id
  String get id => userId;
  String get fullName => name;

  // Role Checks
  bool get isAdmin => role.trim().toLowerCase() == 'admin';
  bool get isPlantManager =>
      role.trim().toLowerCase() == 'plant manager' || isAdmin;
  bool get isEmployee => true;

  // Backward compatibility aliases
  bool get isSupervisor => isPlantManager;
  bool get isOperator => isEmployee;

  // Status Checks
  bool get isActive =>
      accountStatus.trim().toLowerCase() == 'active' && active;
  bool get isSuspended =>
      accountStatus.trim().toLowerCase() == 'disabled' || !active;
  bool get isInvited => accountStatus.trim().toLowerCase() == 'invited';

  // Permission Capabilities
  bool get canManageUsers => isAdmin;
  bool get canAccessSettings => isAdmin;
  bool get canAccessReports => isAdmin || isPlantManager;
  bool get canRecordProduction => isActive;
  bool get canRecordLab => isActive;
  bool get canRecordBoiler => isActive;
  bool get canRecordDg => isActive;
  bool get canRecordDispatch => isActive;
  bool get canManageInventory => isActive;

  UserModel copyWith({
    String? userId,
    String? employeeCode,
    String? name,
    String? email,
    String? role,
    String? department,
    String? accountStatus,
    bool? active,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      userId: userId ?? this.userId,
      employeeCode: employeeCode ?? this.employeeCode,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      department: department ?? this.department,
      accountStatus: accountStatus ?? this.accountStatus,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'id': userId,
      'employee_code': employeeCode,
      'name': name,
      'full_name': name,
      'email': email,
      'role': role,
      'department': department,
      'account_status': accountStatus,
      'active': active,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final status = json['account_status']?.toString().toLowerCase() ?? 'active';
    final act = json['active'] as bool? ?? (status == 'active');
    return UserModel(
      userId: json['user_id']?.toString() ?? json['id']?.toString() ?? '',
      employeeCode: json['employee_code']?.toString() ?? 'EMP-01',
      name: json['name']?.toString() ?? json['full_name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? 'Employee',
      department: json['department']?.toString() ?? 'Processing & Operations',
      accountStatus: status,
      active: act,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  factory UserModel.fromSupabaseProfile(Map<String, dynamic> json, {String? authEmail}) {
    final status = json['account_status']?.toString().toLowerCase() ?? 'active';
    return UserModel(
      userId: json['id']?.toString() ?? '',
      employeeCode: json['employee_code']?.toString() ?? 'EMP-01',
      name: json['full_name']?.toString() ?? '',
      email: json['email']?.toString() ?? authEmail ?? '',
      role: json['role']?.toString() ?? 'Employee',
      department: json['department']?.toString() ?? 'Processing & Operations',
      accountStatus: status,
      active: status == 'active',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  /// Guest / unauthenticated representation
  static const UserModel guest = UserModel(
    userId: '',
    employeeCode: 'GUEST',
    name: 'Unauthenticated Operator',
    email: '',
    role: 'Employee',
    department: 'None',
    accountStatus: 'disabled',
    active: false,
  );
}
