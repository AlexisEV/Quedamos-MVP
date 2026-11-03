import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
import 'lugar_model.dart';

class LugaresRepository {
  LugaresRepository(this._cliente);

  final SupabaseClient _cliente;

  static const _columnas =
      'id, nombre, categoria, zona, direccion, horario_atencion, '
      'precio_estimado_pen, precio_nota';

  static const maxRecomendaciones = 10;

  // rls solo devuelve lugares publicados; orden alfabetico por nombre
  Future<List<LugarModel>> obtenerLugares() async {
    try {
      final filas = await _cliente
          .from('lugares')
          .select(_columnas)
          .order('nombre', ascending: true);
      return filas.map(LugarModel.fromJson).toList();
    } catch (error) {
      throw traducirError(error);
    }
  }

  // recomendaciones rf13: precio conocido y dentro del presupuesto, de mas
  // economico a mas caro y como maximo 10; el precio null queda fuera por el lte
  Future<List<LugarModel>> obtenerRecomendaciones({
    required ZonaLugar zona,
    required CategoriaLugar categoria,
    required double presupuestoSoles,
  }) async {
    try {
      final filas = await _cliente
          .from('lugares')
          .select(_columnas)
          .eq('zona', zona.valor)
          .eq('categoria', categoria.valor)
          .lte('precio_estimado_pen', presupuestoSoles)
          .order('precio_estimado_pen', ascending: true)
          .order('nombre', ascending: true)
          .limit(maxRecomendaciones);
      return filas.map(LugarModel.fromJson).toList();
    } catch (error) {
      throw traducirError(error);
    }
  }

  // null si el lugar no existe o ya no esta publicado
  Future<LugarModel?> obtenerLugar(String lugarId) async {
    try {
      final fila = await _cliente
          .from('lugares')
          .select(_columnas)
          .eq('id', lugarId)
          .maybeSingle();
      return fila == null ? null : LugarModel.fromJson(fila);
    } catch (error) {
      throw traducirError(error);
    }
  }
}
