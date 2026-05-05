import 'package:supabase_flutter/supabase_flutter.dart';
import '../secrets/app_secrets.dart';

class SupabaseConfig {
  SupabaseConfig._();

  static const String url = AppSecrets.supabaseUrl;
  static const String anonKey = AppSecrets.supabaseAnonKey;
  static const String googleWebClientId = AppSecrets.googleWebClientId;

  static Future<void> initialize() async {
    await Supabase.initialize(url: url, anonKey: anonKey);
  }

  static SupabaseClient get client => Supabase.instance.client;
}
