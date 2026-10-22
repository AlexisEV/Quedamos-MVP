import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  AuthRepository(this._cliente);

  final SupabaseClient _cliente;

  bool get haySesion => _cliente.auth.currentSession != null;

  // emite true o false cada vez que se inicia o se cierra la sesion
  Stream<bool> get cambiosDeSesion =>
      _cliente.auth.onAuthStateChange.map((evento) => evento.session != null);
}
