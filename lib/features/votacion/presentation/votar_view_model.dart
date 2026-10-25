import 'package:flutter/foundation.dart';

import '../../../core/errors/app_exception.dart';
import '../../salidas/data/plan_model.dart';
import '../../salidas/data/salidas_repository.dart';
import '../data/candidato_model.dart';
import '../data/votacion_repository.dart';

// p05 votar: seleccion multiple, guardado y totales sin votantes (rf06, rf07)
class VotarViewModel extends ChangeNotifier {
  VotarViewModel(
    this._salidas,
    this._votacion,
    this.planId, {
    DateTime Function()? ahora,
  }) : _ahora = ahora ?? DateTime.now;

  final SalidasRepository _salidas;
  final VotacionRepository _votacion;
  final String planId;
  final DateTime Function() _ahora;

  SalidaModel? _salida;
  List<CandidatoModel> _candidatos = const [];
  Map<String, int> _totales = const {};
  // ultima seleccion guardada en el servidor
  Set<String> _guardados = const {};
  // seleccion en edicion
  Set<String> _seleccion = {};
  bool _cargando = false;
  bool _noEncontrado = false;
  String? _error;
  bool _guardando = false;
  String? _errorGuardado;
  // el voto se guardo pero los totales no se pudieron recargar
  bool _totalesDesactualizados = false;
  bool _desechado = false;

  SalidaModel? get salida => _salida;
  List<CandidatoModel> get candidatos => _candidatos;
  bool get cargando => _cargando;
  bool get noEncontrado => _noEncontrado;
  String? get error => _error;
  bool get guardando => _guardando;
  String? get errorGuardado => _errorGuardado;
  bool get totalesDesactualizados => _totalesDesactualizados;
  Set<String> get seleccion => Set.unmodifiable(_seleccion);

  EstadoPlan? get estado => _salida?.plan.estado;

  bool get votacionAbierta => estado == EstadoPlan.enVotacion;

  // la ruta muestra preparar votacion mientras el plan recibe propuestas
  bool get enPreparacion => estado == EstadoPlan.recibiendoPropuestas;

  // nadie puede elegir mas lugares que candidatos existentes
  int get maximo {
    final plan = _salida?.plan;
    if (plan == null) return 0;
    return plan.maxSelecciones < _candidatos.length
        ? plan.maxSelecciones
        : _candidatos.length;
  }

  bool get yaVoto => _guardados.isNotEmpty;

  bool get hayCambios => !setEquals(_seleccion, _guardados);

  bool get plazoVencido {
    final plazo = _salida?.plan.fechaLimiteVoto;
    return plazo != null && !plazo.isAfter(_ahora());
  }

  int total(String candidatoId) => _totales[candidatoId] ?? 0;

  bool estaSeleccionado(String candidatoId) => _seleccion.contains(candidatoId);

  // un lugar nuevo solo entra si queda espacio bajo el maximo
  bool puedeAlternar(String candidatoId) =>
      votacionAbierta &&
      !_guardando &&
      (estaSeleccionado(candidatoId) || _seleccion.length < maximo);

  void alternar(String candidatoId) {
    if (!puedeAlternar(candidatoId)) return;
    if (!_seleccion.remove(candidatoId)) _seleccion.add(candidatoId);
    _errorGuardado = null;
    notifyListeners();
  }

  bool get puedeGuardar =>
      votacionAbierta && !_guardando && _seleccion.isNotEmpty && hayCambios;

  // recarga todo del servidor; una seleccion sin guardar se conserva
  Future<void> cargar() async {
    if (_cargando) return;
    _cargando = true;
    _error = null;
    _notificar();
    try {
      final salida = await _salidas.obtenerSalida(planId);
      _salida = salida;
      _noEncontrado = salida == null;
      if (salida == null || enPreparacion) {
        _candidatos = const [];
        _totales = const {};
        _guardados = const {};
        _seleccion = {};
        return;
      }
      final editando = hayCambios;
      final candidatos = await _votacion.obtenerCandidatos(planId);
      final totales = await _votacion.obtenerTotales(planId);
      final guardados = await _votacion.obtenerMisVotos(planId);
      final ids = {for (final c in candidatos) c.id};
      _candidatos = candidatos;
      _totales = totales;
      _guardados = guardados.intersection(ids);
      _seleccion = editando && votacionAbierta
          ? _seleccion.intersection(ids)
          : {..._guardados};
      _totalesDesactualizados = false;
    } catch (error) {
      _error = _mensaje(error);
    } finally {
      _cargando = false;
      _notificar();
    }
  }

  // true solo cuando el servidor confirmo la seleccion; si falla se conserva la edicion
  Future<bool> guardar() async {
    if (!puedeGuardar) return false;
    _guardando = true;
    _errorGuardado = null;
    _notificar();
    final enviada = {..._seleccion};
    try {
      await _votacion.guardarVotos(planId: planId, candidatoIds: enviada);
    } catch (error) {
      _errorGuardado = _mensaje(error);
      _guardando = false;
      _notificar();
      return false;
    }
    _guardados = enviada;
    try {
      _totales = await _votacion.obtenerTotales(planId);
      _totalesDesactualizados = false;
    } catch (_) {
      // el voto ya se guardo; los totales se marcan como no actualizados
      _totalesDesactualizados = true;
    }
    _guardando = false;
    _notificar();
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
