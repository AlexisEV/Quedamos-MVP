// perfil propio: nombre_visible viene de perfiles y el correo de la sesion
class PerfilModel {
  const PerfilModel({
    required this.id,
    required this.nombreVisible,
    required this.correo,
  });

  factory PerfilModel.fromJson(Map<String, dynamic> json, {String? correo}) {
    return PerfilModel(
      id: json['id'] as String,
      nombreVisible: json['nombre_visible'] as String,
      correo: correo,
    );
  }

  final String id;
  final String nombreVisible;
  final String? correo;

  PerfilModel copyWith({String? nombreVisible}) {
    return PerfilModel(
      id: id,
      nombreVisible: nombreVisible ?? this.nombreVisible,
      correo: correo,
    );
  }
}
