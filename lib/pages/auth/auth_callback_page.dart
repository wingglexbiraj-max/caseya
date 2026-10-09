import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart';

class AuthCallbackPage extends ConsumerStatefulWidget {
  const AuthCallbackPage({super.key});

  @override
  ConsumerState<AuthCallbackPage> createState() => _AuthCallbackPageState();
}

class _AuthCallbackPageState extends ConsumerState<AuthCallbackPage> {
  String _statusText = 'Verifying secure plant session...';

  @override
  void initState() {
    super.initState();
    _handleCallback();
  }

  Future<void> _handleCallback() async {
    // Wait for Supabase auth listener to process incoming hash/query params
    await Future.delayed(const Duration(milliseconds: 800));

    try {
      final uri = Uri.base;
      final fragment = uri.fragment;
      final queryParams = uri.queryParameters;

      debugPrint('[AuthCallback] Uri: $uri | fragment: $fragment');

      // Check for password recovery or invite flags
      final isRecovery = fragment.contains('type=recovery') ||
          queryParams['type'] == 'recovery' ||
          ref.read(authStateProvider).status == AuthStatus.passwordRecovery;

      if (isRecovery) {
        if (mounted) {
          setState(() {
            _statusText = 'Verified recovery token. Directing to password setup...';
          });
          Navigator.of(context).pushReplacementNamed('/reset-password');
        }
        return;
      }

      // Check if session has been restored
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        if (mounted) {
          setState(() {
            _statusText = 'Authentication confirmed. Loading plant dashboard...';
          });
          Navigator.of(context).pushReplacementNamed('/');
        }
        return;
      }

      // Default timeout redirect to login
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      debugPrint('[AuthCallback] Callback processing error: $e');
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 36),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.05),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/caseya-logo.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Image.asset(
                      'lib/assets/caseya-logo.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                AppConstants.appName,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: AppFontWeights.bold,
                  letterSpacing: 1.5,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _statusText,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
