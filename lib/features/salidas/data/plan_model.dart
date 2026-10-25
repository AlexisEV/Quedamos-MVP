// fases del plan; el orden sigue el flujo unidireccional
enum EstadoPlan {
  recibiendoPropuestas('recibiendo_propuestas', 'Recibiendo propuestas'),
  enVotacion('en_votacion', 'En votación'),
  preparandoItinerario('preparando_itinerario', 'Preparando itinerario'),
  confirmado('confirmado', 'Confirmado'),
  cancelado('cancelado', 'Cancelado');

  const EstadoPlan(this.valor, this.etiqueta);

  final String valor;
  final String etiqueta;

  static EstadoPlan desdeValor(String valor) =>
      values.firstWhere((estado) => estado.valor == valor);
}

enum RolPlan {
  administrador('administrador', 'Administrador'),
  participante('participante', 'Participante');

  const RolPlan(this.valor, this.etiqueta);

  final String valor;
  final String etiqueta;

  static RolPlan desdeValor(String valor) =>
      values.firstWhere((rol) => rol.valor == valor);
}

class PlanModel {
  const PlanModel({
    required this.id,
    required this.nombre,
    required this.estado,
    required this.presupuestoSoles,
    required this.maxPropuestasPorPersona,
    required this.maxCandidatos,
    required this.maxSelecciones,
    required this.maxActividades,
    required this.codigoInvitacion,
    required this.creadoPor,
    required this.createdAt,
    this.fechaLimiteVoto,
    this.fechaLimiteAsistencia,
  });

  factory PlanModel.fromJson(Map<String, dynamic> json) {
    return PlanModel(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      estado: EstadoPlan.desdeValor(json['estado'] as String),
      presupuestoSoles: (json['presupuesto_soles'] as num).toDouble(),
      maxPropuestasPorPersona: json['max_propuestas_por_persona'] as int,
      maxCandidatos: json['max_candidatos'] as int,
      maxSelecciones: json['max_selecciones'] as int,
      maxActividades: json['max_actividades'] as int,
      // char(6) puede llegar con espacios de relleno
      codigoInvitacion: (json['codigo_invitacion'] as String).trim(),
      creadoPor: json['creado_por'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      fechaLimiteVoto: _fechaOpcional(json['fecha_limite_voto']),
      fechaLimiteAsistencia: _fechaOpcional(json['fecha_limite_asistencia']),
    );
  }

  final String id;
  final String nombre;
  final EstadoPlan estado;
  final double presupuestoSoles;
  final int maxPropuestasPorPersona;
  final int maxCandidatos;
  final int maxSelecciones;
  final int maxActividades;
  final String codigoInvitacion;
  final String creadoPor;
  final DateTime createdAt;
  // plazos opcionales en utc; null significa sin plazo ni recordatorio
  final DateTime? fechaLimiteVoto;
  final DateTime? fechaLimiteAsistencia;

  static DateTime? _fechaOpcional(Object? valor) =>
      valor == null ? null : DateTime.parse(valor as String).toUtc();
}

// plan visto por el usuario actual: su rol y el tamano del grupo
class SalidaModel {
  const SalidaModel({
    required this.plan,
    required this.miRol,
    required this.esCreador,
    required this.totalParticipantes,
  });

  // fila de participaciones con el plan embebido y el conteo del grupo
  factory SalidaModel.fromJson(Map<String, dynamic> json) {
    final plan = json['planes'] as Map<String, dynamic>;
    final conteo = plan['participaciones'] as List<dynamic>? ?? const [];
    return SalidaModel(
      plan: PlanModel.fromJson(plan),
      miRol: RolPlan.desdeValor(json['rol'] as String),
      esCreador: json['es_creador'] as bool,
      totalParticipantes: conteo.isEmpty
          ? 0
          : (conteo.first as Map<String, dynamic>)['count'] as int,
    );
  }

  final PlanModel plan;
  final RolPlan miRol;
  final bool esCreador;
  final int totalParticipantes;

  bool get esAdministrador => miRol == RolPlan.administrador;
}
