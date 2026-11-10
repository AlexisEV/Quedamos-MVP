import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
import 'notificacion_model.dart';

// filas propias de notificaciones (rls) y marcas de entregada o leida (rf14)
class NotificacionesRepository {
  NotificacionesRepository(this._cliente);

  final SupabaseClient _cliente;

  // suficiente para el historial y los recordatorios futuros del mvp
  static const maxFilas = 200;

  Future<List<NotificacionModel>> obtenerNotificaciones() async {
    try {
      final filas = await _cliente
          .from('notificaciones')
          .select(
            'id, id_local, plan_id, tipo, titulo, cuerpo, ruta_destino, '
            'programada_para, estado, entregada_en, leida_en, planes(nombre)',
          )
          .order('programada_para', ascending: false)
          .limit(maxFilas);
      return filas.map(NotificacionModel.fromJson).toList();
    } catch (error) {
      throw traducirError(error);
    }
  }

  Future<void> marcar(
    List<String> ids, {
    bool entregada = false,
    bool leida = false,
  }) async {
    if (ids.isEmpty) return;
    try {
      await _cliente.rpc(
        'marcar_notificaciones',
        params: {'p_ids': ids, 'p_entregada': entregada, 'p_leida': leida},
      );
    } catch (error) {
      throw traducirError(error);
    }
  }
}
