import 'plan_model.dart';

// asistencia para toda la salida; pendiente es solo el valor inicial (rf16)
enum EstadoAsistencia {
  pendiente('pendiente', 'Pendiente'),
  asistire('asistire', 'Asistirá'),
  noAsistire('no_asistire', 'No asistirá');

  const EstadoAsistencia(this.valor, this.etiqueta);

  final String valor;
  // etiqueta en tercera persona para la lista del grupo
  final String etiqueta;

  static EstadoAsistencia desdeValor(String? valor) => values.firstWhere(
    (e) => e.valor == valor,
    orElse: () => EstadoAsistencia.pendiente,
  );
}

// integrante del plan con su rol y asistencia; nunca incluye datos de votos
class ParticipanteModel {
  const ParticipanteModel({
    required this.perfilId,
    required this.nombreVisible,
    required this.rol,
    required this.esCreador,
    required this.unidoEn,
    this.asistencia = EstadoAsistencia.pendiente,
  });

  // fila de participaciones con el perfil embebido
  factory ParticipanteModel.fromJson(Map<String, dynamic> json) {
    final perfil = json['perfiles'] as Map<String, dynamic>?;
    return ParticipanteModel(
      perfilId: json['perfil_id'] as String,
      nombreVisible: (perfil?['nombre_visible'] as String?)?.trim() ?? '',
      rol: RolPlan.desdeValor(json['rol'] as String),
      esCreador: json['es_creador'] as bool,
      unidoEn: DateTime.parse(json['unido_en'] as String),
      asistencia: EstadoAsistencia.desdeValor(json['asistencia'] as String?),
    );
  }

  final String perfilId;
  final String nombreVisible;
  final RolPlan rol;
  final bool esCreador;
  final DateTime unidoEn;
  final EstadoAsistencia asistencia;

  bool get esAdministrador => rol == RolPlan.administrador;

  // copia con la respuesta ya confirmada por el servidor
  ParticipanteModel conAsistencia(EstadoAsistencia estado) => ParticipanteModel(
    perfilId: perfilId,
    nombreVisible: nombreVisible,
    rol: rol,
    esCreador: esCreador,
    unidoEn: unidoEn,
    asistencia: estado,
  );

  String get etiquetaRol =>
      esCreador ? 'Creador · ${RolPlan.administrador.etiqueta}' : rol.etiqueta;

  // creador primero, luego administradores y participantes, por orden de union
  static int comparar(ParticipanteModel a, ParticipanteModel b) {
    int prioridad(ParticipanteModel p) =>
        p.esCreador ? 0 : (p.esAdministrador ? 1 : 2);
    final porRol = prioridad(a).compareTo(prioridad(b));
    return porRol != 0 ? porRol : a.unidoEn.compareTo(b.unidoEn);
  }
}
