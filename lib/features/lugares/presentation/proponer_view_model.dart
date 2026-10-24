import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/errors/app_exception.dart';
import '../data/propuesta_model.dart';
import '../data/propuestas_repository.dart';
import 'destino_propuesta.dart';

// accion de proponer un lugar desde su ficha al plan destino (rf05, p04)
class ProponerViewModel extends ChangeNotifier {
  ProponerViewModel(this._repositorio, this._destino, this.lugarId) {
    _destino.addListener(_notificar);
    _suscripcion = _repositorio.cambios.listen((_) => cargar());
  }

  final PropuestasRepository _repositorio;
  final DestinoPropuesta _destino;
  final String lugarId;
  late final StreamSubscription<String> _suscripcion;

  List<DestinoPlan> _destinos = const [];
  bool _cargando = false;
  bool _cargadoAlgunaVez = false;
  String? _error;
  bool _enviando = false;
  String? _errorEnvio;
  bool _desechado = false;

  List<DestinoPlan> get destinos => _destinos;
  bool get cargandoPrimeraVez => _cargando && !_cargadoAlgunaVez;
  String? get error => _error;
  bool get enviando => _enviando;
  String? get errorEnvio => _errorEnvio;

  // destino elegido solo si sigue recibiendo propuestas
  DestinoPlan? get destinoActual {
    final planId = _destino.planId;
    for (final destino in _destinos) {
      if (destino.plan.id == planId) return destino;
    }
    return null;
  }

  Future<void> cargar() async {
    if (_cargando) return;
    _cargando = true;
    _error = null;
    _notificar();
    try {
      _destinos = await _repositorio.obtenerDestinos();
      _cargadoAlgunaVez = true;
      // un destino que ya no recibe propuestas deja de estar elegido
      if (_destino.hayDestino && destinoActual == null) _destino.limpiar();
    } catch (error) {
      _error = _mensaje(error);
    } finally {
      _cargando = false;
      _notificar();
    }
  }

  void elegir(DestinoPlan destino) {
    _errorEnvio = null;
    _destino.fijar(destino.plan);
  }

  // true solo cuando el servidor confirmo la propuesta
  Future<bool> proponer(DestinoPlan destino) async {
    if (_enviando) return false;
    elegir(destino);
    if (destino.yaPropuesto(lugarId) || destino.limiteAlcanzado) return false;
    _enviando = true;
    _errorEnvio = null;
    _notificar();
    try {
      await _repositorio.proponer(planId: destino.plan.id, lugarId: lugarId);
      return true;
    } catch (error) {
      _errorEnvio = _mensaje(error);
      // el cupo o la fase pudieron cambiar en el servidor
      unawaited(cargar());
      return false;
    } finally {
      _enviando = false;
      _notificar();
    }
  }

  String _mensaje(Object error) =>
      error is AppException ? error.mensaje : MensajesError.generico;

  void _notificar() {
    if (!_desechado) notifyListeners();
  }

  @override
  void dispose() {
    _desechado = true;
    _destino.removeListener(_notificar);
    _suscripcion.cancel();
    super.dispose();
  }
}
