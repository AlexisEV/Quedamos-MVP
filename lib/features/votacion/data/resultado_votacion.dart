import 'candidato_model.dart';

// resultado de una votacion cerrada a partir de los totales guardados (rf08, rb06)
class ResultadoVotacion {
  ResultadoVotacion(List<CandidatoModel> candidatos, this.maxActividades)
    : ordenados = _ordenar(candidatos);

  // de mas a menos votos; a igual total conserva el orden de la lista final
  final List<CandidatoModel> ordenados;
  final int maxActividades;

  static List<CandidatoModel> _ordenar(List<CandidatoModel> candidatos) {
    final indices = {
      for (final (i, candidato) in candidatos.indexed) candidato.id: i,
    };
    return [...candidatos]..sort((a, b) {
      final porVotos = (b.totalVotos ?? 0).compareTo(a.totalVotos ?? 0);
      return porVotos != 0
          ? porVotos
          : indices[a.id]!.compareTo(indices[b.id]!);
    });
  }

  int get _votados => ordenados.where((c) => (c.totalVotos ?? 0) > 0).length;

  int get seleccionados => ordenados.where((c) => c.seleccionado).length;

  // puestos del itinerario que aun dependen del desempate
  int get cuposPendientes {
    final disponibles = maxActividades < _votados ? maxActividades : _votados;
    final cupos = disponibles - seleccionados;
    return cupos > 0 ? cupos : 0;
  }

  bool get empatePendiente => cuposPendientes > 0;

  // votados sin seleccionar con el mayor total entre ellos (misma regla que resolver_empate)
  List<CandidatoModel> get empatados {
    if (!empatePendiente) return const [];
    final restantes = ordenados.where(
      (c) => !c.seleccionado && (c.totalVotos ?? 0) > 0,
    );
    final total = restantes.first.totalVotos;
    return restantes.where((c) => c.totalVotos == total).toList();
  }
}
