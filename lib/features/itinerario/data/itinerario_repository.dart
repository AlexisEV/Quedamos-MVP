import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
import '../../salidas/data/plan_model.dart';
import '../../salidas/data/salidas_repository.dart';
import 'actividad_model.dart';
import 'cambio_plan_model.dart';
import 'estimacion_presupuesto.dart';

// orden, fecha y hora, estimacion y confirmacion del itinerario (rf08, rf12, rb08)
class ItinerarioRepository {
  ItinerarioRepository(this._cliente, this._salidas);

  final SupabaseClient _cliente;
  final SalidasRepository _salidas;

  // actividades en orden de ejecucion
  Future<List<ActividadModel>> obtenerActividades(String planId) async {
    try {
      final filas = await _cliente
          .from('actividades_itinerario')
          .select(
            'id, plan_id, lugar_id, posicion, inicio, '
            'lugares(nombre, categoria, zona, direccion, horario_atencion, '
            'precio_estimado_pen)',
          )
          .eq('plan_id', planId)
          .order('posicion', ascending: true);
      return filas.map(ActividadModel.fromJson).toList();
    } catch (error) {
      throw traducirError(error);
    }
  }

  Future<EstimacionPresupuesto> obtenerEstimacion(String planId) async {
    try {
      final filas = await _cliente.rpc(
        'obtener_estimacion_presupuesto',
        params: {'p_plan_id': planId},
      );
      final lista = filas as List<dynamic>;
      return EstimacionPresupuesto.fromJson(
        lista.first as Map<String, dynamic>,
      );
    } catch (error) {
      throw traducirError(error);
    }
  }

  // envia todas las actividades en el orden de la lista; repetirla no cambia nada
  Future<void> guardarItinerario({
    required String planId,
    required List<ActividadModel> actividades,
  }) async {
    try {
      await _cliente.rpc(
        'guardar_itinerario',
        params: {
          'p_plan_id': planId,
          'p_actividades': [
            for (final actividad in actividades)
              {
                'id': actividad.id,
                'inicio': actividad.inicio?.toUtc().toIso8601String(),
              },
          ],
        },
      );
    } catch (error) {
      throw traducirError(error);
    }
  }

  // cambia el lugar de una actividad confirmada sin votacion; conserva posicion e inicio
  // y repetirla con el mismo lugar no cambia nada (rf10, rb11)
  Future<ActividadModel> reemplazarActividad({
    required String actividadId,
    required String lugarId,
  }) async {
    try {
      final fila = await _cliente.rpc(
        'reemplazar_actividad',
        params: {'p_actividad_id': actividadId, 'p_lugar_id': lugarId},
      );
      return ActividadModel.fromJson(fila as Map<String, dynamic>);
    } catch (error) {
      throw traducirError(error);
    }
  }

  // nueva fecha y hora de una actividad confirmada; debe ser futura (rf10)
  Future<ActividadModel> cambiarHorario({
    required String actividadId,
    required DateTime inicio,
  }) async {
    try {
      final fila = await _cliente.rpc(
        'cambiar_horario_actividad',
        params: {
          'p_actividad_id': actividadId,
          'p_inicio': inicio.toUtc().toIso8601String(),
        },
      );
      return ActividadModel.fromJson(fila as Map<String, dynamic>);
    } catch (error) {
      throw traducirError(error);
    }
  }

  // historial del plan, del cambio mas reciente al mas antiguo
  Future<List<CambioPlanModel>> obtenerCambios(String planId) async {
    try {
      final filas = await _cliente
          .from('cambios_plan')
          .select(
            'id, tipo, created_at, inicio_anterior, inicio_nuevo, '
            'anterior:lugares!lugar_anterior_id(nombre), '
            'nuevo:lugares!lugar_nuevo_id(nombre), '
            'perfiles(nombre_visible)',
          )
          .eq('plan_id', planId)
          .order('created_at', ascending: false);
      return filas.map(CambioPlanModel.fromJson).toList();
    } catch (error) {
      throw traducirError(error);
    }
  }

  // irreversible; repetirla con el plan ya confirmado devuelve el plan sin error
  Future<PlanModel> confirmarPlan(String planId) async {
    try {
      final fila = await _cliente.rpc(
        'confirmar_plan',
        params: {'p_plan_id': planId},
      );
      final plan = PlanModel.fromJson(fila as Map<String, dynamic>);
      // mis salidas muestra la nueva fase
      _salidas.avisarCambio();
      return plan;
    } catch (error) {
      throw traducirError(error);
    }
  }
}
