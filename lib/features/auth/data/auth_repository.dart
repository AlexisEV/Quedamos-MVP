import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';

class AuthRepository {
  AuthRepository(this._cliente);

  final SupabaseClient _cliente;

  bool get haySesion => _cliente.auth.currentSession != null;

  // emite true o false cada vez que se inicia o se cierra la sesion
  Stream<bool> get cambiosDeSesion =>
      _cliente.auth.onAuthStateChange.map((evento) => evento.session != null);

  // el trigger crear_perfil_de_usuario toma nombre_visible de los metadatos
  Future<void> registrar({
    required String nombreVisible,
    required String correo,
    required String contrasena,
  }) async {
    final AuthResponse respuesta;
    try {
      respuesta = await _cliente.auth.signUp(
        email: correo.trim(),
        password: contrasena,
        data: {'nombre_visible': nombreVisible.trim()},
      );
    } catch (error) {
      throw traducirError(error);
    }
    // con confirm email desactivado la sesion debe quedar iniciada
    if (respuesta.session == null) {
      throw const AppException(MensajesError.generico);
    }
  }

  Future<void> iniciarSesion({
    required String correo,
    required String contrasena,
  }) async {
    try {
      await _cliente.auth.signInWithPassword(
        email: correo.trim(),
        password: contrasena,
      );
    } catch (error) {
      throw traducirError(error);
    }
  }

  // signOut borra la sesion local antes de avisar al servidor; solo falla si sigue activa
  Future<void> cerrarSesion() async {
    try {
      await _cliente.auth.signOut();
    } catch (error) {
      if (haySesion) throw traducirError(error);
    }
  }
}
