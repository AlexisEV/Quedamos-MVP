// estimacion por persona del itinerario frente al presupuesto del plan (rb08, rf12)
class EstimacionPresupuesto {
  const EstimacionPresupuesto({
    required this.presupuestoSoles,
    required this.totalEstimado,
    required this.actividades,
    required this.sinPrecio,
    required this.incompleta,
    required this.excede,
  });

  // fila devuelta por obtener_estimacion_presupuesto
  factory EstimacionPresupuesto.fromJson(Map<String, dynamic> json) {
    return EstimacionPresupuesto(
      presupuestoSoles: (json['presupuesto_soles'] as num).toDouble(),
      totalEstimado: (json['total_estimado'] as num).toDouble(),
      actividades: json['actividades'] as int,
      sinPrecio: json['sin_precio'] as int,
      incompleta: json['incompleta'] as bool,
      excede: json['excede'] as bool,
    );
  }

  final double presupuestoSoles;
  // suma de los precios conocidos; no incluye las actividades sin precio
  final double totalEstimado;
  final int actividades;
  final int sinPrecio;
  final bool incompleta;
  final bool excede;

  double get exceso => excede ? totalEstimado - presupuestoSoles : 0;

  // fraccion del presupuesto usada, limitada a 1 para la barra
  double get uso {
    if (presupuestoSoles <= 0) return totalEstimado > 0 ? 1 : 0;
    final fraccion = totalEstimado / presupuestoSoles;
    return fraccion > 1 ? 1 : fraccion;
  }
}
