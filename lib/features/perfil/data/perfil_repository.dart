import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
import 'perfil_model.dart';

class PerfilRepository {
  PerfilRepository(this._cliente);

  final SupabaseClient _cliente;

  static const _columnas = 'id, nombre_visible';

  User _usuarioActual() {
    final usuario = _cliente.auth.currentUser;
    if (usuario == null) throw const AppException(MensajesError.sinSesion);
    return usuario;
  }

  Future<PerfilModel> obtenerPerfilPropio() async {
    final usuario = _usuarioActual();
    try {
      final fila = await _cliente
          .from('perfiles')
          .select(_columnas)
          .eq('id', usuario.id)
          .single();
      return PerfilModel.fromJson(fila, correo: usuario.email);
    } catch (error) {
      throw traducirError(error);
    }
  }

  // update directo permitido por perfiles_update_propio y el grant de la columna
  Future<PerfilModel> actualizarNombreVisible(String nombreVisible) async {
    final usuario = _usuarioActual();
    try {
      final fila = await _cliente
          .from('perfiles')
          .update({'nombre_visible': nombreVisible.trim()})
          .eq('id', usuario.id)
          .select(_columnas)
          .single();
      return PerfilModel.fromJson(fila, correo: usuario.email);
    } catch (error) {
      throw traducirError(error);
    }
  }
}
