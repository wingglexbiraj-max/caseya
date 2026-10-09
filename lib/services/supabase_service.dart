import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/supabase_config.dart';
import '../models/user_model.dart';
import '../models/product_model.dart';
import '../models/dispatch_record.dart';

class AccountSuspendedException implements Exception {
  final String message;
  const AccountSuspendedException([this.message = 'Your plant employee account has been suspended by an administrator. Please contact plant management.']);

  @override
  String toString() => message;
}

class SupabaseService {
  static SupabaseClient? _client;
  static bool _initialized = false;

  /// Returns the active SupabaseClient if initialized, or throws a clear error
  static SupabaseClient get client {
    if (_client == null || !_initialized) {
      throw StateError('Supabase has not been initialized with valid credentials.');
    }
    return _client!;
  }

  /// Whether Supabase client is actively initialized
  static bool get isInitialized => _initialized && _client != null;

  /// Safe accessor that returns null instead of throwing
  static SupabaseClient? get clientOrNull => _client;

  /// Current Supabase Auth session
  static Session? get currentSession {
    if (!_initialized) return null;
    return _client?.auth.currentSession;
  }

  /// Current Supabase Auth user
  static User? get currentAuthUser {
    if (!_initialized) return null;
    return _client?.auth.currentUser;
  }

  /// Stream of Supabase Auth state changes
  static Stream<AuthState>? get authStateChanges {
    if (!_initialized) return null;
    return _client?.auth.onAuthStateChange;
  }

  /// Initialize Supabase client
  static Future<bool> initialize() async {
    await SupabaseConfig.init();

    if (!SupabaseConfig.isConfigured) {
      debugPrint('[SupabaseService] Configuration not present or incomplete. Running in standalone mode.');
      _initialized = false;
      _client = null;
      return false;
    }

    try {
      await Supabase.initialize(
        url: SupabaseConfig.url,
        publishableKey: SupabaseConfig.anonKey,
        debug: kDebugMode,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
        ),
      );
      _client = Supabase.instance.client;
      _initialized = true;
      debugPrint('[SupabaseService] Successfully connected to Supabase: ${SupabaseConfig.maskedUrl}');
      return true;
    } catch (e) {
      debugPrint('[SupabaseService] Initialization failed: $e');
      _initialized = false;
      _client = null;
      return false;
    }
  }

  // ===========================================================================
  // AUTHENTICATION OPERATIONS
  // ===========================================================================

  /// Authenticate employee with email and password
  static Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    if (!_initialized || _client == null) {
      throw Exception('Supabase connection is not configured. Please configure project settings.');
    }

    try {
      final response = await _client!.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      final user = response.user;
      if (user == null) {
        throw Exception('Authentication failed. No user record returned.');
      }

      // Fetch corresponding employee profile from PostgreSQL
      final profile = await fetchUserProfile(user.id, authEmail: user.email);

      // Check account status immediately on login
      if (profile.isSuspended) {
        await _client!.auth.signOut();
        throw const AccountSuspendedException();
      }

      return profile;
    } on AuthException catch (e) {
      throw Exception(_mapAuthError(e.message));
    } on AccountSuspendedException {
      rethrow;
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception(_mapGenericError(e.toString()));
    }
  }

  /// Register new employee account
  static Future<UserModel> signUp({
    required String email,
    required String password,
    required String fullName,
    String department = 'Processing & Operations',
  }) async {
    if (!_initialized || _client == null) {
      throw Exception('Supabase connection is not configured. Please configure project settings.');
    }

    try {
      final response = await _client!.auth.signUp(
        email: email.trim(),
        password: password,
        data: {
          'full_name': fullName.trim(),
          'department': department.trim(),
          'role': 'Employee',
        },
      );

      final user = response.user;
      if (user == null) {
        throw Exception('Sign up failed. Please check your credentials.');
      }

      // If email confirmation is enabled, session may be null until confirmed
      if (response.session == null) {
        return UserModel(
          userId: user.id,
          employeeCode: 'EMP-${user.id.substring(0, 4).toUpperCase()}',
          name: fullName.trim(),
          email: user.email ?? email.trim(),
          role: 'Employee',
          department: department.trim(),
          accountStatus: 'invited',
          active: true,
        );
      }

      // If auto-confirmed or session active, fetch or return profile
      try {
        final profile = await fetchUserProfile(user.id, authEmail: user.email);
        return profile;
      } catch (_) {
        return UserModel(
          userId: user.id,
          employeeCode: 'EMP-${user.id.substring(0, 4).toUpperCase()}',
          name: fullName.trim(),
          email: user.email ?? email.trim(),
          role: 'Employee',
          department: department.trim(),
          accountStatus: 'active',
          active: true,
        );
      }
    } on AuthException catch (e) {
      throw Exception(_mapAuthError(e.message));
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception(_mapGenericError(e.toString()));
    }
  }

  /// Terminate session and sign out
  static Future<void> signOut() async {
    if (_initialized && _client != null) {
      try {
        await _client!.auth.signOut();
      } catch (e) {
        debugPrint('[SupabaseService] Error signing out: $e');
      }
    }
  }

  /// Send password recovery link to user's registered email
  static Future<void> sendPasswordResetEmail({
    required String email,
    String? redirectTo,
  }) async {
    if (!_initialized || _client == null) {
      throw Exception('Supabase connection is not configured.');
    }

    try {
      await _client!.auth.resetPasswordForEmail(
        email.trim(),
        redirectTo: redirectTo,
      );
    } on AuthException catch (e) {
      throw Exception(_mapAuthError(e.message));
    } catch (e) {
      throw Exception(_mapGenericError(e.toString()));
    }
  }

  /// Update password for the currently verified recovery session
  static Future<void> updatePassword(String newPassword) async {
    if (!_initialized || _client == null) {
      throw Exception('Supabase connection is not configured.');
    }

    try {
      final res = await _client!.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      if (res.user == null) {
        throw Exception('Password update could not be confirmed.');
      }
    } on AuthException catch (e) {
      throw Exception(_mapAuthError(e.message));
    } catch (e) {
      throw Exception(_mapGenericError(e.toString()));
    }
  }

  // ===========================================================================
  // EMPLOYEE PROFILES & RBAC (DATABASE)
  // ===========================================================================

  /// Fetch user profile from `employee_profiles` table
  static Future<UserModel> fetchUserProfile(String userId, {String? authEmail}) async {
    if (!_initialized || _client == null) {
      return UserModel(
        userId: userId,
        employeeCode: 'EMP-01',
        name: 'Plant Operator',
        email: authEmail ?? '',
        role: 'Employee',
        department: 'Processing & Operations',
      );
    }

    try {
      final data = await _client!
          .from('employee_profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (data != null) {
        return UserModel.fromSupabaseProfile(data, authEmail: authEmail);
      }

      // If no row exists yet in employee_profiles, synthesize from auth metadata
      final authUser = _client!.auth.currentUser;
      final meta = authUser?.userMetadata ?? {};
      final fallbackModel = UserModel(
        userId: userId,
        employeeCode: meta['employee_code']?.toString() ?? 'EMP-01',
        name: meta['full_name']?.toString() ?? (authEmail?.split('@').first ?? 'Operator'),
        email: authEmail ?? authUser?.email ?? '',
        role: meta['role']?.toString() ?? 'Employee',
        department: meta['department']?.toString() ?? 'Processing & Operations',
        accountStatus: 'active',
      );

      // Attempt self-healing profile creation in database
      try {
        await _client!.from('employee_profiles').upsert({
          'id': userId,
          'email': fallbackModel.email,
          'full_name': fallbackModel.name,
          'role': fallbackModel.role,
          'employee_code': fallbackModel.employeeCode,
          'department': fallbackModel.department,
          'account_status': 'active',
        });
      } catch (upsertErr) {
        debugPrint('[SupabaseService] Profile upsert notice: $upsertErr');
      }

      return fallbackModel;
    } catch (e) {
      debugPrint('[SupabaseService] Error loading employee profile: $e');
      return UserModel(
        userId: userId,
        employeeCode: 'EMP-01',
        name: authEmail?.split('@').first ?? 'Operator',
        email: authEmail ?? '',
        role: 'Employee',
        department: 'Processing & Operations',
      );
    }
  }

  /// Admin operation: Fetch all registered plant employee profiles
  static Future<List<UserModel>> fetchAllEmployeeProfiles() async {
    if (!_initialized || _client == null) return [];

    try {
      final List<dynamic> data = await _client!
          .from('employee_profiles')
          .select()
          .order('created_at', ascending: false);

      return data
          .map((row) => UserModel.fromSupabaseProfile(row as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[SupabaseService] Error fetching all employees: $e');
      rethrow;
    }
  }

  /// Admin operation: Update an employee's role
  static Future<void> updateEmployeeRole({
    required String employeeId,
    required String newRole,
  }) async {
    if (!_initialized || _client == null) {
      throw Exception('Supabase connection is not configured.');
    }

    try {
      await _client!
          .from('employee_profiles')
          .update({'role': newRole, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', employeeId);
    } catch (e) {
      throw Exception('Failed to update employee role: $e');
    }
  }

  /// Admin operation: Update an employee's account status (active vs disabled)
  static Future<void> updateEmployeeStatus({
    required String employeeId,
    required String newStatus,
  }) async {
    if (!_initialized || _client == null) {
      throw Exception('Supabase connection is not configured.');
    }

    try {
      await _client!
          .from('employee_profiles')
          .update({
            'account_status': newStatus,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', employeeId);
    } catch (e) {
      throw Exception('Failed to update employee account status: $e');
    }
  }

  /// Admin operation: Provision or invite a new employee profile
  static Future<void> provisionEmployee({
    required String email,
    required String fullName,
    required String role,
    required String employeeCode,
    required String department,
  }) async {
    if (!_initialized || _client == null) {
      throw Exception('Supabase connection is not configured.');
    }

    // Try calling the Supabase Edge Function `invite-employee` first if deployed
    try {
      final res = await _client!.functions.invoke(
        'invite-employee',
        body: {
          'email': email.trim(),
          'full_name': fullName.trim(),
          'role': role,
          'employee_code': employeeCode.trim(),
          'department': department,
        },
      );
      if (res.status == 200 || res.status == 201) {
        return;
      }
    } catch (edgeErr) {
      debugPrint('[SupabaseService] Edge Function invite-employee fallback: $edgeErr');
    }

    // Fallback: If edge function is not deployed yet, attempt calling the Postgres RPC function
    try {
      await _client!.rpc('provision_employee', params: {
        'p_email': email.trim(),
        'p_full_name': fullName.trim(),
        'p_role': role,
        'p_employee_code': employeeCode.trim(),
        'p_department': department,
      });
      return;
    } catch (rpcErr) {
      debugPrint('[SupabaseService] RPC provision_employee notice: $rpcErr');
      rethrow;
    }
  }

  // ===========================================================================
  // DISPATCH OPERATIONS (SUPABASE CLOUD & RPC)
  // ===========================================================================

  /// Fetch all dispatch entries with items from Supabase
  static Future<List<VehicleDispatch>> fetchAllDispatches() async {
    if (!_initialized || _client == null) return [];

    try {
      final response = await _client!
          .from('dispatch_entries')
          .select('*, items:dispatch_entry_items(*)')
          .order('dispatch_date', ascending: false)
          .order('created_at', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      return data.map((json) {
        final map = Map<String, dynamic>.from(json as Map);
        return VehicleDispatch.fromJson(map);
      }).toList();
    } catch (e) {
      debugPrint('[SupabaseService] Error fetching dispatches: $e');
      return [];
    }
  }

  /// Save or update a vehicle dispatch atomically via Postgres RPC or direct insert
  static Future<bool> saveVehicleDispatch(VehicleDispatch dispatch) async {
    if (!_initialized || _client == null) return false;

    try {
      // 1. Attempt atomic RPC save_vehicle_dispatch
      try {
        final rpcRes = await _client!.rpc('save_vehicle_dispatch', params: {
          'p_dispatch': dispatch.toJson(),
          'p_items': dispatch.items.map((i) => i.toJson()).toList(),
        });
        if (rpcRes != null) return true;
      } catch (rpcErr) {
        debugPrint('[SupabaseService] save_vehicle_dispatch RPC notice: $rpcErr');
      }

      // 2. Direct table fallback if RPC not yet deployed
      final dispatchMap = {
        'id': dispatch.id.length >= 32 ? dispatch.id : null,
        'dispatch_date': dispatch.dispatchDate,
        'vehicle_number': dispatch.vehicleNumber.toUpperCase(),
        'distributor_name': dispatch.distributorName,
        'driver_name': dispatch.driverName,
        'route': dispatch.route,
        'remarks': dispatch.remarks,
        'dispatch_time': dispatch.dispatchTime,
        'created_by': dispatch.createdBy,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };
      if (dispatchMap['id'] == null) dispatchMap.remove('id');

      final entryRes = await _client!
          .from('dispatch_entries')
          .upsert(dispatchMap)
          .select('id')
          .single();

      final actualId = entryRes['id']?.toString() ?? dispatch.id;

      // Upsert line items
      await _client!
          .from('dispatch_entry_items')
          .delete()
          .eq('dispatch_entry_id', actualId);

      if (dispatch.items.isNotEmpty) {
        final itemsPayload = dispatch.items.map((item) {
          final itemJson = item.toJson();
          itemJson['dispatch_entry_id'] = actualId;
          itemJson.remove('id');
          return itemJson;
        }).toList();

        await _client!.from('dispatch_entry_items').insert(itemsPayload);
      }
      return true;
    } catch (e) {
      debugPrint('[SupabaseService] Error saving vehicle dispatch: $e');
      return false;
    }
  }

  /// Delete a vehicle dispatch record
  static Future<bool> deleteVehicleDispatch(String dispatchId) async {
    if (!_initialized || _client == null) return false;

    try {
      await _client!.from('dispatch_entries').delete().eq('id', dispatchId);
      return true;
    } catch (e) {
      debugPrint('[SupabaseService] Error deleting vehicle dispatch: $e');
      return false;
    }
  }

  // ===========================================================================
  // PRODUCT MASTER DATABASE OPERATIONS
  // ===========================================================================

  /// Fetch all active products dynamically from Supabase products_master table
  static Future<List<ProductModel>> fetchAllProducts() async {
    if (!_initialized || _client == null) return [];

    try {
      final response = await _client!
          .from('products_master')
          .select()
          .eq('active', true)
          .order('product_id', ascending: true);

      final List<dynamic> list = response as List<dynamic>;
      return list.map((json) => ProductModel.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('[SupabaseService] Error fetching products_master: $e');
      return [];
    }
  }

  /// Sync/Upsert canonical products to Supabase products_master table
  static Future<bool> syncProductsMaster(List<ProductModel> products) async {
    if (!_initialized || _client == null) return false;

    try {
      final payload = products.map((p) => p.toJson()).toList();
      await _client!.from('products_master').upsert(payload);
      return true;
    } catch (e) {
      debugPrint('[SupabaseService] Error syncing products_master: $e');
      return false;
    }
  }

  // ===========================================================================
  // HUMAN-READABLE ERROR TRANSLATION (SECURITY BEST PRACTICE)
  // ===========================================================================

  static String _mapAuthError(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('invalid login credentials') || lower.contains('invalid_credentials')) {
      return 'Incorrect email or password. Please verify your credentials and try again.';
    }
    if (lower.contains('email not confirmed') || lower.contains('not verified')) {
      return 'Your email address has not been confirmed yet. Please verify your inbox.';
    }
    if (lower.contains('user already registered')) {
      return 'An employee account is already registered with this email address.';
    }
    if (lower.contains('password should be at least') || lower.contains('weak_password')) {
      return 'Password must be at least 8 characters long and include numbers or symbols.';
    }
    if (lower.contains('user not found')) {
      return 'No employee account was found matching this email address.';
    }
    if (lower.contains('rate limit') || lower.contains('too many requests')) {
      return 'Too many login attempts. Please wait 60 seconds before trying again.';
    }
    if (lower.contains('network') || lower.contains('connection')) {
      return 'Unable to contact plant authentication server. Please check your internet connection.';
    }
    return message;
  }

  static String _mapGenericError(String error) {
    final lower = error.toLowerCase();
    if (lower.contains('socketexception') || lower.contains('connection refused') || lower.contains('failed host lookup')) {
      return 'Unable to reach the Supabase server. Please verify network connectivity.';
    }
    if (lower.contains('timeout')) {
      return 'The authentication request timed out. Please try again.';
    }
    return 'An unexpected error occurred. Please contact plant IT support.';
  }
}
