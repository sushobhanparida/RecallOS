import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/auth/auth_service.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import 'widgets/auth_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  bool _googleLoading = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final email = _emailCtrl.text.trim();
    final password = _passCtrl.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Please enter your email and password.');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await AuthService.signInWithPassword(email: email, password: password);
      // GoRouter redirect handles navigation
    } catch (e) {
      setState(() => _error = _friendlyError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
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
    if (msg.contains('invalid login credentials') || msg.contains('invalid_credentials')) {
      return 'Incorrect email or password.';
    }
    if (msg.contains('email not confirmed')) {
      return 'Please verify your email before signing in.';
    }
    if (msg.contains('rate limit') || msg.contains('over_email_send_rate_limit')) {
      return 'Too many attempts. Please wait a minute and try again.';
    }
    if (msg.contains('network') || msg.contains('socket') || msg.contains('connection')) {
      return 'Network error. Check your connection.';
    }
    // Show raw error for diagnostics
    return 'Sign in failed: ${e.toString()}';
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
              Text('Welcome back', style: AppTypography.displayMd),
              const SizedBox(height: 6),
              Text(
                'Sign in to your RecallOS account',
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
                textInputAction: TextInputAction.done,
                onEditingComplete: _signIn,
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () => context.push('/auth/forgot-password'),
                  child: Text(
                    'Forgot password?',
                    style: AppTypography.labelMd.copyWith(color: AppColors.accentText),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              AuthPrimaryButton(
                label: 'Sign in',
                onPressed: _signIn,
                loading: _loading,
              ),
              const SizedBox(height: 16),
              const AuthDivider(),
              const SizedBox(height: 16),
              AuthGoogleButton(
                onPressed: _signInWithGoogle,
                loading: _googleLoading,
              ),
              const SizedBox(height: 32),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account? ",
                    style: AppTypography.bodyMd.copyWith(color: AppColors.textSecondary),
                  ),
                  GestureDetector(
                    onTap: () => context.push('/auth/signup'),
                    child: Text(
                      'Sign up',
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
