import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/auth/auth_service.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import 'widgets/auth_widgets.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _update() async {
    final password = _passCtrl.text;
    final confirm = _confirmCtrl.text;
    if (password.isEmpty) {
      setState(() => _error = 'Please enter a new password.');
      return;
    }
    if (password.length < 8) {
      setState(() => _error = 'Password must be at least 8 characters.');
      return;
    }
    if (password != confirm) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await AuthService.updatePassword(password);
      if (mounted) context.go('/auth/login');
    } catch (e) {
      setState(() => _error = 'Could not update password. The link may have expired.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
              Text('New password', style: AppTypography.displayMd),
              const SizedBox(height: 8),
              Text(
                'Choose a strong password for your account.',
                style: AppTypography.bodyMd.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 32),

              if (_error != null) ...[
                AuthErrorBanner(message: _error!),
                const SizedBox(height: 20),
              ],

              AuthTextField(
                controller: _passCtrl,
                label: 'New password',
                hint: '••••••••',
                obscure: true,
                autofocus: true,
              ),
              const SizedBox(height: 16),
              AuthTextField(
                controller: _confirmCtrl,
                label: 'Confirm password',
                hint: '••••••••',
                obscure: true,
                textInputAction: TextInputAction.done,
                onEditingComplete: _update,
              ),
              const SizedBox(height: 24),

              AuthPrimaryButton(
                label: 'Update password',
                onPressed: _update,
                loading: _loading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
