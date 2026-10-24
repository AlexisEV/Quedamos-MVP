import 'plan_model.dart';

// integrante del plan con su rol; nunca incluye datos de votos
class ParticipanteModel {
  const ParticipanteModel({
    required this.perfilId,
    required this.nombreVisible,
    required this.rol,
    required this.esCreador,
    required this.unidoEn,
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
    );
  }

  final String perfilId;
  final String nombreVisible;
  final RolPlan rol;
  final bool esCreador;
  final DateTime unidoEn;

  bool get esAdministrador => rol == RolPlan.administrador;

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
