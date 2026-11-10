import 'package:flutter/foundation.dart';

import '../../../core/errors/app_exception.dart';
import '../../salidas/data/plan_model.dart';
import '../../salidas/data/salidas_repository.dart';
import '../../votacion/data/resultado_votacion.dart';
import '../../votacion/data/votacion_repository.dart';
import '../data/actividad_model.dart';
import '../data/estimacion_presupuesto.dart';
import '../data/itinerario_repository.dart';

// orden manual, fecha y hora de inicio y confirmacion del itinerario (rf08, rf12, p08)
class RevisarItinerarioViewModel extends ChangeNotifier {
  RevisarItinerarioViewModel(
    this._itinerario,
    this._salidas,
    this._votacion,
    this.planId, {
    DateTime Function()? reloj,
  }) : _ahora = reloj ?? DateTime.now;

  final ItinerarioRepository _itinerario;
  final SalidasRepository _salidas;
  final VotacionRepository _votacion;
  final String planId;
  final DateTime Function() _ahora;

  SalidaModel? _salida;
  bool _empatePendiente = false;
  // ultima version guardada en el servidor
  List<ActividadModel> _guardadas = const [];
  // version en edicion, en orden de ejecucion
  List<ActividadModel> _edicion = const [];
  EstimacionPresupuesto? _estimacion;
  bool _cargando = false;
  bool _noEncontrado = false;
  String? _error;
  bool _guardando = false;
  bool _confirmando = false;
  String? _errorAccion;
  bool _desechado = false;

  SalidaModel? get salida => _salida;
  List<ActividadModel> get actividades => _edicion;
  EstimacionPresupuesto? get estimacion => _estimacion;
  bool get cargando => _cargando;
  bool get noEncontrado => _noEncontrado;
  String? get error => _error;
  bool get guardando => _guardando;
  bool get confirmando => _confirmando;
  bool get ocupado => _guardando || _confirmando;
  String? get errorAccion => _errorAccion;
  bool get empatePendiente => _empatePendiente;

  bool get confirmado => _salida?.plan.estado == EstadoPlan.confirmado;

  // solo administradores, con la votacion cerrada y el empate resuelto
  bool get puedeEditar =>
      _salida?.plan.estado == EstadoPlan.preparandoItinerario &&
      (_salida?.esAdministrador ?? false) &&
      !_empatePendiente;

  bool get hayCambios => !_mismaVersion(_edicion, _guardadas);

  int get sinHorario => _edicion.where((a) => a.inicio == null).length;

  // confirmar exige fecha y hora en todas las actividades (decision 2026-11-09)
  bool get puedeConfirmar =>
      puedeEditar && _edicion.isNotEmpty && sinHorario == 0 && !ocupado;

  Future<void> cargar() async {
    if (_cargando) return;
    _cargando = true;
    _error = null;
    _notificar();
    try {
      final salida = await _salidas.obtenerSalida(planId);
      _salida = salida;
      _noEncontrado = salida == null;
      if (salida != null) {
        final candidatos = await _votacion.obtenerCandidatos(planId);
        _empatePendiente = ResultadoVotacion(
          candidatos,
          salida.plan.maxActividades,
        ).empatePendiente;
        final actividades = await _itinerario.obtenerActividades(planId);
        _estimacion = await _itinerario.obtenerEstimacion(planId);
        // una recarga conserva la edicion sin guardar si las actividades son las mismas
        final mismas = _mismosIds(actividades, _edicion);
        if (!hayCambios || !mismas) _edicion = actividades;
        _guardadas = actividades;
      }
    } catch (error) {
      _error = _mensaje(error);
    } finally {
      _cargando = false;
      _notificar();
    }
  }

  void subir(int indice) => _mover(indice, indice - 1);

  void bajar(int indice) => _mover(indice, indice + 1);

  void _mover(int desde, int hacia) {
    if (!puedeEditar || ocupado) return;
    if (desde < 0 || hacia < 0) return;
    if (desde >= _edicion.length || hacia >= _edicion.length) return;
    final lista = [..._edicion];
    final actividad = lista.removeAt(desde);
    lista.insert(hacia, actividad);
    _edicion = lista;
    _errorAccion = null;
    _notificar();
  }

  // devuelve un mensaje si el inicio no es futuro; null si se aplico
  String? fijarInicio(String actividadId, DateTime inicio) {
    if (!puedeEditar || ocupado) return null;
    if (!inicio.isAfter(_ahora())) return MensajesError.inicioEnPasado;
    _edicion = [
      for (final a in _edicion)
        a.id == actividadId
            ? a.copiarCon(posicion: a.posicion, inicio: inicio)
            : a,
    ];
    _errorAccion = null;
    _notificar();
    return null;
  }

  // true solo cuando el servidor guardo el orden y los horarios
  Future<bool> guardar() async {
    if (ocupado || !puedeEditar) return false;
    _guardando = true;
    _errorAccion = null;
    _notificar();
    final ok = await _enviarEdicion();
    _guardando = false;
    _notificar();
    return ok;
  }

  // guarda lo pendiente y confirma; true solo cuando el servidor confirmo el plan
  Future<bool> confirmar() async {
    if (!puedeConfirmar) return false;
    _confirmando = true;
    _errorAccion = null;
    _notificar();
    if (hayCambios && !await _enviarEdicion()) {
      _confirmando = false;
      _notificar();
      return false;
    }
    try {
      final plan = await _itinerario.confirmarPlan(planId);
      final salida = _salida!;
      _salida = SalidaModel(
        plan: plan,
        miRol: salida.miRol,
        esCreador: salida.esCreador,
        totalParticipantes: salida.totalParticipantes,
      );
      return true;
    } catch (error) {
      _errorAccion = _mensaje(error);
      return false;
    } finally {
      _confirmando = false;
      _notificar();
    }
  }

  Future<bool> _enviarEdicion() async {
    final enviada = _edicion;
    try {
      await _itinerario.guardarItinerario(planId: planId, actividades: enviada);
    } catch (error) {
      _errorAccion = _mensaje(error);
      return false;
    }
    _guardadas = [
      for (final (i, a) in enviada.indexed)
        a.copiarCon(posicion: i + 1, inicio: a.inicio),
    ];
    _edicion = _guardadas;
    return true;
  }

  static bool _mismosIds(List<ActividadModel> a, List<ActividadModel> b) {
    final ids = {for (final x in a) x.id};
    return a.length == b.length && b.every((x) => ids.contains(x.id));
  }

  static bool _mismaVersion(List<ActividadModel> a, List<ActividadModel> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id) return false;
      final ia = a[i].inicio;
      final ib = b[i].inicio;
      if (ia == null || ib == null) {
        if (ia != ib) return false;
      } else if (!ia.isAtSameMomentAs(ib)) {
        return false;
      }
    }
    return true;
  }

  String _mensaje(Object error) =>
      error is AppException ? error.mensaje : MensajesError.generico;

  void _notificar() {
    if (!_desechado) notifyListeners();
  }

  @override
  void dispose() {
    _desechado = true;
    super.dispose();
  }
}
