import 'package:supabase_flutter/supabase_flutter.dart';

sealed class AuthState {
  const AuthState();
}

/// Initial state while the persisted session is being restored from storage.
class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// Signed up but email not yet verified.
class AuthUnverified extends AuthState {
  final User user;
  const AuthUnverified(this.user);
}

class AuthAuthenticated extends AuthState {
  final User user;
  const AuthAuthenticated(this.user);
}
