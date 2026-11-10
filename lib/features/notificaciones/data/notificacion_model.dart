// tipos de aviso definidos en la tabla notificaciones (rf14)
enum TipoNotificacion {
  actividad('actividad', 'Abrir plan'),
  voto('voto', 'Ir a votar'),
  asistencia('asistencia', 'Confirmar'),
  cambio('cambio', 'Ver itinerario'),
  cancelacion('cancelacion', 'Detalles');

  const TipoNotificacion(this.valor, this.accion);

  final String valor;

  // texto del boton de la tarjeta en p10
  final String accion;

  static TipoNotificacion desde(String valor) => TipoNotificacion.values
      .firstWhere((t) => t.valor == valor, orElse: () => actividad);

  // los avisos de cambio y cancelacion se muestran al sincronizar
  bool get esInmediato => this == cambio || this == cancelacion;
}

// fila propia de notificaciones con el nombre del plan embebido
class NotificacionModel {
  const NotificacionModel({
    required this.id,
    required this.idLocal,
    required this.planId,
    required this.nombrePlan,
    required this.tipo,
    required this.titulo,
    required this.cuerpo,
    required this.rutaDestino,
    required this.programadaPara,
    required this.activa,
    this.entregadaEn,
    this.leidaEn,
  });

  factory NotificacionModel.fromJson(Map<String, dynamic> json) {
    final plan = json['planes'] as Map<String, dynamic>?;
    return NotificacionModel(
      id: json['id'] as String,
      idLocal: (json['id_local'] as num).toInt(),
      planId: json['plan_id'] as String,
      nombrePlan: plan?['nombre'] as String? ?? '',
      tipo: TipoNotificacion.desde(json['tipo'] as String),
      titulo: json['titulo'] as String,
      cuerpo: json['cuerpo'] as String,
      rutaDestino: json['ruta_destino'] as String,
      programadaPara: DateTime.parse(json['programada_para'] as String),
      activa: json['estado'] == 'activa',
      entregadaEn: _fecha(json['entregada_en']),
      leidaEn: _fecha(json['leida_en']),
    );
  }

  static DateTime? _fecha(Object? valor) =>
      valor == null ? null : DateTime.parse(valor as String);

  final String id;
  final int idLocal;
  final String planId;
  final String nombrePlan;
  final TipoNotificacion tipo;
  final String titulo;
  final String cuerpo;
  final String rutaDestino;
  final DateTime programadaPara;
  final bool activa;
  final DateTime? entregadaEn;
  final DateTime? leidaEn;

  bool get leida => leidaEn != null;

  // un recordatorio solo entra al historial cuando llega su momento
  bool visibleEn(DateTime ahora) => activa && !programadaPara.isAfter(ahora);

  // copia con las marcas de entregada o leida ya confirmadas por el servidor
  NotificacionModel copiarCon({DateTime? entregadaEn, DateTime? leidaEn}) =>
      NotificacionModel(
        id: id,
        idLocal: idLocal,
        planId: planId,
        nombrePlan: nombrePlan,
        tipo: tipo,
        titulo: titulo,
        cuerpo: cuerpo,
        rutaDestino: rutaDestino,
        programadaPara: programadaPara,
        activa: activa,
        entregadaEn: this.entregadaEn ?? entregadaEn,
        leidaEn: this.leidaEn ?? leidaEn,
      );
}
