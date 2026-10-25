import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
import 'lugar_model.dart';

class LugaresRepository {
  LugaresRepository(this._cliente);

  final SupabaseClient _cliente;

  static const _columnas =
      'id, nombre, categoria, zona, direccion, horario_atencion, '
      'precio_estimado_pen, precio_nota';

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
