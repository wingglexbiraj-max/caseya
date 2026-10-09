import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'services/local_storage_service.dart';
import 'providers/auth_provider.dart';
import 'pages/shell/main_shell_page.dart';
import 'pages/auth/login_page.dart';
import 'pages/auth/signup_page.dart';
import 'pages/auth/forgot_password_page.dart';
import 'pages/auth/reset_password_page.dart';
import 'pages/auth/auth_callback_page.dart';
import 'pages/auth/account_suspended_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configure clean path URL strategy for Flutter Web (e.g. /login instead of /#/login)
  if (kIsWeb) {
    usePathUrlStrategy();
  }

  // Initialize persistent browser local storage and seeds
  await LocalStorageService.init();

  runApp(
    const ProviderScope(
      child: CaseyaApp(),
    ),
  );
}

class CaseyaApp extends ConsumerWidget {
  const CaseyaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return MaterialApp(
      title: '${AppConstants.appName} — ${AppConstants.appSubtitle}',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: '/',
      onGenerateRoute: (settings) {
        final uri = Uri.tryParse(settings.name ?? '/');
        final path = uri?.path ?? '/';

        debugPrint('[Router] Navigating to path: $path | AuthStatus: ${authState.status}');

        // 1. Account Suspended check
        if (authState.status == AuthStatus.accountSuspended) {
          return MaterialPageRoute(
            builder: (_) => const AccountSuspendedPage(),
            settings: settings,
          );
        }

        // 2. Auth Callback Route
        if (path == '/callback' ||
            (kIsWeb && Uri.base.toString().contains('type='))) {
          return MaterialPageRoute(
            builder: (_) => const AuthCallbackPage(),
            settings: settings,
          );
        }

        // 3. Password Recovery Route
        if (path == '/reset-password' ||
            authState.status == AuthStatus.passwordRecovery ||
            (kIsWeb && Uri.base.toString().contains('type=recovery'))) {
          return MaterialPageRoute(
            builder: (_) => const ResetPasswordPage(),
            settings: settings,
          );
        }

        // 4. Forgot Password Route
        if (path == '/forgot-password') {
          return MaterialPageRoute(
            builder: (_) => const ForgotPasswordPage(),
            settings: settings,
          );
        }

        // 5. Sign Up Route
        if (path == '/signup') {
          if (authState.isAuthenticated) {
            return MaterialPageRoute(
              builder: (_) => const MainShellPage(),
              settings: const RouteSettings(name: '/'),
            );
          }
          return MaterialPageRoute(
            builder: (_) => const SignUpPage(),
            settings: settings,
          );
        }

        // 6. Unauthenticated State Guard
        if (!authState.isAuthenticated) {
          return MaterialPageRoute(
            builder: (_) => const LoginPage(),
            settings: settings,
          );
        }

        // 7. Authenticated State: If navigating to /login, /signup, or /forgot-password, redirect to Home
        if (path == '/login' || path == '/signup' || path == '/forgot-password') {
          return MaterialPageRoute(
            builder: (_) => const MainShellPage(),
            settings: const RouteSettings(name: '/'),
          );
        }

        // 8. Protected Shell Route (Default)
        return MaterialPageRoute(
          builder: (_) => const MainShellPage(),
          settings: settings,
        );
      },
    );
  }
}
