import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/auth/auth_service.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import 'widgets/auth_widgets.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  bool _loading = false;
  bool _sent = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'Please enter your email address.');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await AuthService.resetPasswordForEmail(email);
      setState(() => _sent = true);
    } catch (e) {
      setState(() => _error = 'Could not send reset email. Try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: AppBar(
        backgroundColor: AppColors.bgBase,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textSecondary),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Reset password', style: AppTypography.displayMd),
              const SizedBox(height: 8),
              Text(
                'Enter your email and we\'ll send you a reset link.',
                style: AppTypography.bodyMd.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 32),

              if (_error != null) ...[
                AuthErrorBanner(message: _error!),
                const SizedBox(height: 20),
              ],

              if (_sent) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.successMuted,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Reset link sent — check your email.',
                    style: AppTypography.bodySm.copyWith(color: AppColors.success),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              AuthTextField(
                controller: _emailCtrl,
                label: 'Email',
                hint: 'you@example.com',
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                onEditingComplete: _send,
                autofocus: true,
              ),
              const SizedBox(height: 24),

              AuthPrimaryButton(
                label: 'Send reset link',
                onPressed: _send,
                loading: _loading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
