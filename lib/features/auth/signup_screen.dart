import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/auth/auth_service.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import 'widgets/auth_widgets.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;
  bool _googleLoading = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    final email = _emailCtrl.text.trim();
    final password = _passCtrl.text;
    final confirm = _confirmCtrl.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Please fill in all fields.');
      return;
    }
    if (password != confirm) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }
    if (password.length < 8) {
      setState(() => _error = 'Password must be at least 8 characters.');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await AuthService.signUp(email: email, password: password);
      // GoRouter redirect moves to /auth/verify-email (AuthUnverified state)
    } catch (e) {
      setState(() => _error = _friendlyError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signUpWithGoogle() async {
    setState(() { _googleLoading = true; _error = null; });
    try {
      await AuthService.signInWithGoogle();
    } catch (e) {
      setState(() => _error = _friendlyError(e));
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  String _friendlyError(Object e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('already registered') || msg.contains('already been registered')) {
      return 'An account with this email already exists. Sign in instead?';
    }
    if (msg.contains('weak password')) return 'Password is too weak.';
    if (msg.contains('rate limit') || msg.contains('over_email_send_rate_limit')) {
      return 'Too many attempts. Please wait a minute and try again.';
    }
    if (msg.contains('invalid email') || msg.contains('unable to validate email')) {
      return 'Please enter a valid email address.';
    }
    if (msg.contains('network') || msg.contains('socket') || msg.contains('connection')) {
      return 'Network error. Check your connection.';
    }
    // Show raw error for diagnostics
    return e.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Text('Create account', style: AppTypography.displayMd),
              const SizedBox(height: 6),
              Text(
                'Start building your visual memory',
                style: AppTypography.bodyMd.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 36),

              if (_error != null) ...[
                AuthErrorBanner(message: _error!),
                const SizedBox(height: 20),
              ],

              AuthTextField(
                controller: _emailCtrl,
                label: 'Email',
                hint: 'you@example.com',
                keyboardType: TextInputType.emailAddress,
                autofocus: true,
              ),
              const SizedBox(height: 16),
              AuthTextField(
                controller: _passCtrl,
                label: 'Password',
                hint: '••••••••',
                obscure: true,
              ),
              const SizedBox(height: 16),
              AuthTextField(
                controller: _confirmCtrl,
                label: 'Confirm password',
                hint: '••••••••',
                obscure: true,
                textInputAction: TextInputAction.done,
                onEditingComplete: _signUp,
              ),
              const SizedBox(height: 24),

              AuthPrimaryButton(
                label: 'Create account',
                onPressed: _signUp,
                loading: _loading,
              ),
              const SizedBox(height: 16),
              const AuthDivider(),
              const SizedBox(height: 16),
              AuthGoogleButton(
                onPressed: _signUpWithGoogle,
                loading: _googleLoading,
              ),
              const SizedBox(height: 32),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Already have an account? ',
                    style: AppTypography.bodyMd.copyWith(color: AppColors.textSecondary),
                  ),
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Text(
                      'Sign in',
                      style: AppTypography.bodyMd.copyWith(color: AppColors.accentText),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
