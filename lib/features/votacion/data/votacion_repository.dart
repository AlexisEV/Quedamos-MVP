import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
import '../../salidas/data/plan_model.dart';
import '../../salidas/data/salidas_repository.dart';
import 'candidato_model.dart';

// lista final, limites, plazos y votos de la votacion (rf05, rf06, rf07, rf14, rf18)
class VotacionRepository {
  VotacionRepository(this._cliente, this._salidas);

  final SupabaseClient _cliente;
  final SalidasRepository _salidas;

  // lista final del plan, en el orden en que se eligio
  Future<List<CandidatoModel>> obtenerCandidatos(String planId) async {
    try {
      final filas = await _cliente
          .from('candidatos')
          .select(
            'id, plan_id, lugar_id, created_at, '
            'lugares(nombre, categoria, zona, precio_estimado_pen)',
          )
          .eq('plan_id', planId)
          .order('created_at', ascending: true);
      return filas.map(CandidatoModel.fromJson).toList();
    } catch (error) {
      throw traducirError(error);
    }
  }

  // el maximo de propuestas por persona no se modifica despues de crear el plan
  Future<PlanModel> actualizarLimites({
    required String planId,
    required int maxCandidatos,
    required int maxSelecciones,
    required int maxActividades,
  }) async {
    try {
      final fila = await _cliente.rpc(
        'actualizar_limites',
        params: {
          'p_plan_id': planId,
          'p_max_candidatos': maxCandidatos,
          'p_max_selecciones': maxSelecciones,
          'p_max_actividades': maxActividades,
        },
      );
      return PlanModel.fromJson(fila as Map<String, dynamic>);
    } catch (error) {
      throw traducirError(error);
    }
  }

  // reemplaza la lista completa; repetirla con los mismos lugares no cambia nada
  Future<void> definirCandidatos({
    required String planId,
    required Set<String> lugarIds,
  }) async {
    try {
      await _cliente.rpc(
        'definir_candidatos',
        params: {'p_plan_id': planId, 'p_lugar_ids': lugarIds.toList()},
      );
    } catch (error) {
      throw traducirError(error);
    }
  }

  // null quita el plazo; los instantes viajan en utc
  Future<PlanModel> definirPlazos({
    required String planId,
    required DateTime? fechaLimiteVoto,
    required DateTime? fechaLimiteAsistencia,
  }) async {
    try {
      final fila = await _cliente.rpc(
        'definir_plazos',
        params: {
          'p_plan_id': planId,
          'p_fecha_limite_voto': fechaLimiteVoto?.toUtc().toIso8601String(),
          'p_fecha_limite_asistencia': fechaLimiteAsistencia
              ?.toUtc()
              .toIso8601String(),
        },
      );
      return PlanModel.fromJson(fila as Map<String, dynamic>);
    } catch (error) {
      throw traducirError(error);
    }
  }

  // irreversible; repetirla con el plan ya en votacion no falla (ver abrir_votacion)
  Future<PlanModel> abrirVotacion(String planId) async {
    try {
      final fila = await _cliente.rpc(
        'abrir_votacion',
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

  // candidatos que el usuario eligio en su ultima seleccion guardada (rls: solo los propios)
  Future<Set<String>> obtenerMisVotos(String planId) async {
    try {
      final filas = await _cliente
          .from('votos')
          .select('candidato_id')
          .eq('plan_id', planId);
      return {for (final fila in filas) fila['candidato_id'] as String};
    } catch (error) {
      throw traducirError(error);
    }
  }

  // total de votos por candidato sin identificar votantes (rb04)
  Future<Map<String, int>> obtenerTotales(String planId) async {
    try {
      final filas = await _cliente.rpc(
        'obtener_totales_votacion',
        params: {'p_plan_id': planId},
      );
      return {
        for (final fila in filas as List<dynamic>)
          (fila as Map<String, dynamic>)['candidato_id'] as String:
              fila['total'] as int,
      };
    } catch (error) {
      throw traducirError(error);
    }
  }

  // reemplaza la seleccion completa; repetirla con los mismos candidatos no duplica votos
  Future<void> guardarVotos({
    required String planId,
    required Set<String> candidatoIds,
  }) async {
    try {
      await _cliente.rpc(
        'guardar_votos',
        params: {'p_plan_id': planId, 'p_candidato_ids': candidatoIds.toList()},
      );
    } catch (error) {
      throw traducirError(error);
    }
  }
}
