import '../../salidas/data/plan_model.dart';
import 'lugar_model.dart';

// propuesta de un lugar en un plan, con el lugar y el autor embebidos
class PropuestaModel {
  const PropuestaModel({
    required this.id,
    required this.planId,
    required this.lugarId,
    required this.propuestoPor,
    required this.nombreAutor,
    required this.createdAt,
    this.nombreLugar,
    this.categoria,
    this.precioEstimadoPen,
  });

  // fila de propuestas con lugares(nombre, categoria, precio_estimado_pen) y perfiles(nombre_visible)
  factory PropuestaModel.fromJson(Map<String, dynamic> json) {
    final lugar = json['lugares'] as Map<String, dynamic>?;
    final perfil = json['perfiles'] as Map<String, dynamic>?;
    return PropuestaModel(
      id: json['id'] as String,
      planId: json['plan_id'] as String,
      lugarId: json['lugar_id'] as String,
      propuestoPor: json['propuesto_por'] as String,
      nombreAutor: (perfil?['nombre_visible'] as String?)?.trim() ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
      nombreLugar: lugar?['nombre'] as String?,
      categoria: lugar == null
          ? null
          : CategoriaLugar.desdeValor(lugar['categoria'] as String),
      precioEstimadoPen: (lugar?['precio_estimado_pen'] as num?)?.toDouble(),
    );
  }

  final String id;
  final String planId;
  final String lugarId;
  final String propuestoPor;
  final String nombreAutor;
  final DateTime createdAt;
  // null cuando el lugar dejo de estar publicado (rls no lo devuelve)
  final String? nombreLugar;
  final CategoriaLugar? categoria;
  // null cuando el precio es desconocido
  final double? precioEstimadoPen;
}

// plan del usuario que recibe propuestas, con su cupo y los lugares ya propuestos
class DestinoPlan {
  const DestinoPlan({
    required this.salida,
    required this.misPropuestas,
    required this.lugaresPropuestos,
  });

  final SalidaModel salida;
  final int misPropuestas;
  final Set<String> lugaresPropuestos;

  PlanModel get plan => salida.plan;
  int get maxPropuestas => plan.maxPropuestasPorPersona;
  bool get limiteAlcanzado => misPropuestas >= maxPropuestas;
  bool yaPropuesto(String lugarId) => lugaresPropuestos.contains(lugarId);
}
