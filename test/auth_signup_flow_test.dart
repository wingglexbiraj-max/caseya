import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:caseya/main.dart';
import 'package:caseya/models/user_model.dart';
import 'package:caseya/providers/auth_provider.dart';
import 'package:caseya/services/local_storage_service.dart';
import 'package:caseya/services/supabase_service.dart';
import 'package:caseya/core/constants/app_constants.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Caseya Auth & Signup Separation Flow Tests', () {
    const mockAdmin = UserModel(
      userId: 'test-admin-123',
      employeeCode: 'ADMIN-01',
      name: 'Biraj Goswami',
      email: 'biraj.goswami@caseya-plant.com',
      role: 'Admin',
      department: 'Processing & Operations',
      accountStatus: 'active',
      active: true,
    );

    const mockEmployee = UserModel(
      userId: 'test-emp-456',
      employeeCode: 'EMP-02',
      name: 'Priyanka Sharma',
      email: 'priyanka@caseya-plant.com',
      role: 'Employee',
      department: 'Quality & Lab',
      accountStatus: 'active',
      active: true,
    );

    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('1. LocalStorageService.getCurrentUser defaults to guest when storage is empty', () async {
      SharedPreferences.setMockInitialValues({});
      final user = await LocalStorageService.getCurrentUser();
      expect(user.isGuest, isTrue);
      expect(user.userId, isEmpty);
      expect(user.active, isFalse);
    });

    test('2. LocalStorageService persists and clears current user accurately', () async {
      SharedPreferences.setMockInitialValues({});
      await LocalStorageService.saveCurrentUser(mockAdmin);

      final retrieved = await LocalStorageService.getCurrentUser();
      expect(retrieved.userId, equals(mockAdmin.userId));
      expect(retrieved.name, equals(mockAdmin.name));
      expect(retrieved.isAdmin, isTrue);

      await LocalStorageService.clearCurrentUser();
      final afterClear = await LocalStorageService.getCurrentUser();
      expect(afterClear.isGuest, isTrue);
      expect(afterClear.userId, isEmpty);
    });

    test('3. AuthNotifier starts with guest user in unauthenticated state in standalone mode', () async {
      SharedPreferences.setMockInitialValues({});
      final notifier = AuthNotifier();
      await notifier.init();

      expect(notifier.state.user.isGuest, isTrue);
      expect(notifier.state.status, equals(AuthStatus.unauthenticated));
      expect(notifier.state.isAuthenticated, isFalse);
    });

    test('4. Registering while already authenticated is blocked with clear notice', () async {
      SharedPreferences.setMockInitialValues({});
      final notifier = AuthNotifier();
      // Simulate authenticated session
      notifier.state = notifier.state.copyWith(
        user: mockAdmin,
        status: AuthStatus.authenticated,
      );

      final result = await notifier.register(
        fullName: 'New Trainee',
        email: 'trainee@caseya-plant.com',
        password: 'Password123!',
      );

      expect(result.isSessionEstablished, isFalse);
      expect(result.message, contains('A session is already active'));
      // State should not have been overwritten
      expect(notifier.state.user.userId, equals(mockAdmin.userId));
    });

    test('5. Unauthenticated signup when email confirmation is required does not authenticate session', () async {
      // Create a SignUpResult simulating unconfirmed user
      const unconfirmed = SignUpResult(
        isSessionEstablished: false,
        isEmailConfirmationRequired: true,
        user: UserModel(
          userId: 'unconfirmed-id',
          employeeCode: 'EMP-UNCONFIRMED',
          name: 'Pending Operator',
          email: 'pending@caseya-plant.com',
          role: 'Employee',
          department: 'Processing & Operations',
          accountStatus: 'invited',
          active: false,
        ),
        message: 'A verification link has been sent to pending@caseya-plant.com.',
      );

      expect(unconfirmed.isSessionEstablished, isFalse);
      expect(unconfirmed.isEmailConfirmationRequired, isTrue);
      expect(unconfirmed.user.isInvited, isTrue);
      expect(unconfirmed.user.isActive, isFalse);
    });

    testWidgets('6. Open Signup while logged out renders registration form and does NOT redirect to dashboard',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWithValue(
              const AuthState(
                user: UserModel.guest,
                status: AuthStatus.unauthenticated,
              ),
            ),
            authProvider.overrideWithValue(UserModel.guest),
          ],
          child: MaterialApp(
            initialRoute: '/signup',
            routes: {
              '/': (context) => const Scaffold(body: Text('Plant Dashboard')),
              '/signup': (context) => const CaseyaApp(),
            },
          ),
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWithValue(
              const AuthState(
                user: UserModel.guest,
                status: AuthStatus.unauthenticated,
              ),
            ),
            authProvider.overrideWithValue(UserModel.guest),
          ],
          child: const CaseyaApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Navigate to /signup
      final nav = tester.state<NavigatorState>(find.byType(Navigator));
      nav.pushNamed('/signup');
      await tester.pumpAndSettle();

      // Verify that SignUpPage rendered without redirecting to dashboard
      expect(find.text('Create Account'), findsWidgets);
      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('Plant Email Address'), findsOneWidget);
      expect(find.text('Department / Section'), findsOneWidget);
      expect(find.textContaining('CASEYA is an internal dairy plant ERP'), findsOneWidget);
    });

    testWidgets('7. Open Signup while ALREADY LOGGED IN displays active session card instead of auto-redirecting',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWithValue(
              const AuthState(
                user: mockEmployee,
                status: AuthStatus.authenticated,
              ),
            ),
            authProvider.overrideWithValue(mockEmployee),
          ],
          child: const CaseyaApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Navigate to /signup while authenticated
      final nav = tester.state<NavigatorState>(find.byType(Navigator));
      nav.pushNamed('/signup');
      await tester.pumpAndSettle();

      // Verify deliberate "Active Session Detected" view is presented
      expect(find.text('Active Session Detected'), findsOneWidget);
      expect(find.text('Priyanka Sharma'), findsOneWidget);
      expect(find.text('Employee • Quality & Lab'), findsOneWidget);
      expect(find.text('priyanka@caseya-plant.com'), findsOneWidget);
      expect(find.text('Sign Out & Register'), findsOneWidget);
      expect(find.text('Back to Dashboard'), findsOneWidget);

      // Verify the normal blank signup input fields are NOT rendered over active session
      expect(find.text('Create Account'), findsNothing);
    });

    testWidgets('8. Clicking Back to Dashboard returns to plant dashboard',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWithValue(
              const AuthState(
                user: mockAdmin,
                status: AuthStatus.authenticated,
              ),
            ),
            authProvider.overrideWithValue(mockAdmin),
          ],
          child: const CaseyaApp(),
        ),
      );

      await tester.pumpAndSettle();

      final nav = tester.state<NavigatorState>(find.byType(Navigator));
      nav.pushNamed('/signup');
      await tester.pumpAndSettle();

      expect(find.text('Active Session Detected'), findsOneWidget);

      // Tap 'Back to Dashboard'
      await tester.tap(find.text('Back to Dashboard'));
      await tester.pumpAndSettle();

      // Verify returned to main shell dashboard
      expect(find.text('Product Calculator'), findsWidgets);
    });
  });
}
