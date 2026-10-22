// configuracion leida en compilacion con --dart-define-from-file=.env.json
abstract final class Env {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static bool get estaCompleto =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
