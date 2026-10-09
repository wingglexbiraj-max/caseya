import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/responsive_layout.dart';
import '../../services/supabase_service.dart';
import '../../providers/auth_provider.dart';

class ResetPasswordPage extends ConsumerStatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  ConsumerState<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends ConsumerState<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isSubmitting = false;
  bool _resetSuccess = false;
  String? _errorMessage;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _hasValidRecoverySession() {
    // If Supabase is initialized, ensure an authenticated recovery session or user is present
    if (SupabaseService.isInitialized) {
      final session = SupabaseService.currentSession;
      return session != null && session.accessToken.isNotEmpty;
    }
    // Standalone test fallback
    return true;
  }

  Future<void> _handleResetPassword() async {
    if (_isSubmitting) return;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final newPassword = _passwordController.text;

    final success = await ref
        .read(authNotifierProvider.notifier)
        .updatePassword(newPassword);

    if (mounted) {
      setState(() {
        _isSubmitting = false;
        if (success) {
          _resetSuccess = true;
        } else {
          final authState = ref.read(authStateProvider);
          _errorMessage = authState.errorMessage ??
              'Unable to update password. Your recovery link may have expired.';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveLayout.isMobile(context);
    final hasValidSession = _hasValidRecoverySession();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 16 : 32,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: Container(
              padding: EdgeInsets.all(isMobile ? 24 : 36),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.cardBorder, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.06),
                    blurRadius: 32,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: _resetSuccess
                  ? _buildSuccessView()
                  : (!hasValidSession
                      ? _buildInvalidSessionView()
                      : _buildFormView()),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormView() {
    final passwordText = _passwordController.text;
    final hasMinLength = passwordText.length >= 8;
    final hasLetter = RegExp(r'[A-Za-z]').hasMatch(passwordText);
    final hasDigit = RegExp(r'[0-9]').hasMatch(passwordText);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildLogoIcon(size: 38),
              TextButton(
                onPressed: () => Navigator.of(context).pushReplacementNamed('/login'),
                child: const Text('Back to Sign In'),
              ),
            ],
          ),
          const SizedBox(height: 24),

          const Text(
            'Create New Password',
            style: TextStyle(
              fontSize: 22,
              fontWeight: AppFontWeights.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Set a secure new password for your plant operations employee account.',
            style: TextStyle(
              fontSize: 13.5,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),

          // Error banner
          if (_errorMessage != null)
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFF87171)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: AppColors.danger, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF991B1B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // New Password Field
          const Text(
            'New Password',
            style: TextStyle(
              fontSize: 13,
              fontWeight: AppFontWeights.semiBold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.next,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Minimum 8 characters',
              prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20, color: AppColors.textSecondary),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.cardBorder, width: 1.2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.cardBorder, width: 1.2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a new password';
              }
              if (value.length < 8) {
                return 'Password must be at least 8 characters long';
              }
              if (!RegExp(r'[A-Za-z]').hasMatch(value)) {
                return 'Password must contain at least one letter';
              }
              if (!RegExp(r'[0-9]').hasMatch(value)) {
                return 'Password must contain at least one number';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),

          // Password requirements visual indicators
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Password Requirements:',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                _buildRuleItem('At least 8 characters', hasMinLength),
                const SizedBox(height: 4),
                _buildRuleItem('Contains letters (A-Z, a-z)', hasLetter),
                const SizedBox(height: 4),
                _buildRuleItem('Contains at least one number (0-9)', hasDigit),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Confirm Password Field
          const Text(
            'Confirm New Password',
            style: TextStyle(
              fontSize: 13,
              fontWeight: AppFontWeights.semiBold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirmPassword,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _handleResetPassword(),
            decoration: InputDecoration(
              hintText: 'Re-enter your new password',
              prefixIcon: const Icon(Icons.lock_reset_rounded, size: 20, color: AppColors.textSecondary),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
                onPressed: () {
                  setState(() {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
                  });
                },
              ),
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.cardBorder, width: 1.2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.cardBorder, width: 1.2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please confirm your password';
              }
              if (value != _passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),

          // Submit Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              onPressed: _isSubmitting ? null : _handleResetPassword,
              child: _isSubmitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Update Password & Sign In',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: AppFontWeights.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRuleItem(String label, bool passed) {
    return Row(
      children: [
        Icon(
          passed ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
          size: 14,
          color: passed ? AppColors.success : AppColors.textSecondary,
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            color: passed ? AppColors.success : AppColors.textSecondary,
            fontWeight: passed ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildInvalidSessionView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFFFEE2E2),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFEF4444), width: 1.5),
          ),
          child: const Icon(
            Icons.link_off_rounded,
            color: Color(0xFFDC2626),
            size: 28,
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Recovery Link Expired or Invalid',
          style: TextStyle(
            fontSize: 20,
            fontWeight: AppFontWeights.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'This password reset link is invalid, has expired, or has already been used. For plant ERP security, please request a fresh reset link.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13.5,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 44,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.of(context).pushReplacementNamed('/forgot-password');
            },
            child: const Text('Request New Reset Link'),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () {
            Navigator.of(context).pushReplacementNamed('/login');
          },
          child: const Text('Return to Sign In'),
        ),
      ],
    );
  }

  Widget _buildSuccessView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFFD1FAE5),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF10B981), width: 1.5),
          ),
          child: const Icon(
            Icons.check_rounded,
            color: Color(0xFF047857),
            size: 32,
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Password Successfully Updated',
          style: TextStyle(
            fontSize: 20,
            fontWeight: AppFontWeights.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Your plant account credentials have been updated securely in Supabase Auth. You can now access Caseya with your new password.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13.5,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.of(context).pushReplacementNamed('/');
            },
            child: const Text(
              'Enter Caseya Plant System',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLogoIcon({required double size}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.cardBorder, width: 1.2),
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/caseya-logo.png',
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => Image.asset(
            'lib/assets/caseya-logo.png',
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Center(
              child: Text(
                'C',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: size * 0.5,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
