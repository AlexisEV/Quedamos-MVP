import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
import '../../salidas/data/plan_model.dart';
import 'propuesta_model.dart';

class PropuestasRepository {
  PropuestasRepository(this._cliente);

  final SupabaseClient _cliente;
  final _cambios = StreamController<String>.broadcast();

  // emite el id del plan cuyas propuestas cambiaron, para recargar sus vistas
  Stream<String> get cambios => _cambios.stream;

  String? get usuarioActualId => _cliente.auth.currentUser?.id;

  String _usuarioId() {
    final id = _cliente.auth.currentUser?.id;
    if (id == null) throw const AppException(MensajesError.sinSesion);
    return id;
  }

  // propuestas visibles para quien participa en el plan, de la mas antigua a la mas reciente
  Future<List<PropuestaModel>> obtenerPropuestas(String planId) async {
    try {
      final filas = await _cliente
          .from('propuestas')
          .select(
            'id, plan_id, lugar_id, propuesto_por, created_at, '
            'lugares(nombre, categoria), perfiles(nombre_visible)',
          )
          .eq('plan_id', planId)
          .order('created_at', ascending: true);
      return filas.map(PropuestaModel.fromJson).toList();
    } catch (error) {
      throw traducirError(error);
    }
  }

  // planes del usuario en recibiendo_propuestas con su cupo usado y lugares ya propuestos
  Future<List<DestinoPlan>> obtenerDestinos() async {
    final usuarioId = _usuarioId();
    try {
      final filas = await _cliente
          .from('participaciones')
          .select('rol, es_creador, planes!inner(*, participaciones(count))')
          .eq('perfil_id', usuarioId)
          .eq('planes.estado', EstadoPlan.recibiendoPropuestas.valor);
      final salidas = filas.map(SalidaModel.fromJson).toList()
        ..sort((a, b) => b.plan.createdAt.compareTo(a.plan.createdAt));
      if (salidas.isEmpty) return const [];
      final propuestas = await _cliente
          .from('propuestas')
          .select('plan_id, lugar_id, propuesto_por')
          .inFilter('plan_id', [for (final s in salidas) s.plan.id]);
      return [
        for (final salida in salidas)
          DestinoPlan(
            salida: salida,
            misPropuestas: propuestas
                .where(
                  (p) =>
                      p['plan_id'] == salida.plan.id &&
                      p['propuesto_por'] == usuarioId,
                )
                .length,
            lugaresPropuestos: {
              for (final p in propuestas)
                if (p['plan_id'] == salida.plan.id) p['lugar_id'] as String,
            },
          ),
      ];
    } catch (error) {
      throw traducirError(error);
    }
  }

  // repetir con el mismo lugar no duplica la propuesta (ver proponer_lugar)
  Future<void> proponer({
    required String planId,
    required String lugarId,
  }) async {
    try {
      await _cliente.rpc(
        'proponer_lugar',
        params: {'p_plan_id': planId, 'p_lugar_id': lugarId},
      );
      _cambios.add(planId);
    } catch (error) {
      throw traducirError(error);
    }
  }

  // retirar una propuesta que ya no existe no falla (ver retirar_propuesta)
  Future<void> retirar(PropuestaModel propuesta) async {
    try {
      await _cliente.rpc(
        'retirar_propuesta',
        params: {'p_propuesta_id': propuesta.id},
      );
      _cambios.add(propuesta.planId);
    } catch (error) {
      throw traducirError(error);
    }
  }
}
