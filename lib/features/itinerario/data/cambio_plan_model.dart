// tipos de cambio del historial; el valor coincide con cambios_plan.tipo (rf10)
enum TipoCambio {
  reemplazo('reemplazo', 'Actividad reemplazada'),
  horario('horario', 'Horario cambiado'),
  cancelacion('cancelacion', 'Salida cancelada');

  const TipoCambio(this.valor, this.etiqueta);

  final String valor;
  final String etiqueta;

  static TipoCambio desdeValor(String valor) =>
      values.firstWhere((tipo) => tipo.valor == valor);
}

// fila del historial de cambios del plan con los nombres de lugares y autor
class CambioPlanModel {
  const CambioPlanModel({
    required this.id,
    required this.tipo,
    required this.creadoEn,
    this.lugarAnterior,
    this.lugarNuevo,
    this.inicioAnterior,
    this.inicioNuevo,
    this.realizadoPor,
  });

  // fila de cambios_plan con anterior:lugares(nombre), nuevo:lugares(nombre)
  // y perfiles(nombre_visible)
  factory CambioPlanModel.fromJson(Map<String, dynamic> json) {
    final anterior = json['anterior'] as Map<String, dynamic>?;
    final nuevo = json['nuevo'] as Map<String, dynamic>?;
    final autor = json['perfiles'] as Map<String, dynamic>?;
    return CambioPlanModel(
      id: json['id'] as String,
      tipo: TipoCambio.desdeValor(json['tipo'] as String),
      creadoEn: DateTime.parse(json['created_at'] as String).toUtc(),
      lugarAnterior: anterior?['nombre'] as String?,
      lugarNuevo: nuevo?['nombre'] as String?,
      inicioAnterior: _fecha(json['inicio_anterior']),
      inicioNuevo: _fecha(json['inicio_nuevo']),
      realizadoPor: autor?['nombre_visible'] as String?,
    );
  }

  final String id;
  final TipoCambio tipo;
  final DateTime creadoEn;
  // null cuando el lugar dejo de estar publicado (rls no lo devuelve)
  final String? lugarAnterior;
  final String? lugarNuevo;
  final DateTime? inicioAnterior;
  final DateTime? inicioNuevo;
  // null si el perfil del autor no es visible
  final String? realizadoPor;

  static DateTime? _fecha(Object? valor) =>
      valor == null ? null : DateTime.parse(valor as String).toUtc();
}
