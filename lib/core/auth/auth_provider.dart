import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import '../supabase/supabase_config.dart';
import 'auth_state.dart';

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthInitial()) {
    final session = SupabaseConfig.client.auth.currentSession;
    state = session != null
        ? _stateFromUser(session.user)
        : const AuthUnauthenticated();

    _sub = SupabaseConfig.client.auth.onAuthStateChange.listen((event) {
      final s = event.session;
      state = s != null ? _stateFromUser(s.user) : const AuthUnauthenticated();
    });
  }

  late final StreamSubscription<supa.AuthState> _sub;

  AuthState _stateFromUser(supa.User user) {
    final isVerified = user.emailConfirmedAt != null;
    final isGoogle = user.appMetadata['provider'] == 'google' ||
        (user.identities ?? []).any((id) => id.provider == 'google');
    if (isVerified || isGoogle) return AuthAuthenticated(user);
    return AuthUnverified(user);
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (_) => AuthNotifier(),
);

/// ChangeNotifier wrapper so GoRouter can use refreshListenable.
class AuthRouterNotifier extends ChangeNotifier {
  AuthRouterNotifier(Ref ref) {
    ref.listen<AuthState>(authProvider, (_, __) => notifyListeners());
  }
}
