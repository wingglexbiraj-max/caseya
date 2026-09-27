class UserModel {
  final String userId;
  final String employeeCode;
  final String name;
  final String email;
  final String role; // Admin, Supervisor, Operator
  final String department; // Processing, Quality, Maintenance, Dispatch
  final bool active;

  const UserModel({
    required this.userId,
    required this.employeeCode,
    required this.name,
    required this.email,
    required this.role,
    required this.department,
    this.active = true,
  });

  bool get isAdmin => role == 'Admin';
  bool get isSupervisor => role == 'Supervisor' || role == 'Admin';
  bool get isOperator => true;

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'employee_code': employeeCode,
      'name': name,
      'email': email,
      'role': role,
      'department': department,
      'active': active,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['user_id']?.toString() ?? '',
      employeeCode: json['employee_code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? 'Operator',
      department: json['department']?.toString() ?? 'Processing',
      active: json['active'] as bool? ?? true,
    );
  }
}
