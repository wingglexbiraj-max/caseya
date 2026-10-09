import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:caseya/main.dart';
import 'package:caseya/models/user_model.dart';
import 'package:caseya/providers/auth_provider.dart';

void main() {
  testWidgets('CASEYA application unauthenticated launch smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const ProviderScope(
        child: CaseyaApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Verify login page elements and branding are present
    expect(find.text('CASEYA'), findsWidgets);
    expect(find.text('Sign In'), findsWidgets);
    expect(find.text('Plant Email Address'), findsWidgets);
    expect(find.text('Password'), findsWidgets);
    expect(find.text('Sign In to Plant System'), findsWidgets);
  });

  testWidgets('CASEYA authenticated application launch renders plant dashboard', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    const mockAdmin = UserModel(
      userId: 'test-admin',
      employeeCode: 'ADMIN-01',
      name: 'Biraj Goswami',
      email: 'biraj.goswami@caseya-plant.com',
      role: 'Admin',
      department: 'Processing & Operations',
      accountStatus: 'active',
      active: true,
    );

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

    // Verify dashboard and main modules
    expect(find.text('CASEYA'), findsWidgets);
    expect(find.text('Dashboard'), findsWidgets);
    expect(find.text('Product Calculator'), findsWidgets);
    expect(find.text('Milk Standardization'), findsWidgets);
  });
}
