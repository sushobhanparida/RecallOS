import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/auth/auth_service.dart';
import '../../core/auth/auth_state.dart';
import '../../core/supabase/supabase_config.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import 'widgets/auth_widgets.dart';

class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  bool _resendLoading = false;
  bool _resendSent = false;
  String? _error;

  String get _email =>
      (ref.read(authProvider) is AuthUnverified
          ? (ref.read(authProvider) as AuthUnverified).user.email
          : null) ??
      SupabaseConfig.client.auth.currentUser?.email ??
      '';

  Future<void> _resend() async {
    setState(() { _resendLoading = true; _error = null; _resendSent = false; });
    try {
      await AuthService.resendVerificationEmail(_email);
      setState(() => _resendSent = true);
    } catch (e) {
      setState(() => _error = 'Could not resend email. Try again shortly.');
    } finally {
      if (mounted) setState(() => _resendLoading = false);
    }
  }

  Future<void> _signOut() async {
    await AuthService.signOut();
    if (mounted) context.go('/auth/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.accentMuted,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.mail_outline_rounded, color: AppColors.accentText, size: 24),
              ),
              const SizedBox(height: 20),
              Text('Check your inbox', style: AppTypography.displayMd),
              const SizedBox(height: 8),
              RichText(
                text: TextSpan(
                  style: AppTypography.bodyMd.copyWith(color: AppColors.textSecondary),
                  children: [
                    const TextSpan(text: 'We sent a verification link to '),
                    TextSpan(
                      text: _email,
                      style: AppTypography.bodyMd.copyWith(color: AppColors.textPrimary),
                    ),
                    const TextSpan(text: '. Click it to activate your account.'),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              if (_error != null) ...[
                AuthErrorBanner(message: _error!),
                const SizedBox(height: 16),
              ],
              if (_resendSent) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.successMuted,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Verification email resent.',
                    style: AppTypography.bodySm.copyWith(color: AppColors.success),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              AuthPrimaryButton(
                label: 'Resend email',
                onPressed: _resend,
                loading: _resendLoading,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: OutlinedButton(
                  onPressed: _signOut,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: const BorderSide(color: AppColors.borderDefault),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text('Back to sign in', style: AppTypography.labelLg.copyWith(color: AppColors.textSecondary)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
