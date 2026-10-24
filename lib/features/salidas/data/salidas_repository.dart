import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
import 'plan_model.dart';

// datos del formulario de crear plan; los limites llegan ya validados por rango
class NuevoPlan {
  const NuevoPlan({
    required this.id,
    required this.nombre,
    required this.presupuestoSoles,
    required this.maxPropuestas,
    required this.maxCandidatos,
    required this.maxSelecciones,
    required this.maxActividades,
  });

  final String id;
  final String nombre;
  final double presupuestoSoles;
  final int maxPropuestas;
  final int maxCandidatos;
  final int maxSelecciones;
  final int maxActividades;
}

// respuesta de unirse_con_codigo
class ResultadoUnion {
  const ResultadoUnion({required this.planId, required this.yaParticipaba});

  factory ResultadoUnion.fromJson(Map<String, dynamic> json) => ResultadoUnion(
    planId: json['plan_id'] as String,
    yaParticipaba: json['ya_participaba'] as bool,
  );

  final String planId;
  final bool yaParticipaba;
}

class SalidasRepository {
  SalidasRepository(this._cliente);

  final SupabaseClient _cliente;
  final _cambios = StreamController<void>.broadcast();

  static const _columnas = 'rol, es_creador, planes(*, participaciones(count))';

  // avisa que la lista de salidas del usuario cambio, para recargarla
  Stream<void> get cambios => _cambios.stream;

  String _usuarioId() {
    final id = _cliente.auth.currentUser?.id;
    if (id == null) throw const AppException(MensajesError.sinSesion);
    return id;
  }

  // planes donde participa el usuario, del mas reciente al mas antiguo
  Future<List<SalidaModel>> obtenerMisSalidas() async {
    final usuarioId = _usuarioId();
    try {
      final filas = await _cliente
          .from('participaciones')
          .select(_columnas)
          .eq('perfil_id', usuarioId);
      final salidas = filas.map(SalidaModel.fromJson).toList()
        ..sort((a, b) => b.plan.createdAt.compareTo(a.plan.createdAt));
      return salidas;
    } catch (error) {
      throw traducirError(error);
    }
  }

  // null si el plan no existe o el usuario no participa (rls)
  Future<SalidaModel?> obtenerSalida(String planId) async {
    final usuarioId = _usuarioId();
    try {
      final fila = await _cliente
          .from('participaciones')
          .select(_columnas)
          .eq('perfil_id', usuarioId)
          .eq('plan_id', planId)
          .maybeSingle();
      return fila == null ? null : SalidaModel.fromJson(fila);
    } catch (error) {
      throw traducirError(error);
    }
  }

  // repetir con el mismo id no duplica el plan (ver crear_plan)
  Future<PlanModel> crearPlan(NuevoPlan nuevo) async {
    try {
      final fila = await _cliente.rpc(
        'crear_plan',
        params: {
          'p_plan_id': nuevo.id,
          'p_nombre': nuevo.nombre.trim(),
          'p_presupuesto_soles': nuevo.presupuestoSoles,
          'p_max_propuestas': nuevo.maxPropuestas,
          'p_max_candidatos': nuevo.maxCandidatos,
          'p_max_selecciones': nuevo.maxSelecciones,
          'p_max_actividades': nuevo.maxActividades,
        },
      );
      final plan = PlanModel.fromJson(fila as Map<String, dynamic>);
      _cambios.add(null);
      return plan;
    } catch (error) {
      throw traducirError(error);
    }
  }

  // repetir el codigo no duplica la participacion (ver unirse_con_codigo)
  Future<ResultadoUnion> unirseConCodigo(String codigo) async {
    try {
      final respuesta = await _cliente.rpc(
        'unirse_con_codigo',
        params: {'p_codigo': codigo.trim().toUpperCase()},
      );
      final resultado = ResultadoUnion.fromJson(
        respuesta as Map<String, dynamic>,
      );
      if (!resultado.yaParticipaba) _cambios.add(null);
      return resultado;
    } catch (error) {
      throw traducirError(error);
    }
  }
}
