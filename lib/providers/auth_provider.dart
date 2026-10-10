import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../models/user_model.dart';
import '../services/local_storage_service.dart';
import '../services/supabase_service.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  passwordRecovery,
  accountSuspended,
  error,
}

class AuthState {
  final UserModel user;
  final AuthStatus status;
  final String? errorMessage;
  final bool isSubmitting;
  final bool isConfigured;

  const AuthState({
    required this.user,
    this.status = AuthStatus.initial,
    this.errorMessage,
    this.isSubmitting = false,
    this.isConfigured = false,
  });

  bool get isAuthenticated =>
      status == AuthStatus.authenticated && user.active && !user.isSuspended;

  bool get isLoading => status == AuthStatus.loading || isSubmitting;

  AuthState copyWith({
    UserModel? user,
    AuthStatus? status,
    String? errorMessage,
    bool? isSubmitting,
    bool? isConfigured,
  }) {
    return AuthState(
      user: user ?? this.user,
      status: status ?? this.status,
      errorMessage: errorMessage,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isConfigured: isConfigured ?? this.isConfigured,
    );
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

final authProvider = Provider<UserModel>((ref) {
  return ref.watch(authNotifierProvider).user;
});

final authStateProvider = Provider<AuthState>((ref) {
  return ref.watch(authNotifierProvider);
});

class AuthNotifier extends StateNotifier<AuthState> {
  StreamSubscription<sb.AuthState>? _authSubscription;

  AuthNotifier()
      : super(const AuthState(
          user: UserModel.guest,
          status: AuthStatus.initial,
        )) {
    init();
  }

  /// Initialize authentication state on startup
  Future<void> init() async {
    state = state.copyWith(status: AuthStatus.loading);

    // Initialize Supabase client
    final isConfigured = await SupabaseService.initialize();

    if (isConfigured && SupabaseService.isInitialized) {
      // Subscribe to Supabase Auth state changes
      _authSubscription?.cancel();
      _authSubscription = SupabaseService.authStateChanges?.listen(
        _handleAuthStateChange,
        onError: (err) {
          debugPrint('[AuthNotifier] Auth stream error: $err');
        },
      );

      // Check current session
      final session = SupabaseService.currentSession;
      if (session != null && session.user.id.isNotEmpty) {
        await _restoreSession(session.user);
        return;
      } else {
        // No active Supabase session
        state = state.copyWith(
          user: UserModel.guest,
          status: AuthStatus.unauthenticated,
          isConfigured: true,
        );
        return;
      }
    }

    // Standalone fallback when Supabase credentials are not yet configured
    final localUser = await LocalStorageService.getCurrentUser();
    if (localUser.userId.isNotEmpty &&
        localUser.active &&
        !localUser.isSuspended &&
        !localUser.isGuest) {
      state = state.copyWith(
        user: localUser,
        status: AuthStatus.authenticated,
        isConfigured: false,
      );
    } else {
      state = state.copyWith(
        user: UserModel.guest,
        status: AuthStatus.unauthenticated,
        isConfigured: false,
      );
    }
  }

  void _handleAuthStateChange(sb.AuthState authState) async {
    final event = authState.event;
    final session = authState.session;

    debugPrint('[AuthNotifier] Supabase Auth Event: $event');

    switch (event) {
      case sb.AuthChangeEvent.signedIn:
        if (session != null) {
          await _restoreSession(session.user);
        }
        break;

      case sb.AuthChangeEvent.signedOut:
        state = state.copyWith(
          user: UserModel.guest,
          status: AuthStatus.unauthenticated,
        );
        break;

      case sb.AuthChangeEvent.passwordRecovery:
        state = state.copyWith(
          status: AuthStatus.passwordRecovery,
        );
        break;

      case sb.AuthChangeEvent.tokenRefreshed:
        if (session != null && state.user.userId.isNotEmpty) {
          // Token refreshed in background
        }
        break;

      case sb.AuthChangeEvent.userUpdated:
        if (session != null) {
          await refreshProfile();
        }
        break;

      default:
        break;
    }
  }

  Future<void> _restoreSession(sb.User authUser) async {
    try {
      final profile = await SupabaseService.fetchUserProfile(
        authUser.id,
        authEmail: authUser.email,
      );

      if (profile.isSuspended) {
        await SupabaseService.signOut();
        state = state.copyWith(
          user: profile,
          status: AuthStatus.accountSuspended,
          errorMessage:
              'Your employee account has been suspended by plant administration.',
        );
        return;
      }

      state = state.copyWith(
        user: profile,
        status: AuthStatus.authenticated,
        isConfigured: true,
        errorMessage: null,
      );
      await LocalStorageService.saveCurrentUser(profile);
    } catch (e) {
      debugPrint('[AuthNotifier] Error restoring session profile: $e');
      state = state.copyWith(
        user: UserModel(
          userId: authUser.id,
          employeeCode: 'EMP-01',
          name: authUser.email?.split('@').first ?? 'Plant Operator',
          email: authUser.email ?? '',
          role: 'Employee',
          department: 'Processing & Operations',
          accountStatus: 'active',
        ),
        status: AuthStatus.authenticated,
        isConfigured: true,
      );
    }
  }

  /// Sign in with employee email and password
  Future<bool> login({
    required String email,
    required String password,
    bool rememberMe = true,
  }) async {
    state = state.copyWith(isSubmitting: true, errorMessage: null);

    if (SupabaseService.isInitialized) {
      try {
        final profile = await SupabaseService.signIn(
          email: email.trim(),
          password: password,
        );

        state = state.copyWith(
          user: profile,
          status: AuthStatus.authenticated,
          isSubmitting: false,
          errorMessage: null,
        );
        await LocalStorageService.saveCurrentUser(profile);
        return true;
      } on AccountSuspendedException catch (e) {
        state = state.copyWith(
          status: AuthStatus.accountSuspended,
          isSubmitting: false,
          errorMessage: e.message,
        );
        return false;
      } catch (e) {
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          isSubmitting: false,
          errorMessage: e.toString().replaceFirst('Exception: ', ''),
        );
        return false;
      }
    } else {
      // Standalone mode validation (when Supabase credentials not yet supplied)
      if (email.trim().isEmpty || password.isEmpty) {
        state = state.copyWith(
          isSubmitting: false,
          errorMessage: 'Please enter both plant email and password.',
        );
        return false;
      }

      final profile = UserModel(
        userId: 'EMP-0101',
        employeeCode: 'ADMIN-01',
        name: email.split('@').first.replaceAll('.', ' ').toUpperCase(),
        email: email.trim(),
        role: 'Admin',
        department: 'Processing & Operations',
        accountStatus: 'active',
      );

      state = state.copyWith(
        user: profile,
        status: AuthStatus.authenticated,
        isSubmitting: false,
        errorMessage: null,
      );
      await LocalStorageService.saveCurrentUser(profile);
      return true;
    }
  }

  /// Register a new employee account
  Future<SignUpResult> register({
    required String fullName,
    required String email,
    required String password,
    String department = 'Processing & Operations',
  }) async {
    // If already authenticated, do not register on top of existing session
    if (state.isAuthenticated) {
      return SignUpResult(
        isSessionEstablished: false,
        isEmailConfirmationRequired: false,
        user: state.user,
        message: 'A session is already active for ${state.user.name}. Please sign out first to create a new employee account.',
      );
    }

    state = state.copyWith(isSubmitting: true, errorMessage: null);

    if (SupabaseService.isInitialized) {
      try {
        final result = await SupabaseService.signUp(
          fullName: fullName.trim(),
          email: email.trim(),
          password: password,
          department: department.trim(),
        );

        if (result.isSessionEstablished) {
          state = state.copyWith(
            user: result.user,
            status: AuthStatus.authenticated,
            isSubmitting: false,
            errorMessage: null,
          );
          await LocalStorageService.saveCurrentUser(result.user);
        } else {
          // Unconfirmed signup or email verification required
          // Deliberately keep unauthenticated state! Do not treat unconfirmed signup as active session.
          state = state.copyWith(
            user: UserModel.guest,
            status: AuthStatus.unauthenticated,
            isSubmitting: false,
            errorMessage: null,
          );
        }
        return result;
      } catch (e) {
        final errorMsg = e.toString().replaceFirst('Exception: ', '');
        state = state.copyWith(
          isSubmitting: false,
          errorMessage: errorMsg,
        );
        return SignUpResult(
          isSessionEstablished: false,
          isEmailConfirmationRequired: false,
          user: UserModel.guest,
          message: errorMsg,
        );
      }
    } else {
      // Standalone mode demo registration
      if (fullName.trim().isEmpty || email.trim().isEmpty || password.isEmpty) {
        const errorMsg = 'Please fill in all required fields.';
        state = state.copyWith(
          isSubmitting: false,
          errorMessage: errorMsg,
        );
        return const SignUpResult(
          isSessionEstablished: false,
          isEmailConfirmationRequired: false,
          user: UserModel.guest,
          message: errorMsg,
        );
      }

      final profile = UserModel(
        userId: 'EMP-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
        employeeCode: 'EMP-02',
        name: fullName.trim(),
        email: email.trim(),
        role: 'Employee',
        department: department.trim(),
        accountStatus: 'active',
        active: true,
      );

      state = state.copyWith(
        user: profile,
        status: AuthStatus.authenticated,
        isSubmitting: false,
        errorMessage: null,
      );
      await LocalStorageService.saveCurrentUser(profile);
      return SignUpResult(
        isSessionEstablished: true,
        isEmailConfirmationRequired: false,
        user: profile,
        message: 'Account created and authenticated successfully.',
      );
    }
  }

  /// Sign out
  Future<void> logout() async {
    state = state.copyWith(isSubmitting: true);
    try {
      if (SupabaseService.isInitialized) {
        await SupabaseService.signOut();
      }
    } catch (_) {}

    await LocalStorageService.clearCurrentUser();

    state = state.copyWith(
      user: UserModel.guest,
      status: AuthStatus.unauthenticated,
      isSubmitting: false,
      errorMessage: null,
    );
  }

  /// Send password recovery email
  Future<bool> sendPasswordReset(String email, {String? redirectTo}) async {
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    try {
      if (SupabaseService.isInitialized) {
        await SupabaseService.sendPasswordResetEmail(
          email: email.trim(),
          redirectTo: redirectTo,
        );
      } else {
        // Simulated network delay in standalone mode
        await Future.delayed(const Duration(milliseconds: 600));
      }
      state = state.copyWith(isSubmitting: false, errorMessage: null);
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  /// Update password during password recovery flow
  Future<bool> updatePassword(String newPassword) async {
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    try {
      if (SupabaseService.isInitialized) {
        await SupabaseService.updatePassword(newPassword);
      } else {
        await Future.delayed(const Duration(milliseconds: 600));
      }
      state = state.copyWith(
        status: AuthStatus.authenticated,
        isSubmitting: false,
        errorMessage: null,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  /// Refresh user profile from PostgreSQL
  Future<void> refreshProfile() async {
    if (state.user.userId.isNotEmpty && SupabaseService.isInitialized) {
      try {
        final profile = await SupabaseService.fetchUserProfile(
          state.user.userId,
          authEmail: state.user.email,
        );
        state = state.copyWith(user: profile);
        await LocalStorageService.saveCurrentUser(profile);
      } catch (e) {
        debugPrint('[AuthNotifier] Error refreshing profile: $e');
      }
    }
  }

  /// Clear any error message
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  // ===========================================================================
  // BACKWARD COMPATIBILITY METHODS
  // ===========================================================================

  Future<void> loadUser() async {
    await init();
  }

  Future<void> switchRole(String role) async {
    final updated = state.user.copyWith(role: role);
    state = state.copyWith(user: updated);
    await LocalStorageService.saveCurrentUser(updated);
  }

  Future<void> updateUser(UserModel user) async {
    state = state.copyWith(user: user);
    await LocalStorageService.saveCurrentUser(user);
  }

  Future<void> loginDefault({
    String name = 'Biraj Goswami',
    String role = 'Admin',
    String employeeCode = 'ADMIN-01',
  }) async {
    final updated = UserModel(
      userId: 'EMP-0101',
      employeeCode: employeeCode,
      name: name,
      email: '${name.toLowerCase().replaceAll(' ', '.')}@caseya-plant.com',
      role: role,
      department: 'Processing & Operations',
      accountStatus: 'active',
      active: true,
    );
    state = state.copyWith(
      user: updated,
      status: AuthStatus.authenticated,
    );
    await LocalStorageService.saveCurrentUser(updated);
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
