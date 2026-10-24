// zonas fijas de la cobertura (rb09); el valor coincide con el enum lugar_zona
enum ZonaLugar {
  centroHistorico('centro_historico', 'Centro Histórico'),
  yanahuara('yanahuara', 'Yanahuara'),
  cayma('cayma', 'Cayma'),
  vallecito('vallecito', 'Vallecito'),
  cercado('cercado', 'Cercado');

  const ZonaLugar(this.valor, this.etiqueta);

  final String valor;
  final String etiqueta;

  static ZonaLugar desdeValor(String valor) =>
      values.firstWhere((zona) => zona.valor == valor);
}

// categorias fijas del catalogo (rb09); el valor coincide con el enum lugar_categoria
enum CategoriaLugar {
  restaurantes('restaurantes', 'Restaurantes'),
  cafesYPostres('cafes_y_postres', 'Cafés y Postres'),
  bares('bares', 'Bares'),
  entretenimientoYCultura(
    'entretenimiento_y_cultura',
    'Entretenimiento y Cultura',
  );

  const CategoriaLugar(this.valor, this.etiqueta);

  final String valor;
  final String etiqueta;

  static CategoriaLugar desdeValor(String valor) =>
      values.firstWhere((categoria) => categoria.valor == valor);
}

// lugar publicado del catalogo; los campos null son datos desconocidos
class LugarModel {
  const LugarModel({
    required this.id,
    required this.nombre,
    required this.categoria,
    required this.zona,
    this.direccion,
    this.horarioAtencion,
    this.precioEstimadoPen,
    this.precioNota,
  });

  factory LugarModel.fromJson(Map<String, dynamic> json) {
    return LugarModel(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      categoria: CategoriaLugar.desdeValor(json['categoria'] as String),
      zona: ZonaLugar.desdeValor(json['zona'] as String),
      direccion: _textoOpcional(json['direccion']),
      horarioAtencion: _textoOpcional(json['horario_atencion']),
      precioEstimadoPen: (json['precio_estimado_pen'] as num?)?.toDouble(),
      precioNota: _textoOpcional(json['precio_nota']),
    );
  }

  final String id;
  final String nombre;
  final CategoriaLugar categoria;
  final ZonaLugar zona;
  final String? direccion;
  final String? horarioAtencion;
  // precio estimado por persona en soles; null no equivale a gratis
  final double? precioEstimadoPen;
  final String? precioNota;

  // un texto vacio tambien se trata como desconocido
  static String? _textoOpcional(Object? valor) {
    final texto = (valor as String?)?.trim();
    return texto == null || texto.isEmpty ? null : texto;
  }
}
