import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/env.dart';

abstract final class SupabaseService {
  // inicializa el cliente una sola vez; la sesion guardada se restaura aqui
  static Future<void> inicializar() async {
    if (!Env.estaCompleto) {
      throw StateError(
        'Faltan SUPABASE_URL o SUPABASE_ANON_KEY. '
        'Ejecuta con --dart-define-from-file=.env.json',
      );
    }
    await Supabase.initialize(
      url: Env.supabaseUrl,
      publishableKey: Env.supabaseAnonKey,
    );
  }

  static SupabaseClient get cliente => Supabase.instance.client;
}
