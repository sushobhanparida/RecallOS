import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import '../supabase/supabase_config.dart';

enum EmailCheckResult { exists, notFound, error }

class AuthService {
  AuthService._();

  static final _client = SupabaseConfig.client;

  static final _googleSignIn = GoogleSignIn(
    serverClientId: SupabaseConfig.googleWebClientId,
  );

  static Future<void> signUp({
    required String email,
    required String password,
  }) async {
    await _client.auth.signUp(
      email: email,
      password: password,
      emailRedirectTo: 'recallos://auth/callback',
    );
  }

  static Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  static Future<void> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return; // user cancelled
    final googleAuth = await googleUser.authentication;
    if (googleAuth.idToken == null) throw Exception('Google sign-in failed: no ID token');
    await _client.auth.signInWithIdToken(
      provider: supa.OAuthProvider.google,
      idToken: googleAuth.idToken!,
      accessToken: googleAuth.accessToken,
    );
  }

  static Future<void> signOut() async {
    await _googleSignIn.signOut().catchError((_) {});
    await _client.auth.signOut();
  }

  static Future<void> resetPasswordForEmail(String email) async {
    await _client.auth.resetPasswordForEmail(
      email,
      redirectTo: 'recallos://auth/callback?type=recovery',
    );
  }

  static Future<void> resendVerificationEmail(String email) async {
    await _client.auth.resend(
      type: supa.OtpType.signup,
      email: email,
    );
  }

  static Future<void> updatePassword(String newPassword) async {
    await _client.auth.updateUser(supa.UserAttributes(password: newPassword));
  }

  // Probes email existence via OTP with shouldCreateUser=false.
  // Existing users: OTP email sent (harmless, ignored); returns exists.
  // New users: AuthException thrown; returns notFound.
  // Replace with a Supabase Edge Function for a cleaner production implementation.
  static Future<EmailCheckResult> checkEmailExists(String email) async {
    try {
      await _client.auth.signInWithOtp(
        email: email,
        shouldCreateUser: false,
      );
      return EmailCheckResult.exists;
    } on supa.AuthException catch (e) {
      final msg = e.message.toLowerCase();
      if (msg.contains('not allowed') ||
          msg.contains('not found') ||
          msg.contains('otp') ||
          msg.contains('signup') ||
          msg.contains('disabled')) {
        return EmailCheckResult.notFound;
      }
      return EmailCheckResult.error;
    } catch (_) {
      return EmailCheckResult.error;
    }
  }
}
