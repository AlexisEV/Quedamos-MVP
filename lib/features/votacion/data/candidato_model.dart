import '../../lugares/data/lugar_model.dart';

// lugar de la lista final de votacion elegido por los administradores
class CandidatoModel {
  const CandidatoModel({
    required this.id,
    required this.planId,
    required this.lugarId,
    this.nombreLugar,
    this.categoria,
    this.zona,
    this.precioEstimadoPen,
  });

  // fila de candidatos con lugares(nombre, categoria, zona, precio_estimado_pen)
  factory CandidatoModel.fromJson(Map<String, dynamic> json) {
    final lugar = json['lugares'] as Map<String, dynamic>?;
    return CandidatoModel(
      id: json['id'] as String,
      planId: json['plan_id'] as String,
      lugarId: json['lugar_id'] as String,
      nombreLugar: lugar?['nombre'] as String?,
      categoria: lugar == null
          ? null
          : CategoriaLugar.desdeValor(lugar['categoria'] as String),
      zona: lugar?['zona'] == null
          ? null
          : ZonaLugar.desdeValor(lugar!['zona'] as String),
      precioEstimadoPen: (lugar?['precio_estimado_pen'] as num?)?.toDouble(),
    );
  }

  final String id;
  final String planId;
  final String lugarId;
  // null cuando el lugar dejo de estar publicado (rls no lo devuelve)
  final String? nombreLugar;
  final CategoriaLugar? categoria;
  final ZonaLugar? zona;
  // null cuando el precio es desconocido
  final double? precioEstimadoPen;
}
