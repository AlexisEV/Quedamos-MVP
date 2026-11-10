import '../../lugares/data/lugar_model.dart';

// actividad del itinerario con los datos del lugar (rf12)
class ActividadModel {
  const ActividadModel({
    required this.id,
    required this.planId,
    required this.lugarId,
    required this.posicion,
    this.inicio,
    this.nombreLugar,
    this.categoria,
    this.zona,
    this.direccion,
    this.horarioAtencion,
    this.precioEstimadoPen,
  });

  // fila de actividades_itinerario con
  // lugares(nombre, categoria, zona, direccion, horario_atencion, precio_estimado_pen)
  factory ActividadModel.fromJson(Map<String, dynamic> json) {
    final lugar = json['lugares'] as Map<String, dynamic>?;
    final inicio = json['inicio'] as String?;
    return ActividadModel(
      id: json['id'] as String,
      planId: json['plan_id'] as String,
      lugarId: json['lugar_id'] as String,
      posicion: json['posicion'] as int,
      inicio: inicio == null ? null : DateTime.parse(inicio),
      nombreLugar: lugar?['nombre'] as String?,
      categoria: lugar == null
          ? null
          : CategoriaLugar.desdeValor(lugar['categoria'] as String),
      zona: lugar == null
          ? null
          : ZonaLugar.desdeValor(lugar['zona'] as String),
      direccion: _textoOpcional(lugar?['direccion']),
      horarioAtencion: _textoOpcional(lugar?['horario_atencion']),
      precioEstimadoPen: (lugar?['precio_estimado_pen'] as num?)?.toDouble(),
    );
  }

  final String id;
  final String planId;
  final String lugarId;
  final int posicion;
  // null indica actividad sin fecha y hora asignadas
  final DateTime? inicio;
  // null cuando el lugar dejo de estar publicado (rls no lo devuelve)
  final String? nombreLugar;
  final CategoriaLugar? categoria;
  final ZonaLugar? zona;
  final String? direccion;
  // horario de atencion del lugar, distinto de la hora de la actividad
  final String? horarioAtencion;
  // null cuando el precio es desconocido
  final double? precioEstimadoPen;

  ActividadModel copiarCon({required int posicion, required DateTime? inicio}) {
    return ActividadModel(
      id: id,
      planId: planId,
      lugarId: lugarId,
      posicion: posicion,
      inicio: inicio,
      nombreLugar: nombreLugar,
      categoria: categoria,
      zona: zona,
      direccion: direccion,
      horarioAtencion: horarioAtencion,
      precioEstimadoPen: precioEstimadoPen,
    );
  }

  static String? _textoOpcional(Object? valor) {
    final texto = (valor as String?)?.trim();
    return texto == null || texto.isEmpty ? null : texto;
  }
}
