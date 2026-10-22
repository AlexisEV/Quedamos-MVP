import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/errors/app_exception.dart';
import '../data/plan_model.dart';
import '../data/salidas_repository.dart';

class MisSalidasViewModel extends ChangeNotifier {
  MisSalidasViewModel(this._repositorio) {
    _suscripcion = _repositorio.cambios.listen((_) => cargar());
  }

  final SalidasRepository _repositorio;
  late final StreamSubscription<void> _suscripcion;

  List<SalidaModel> _salidas = const [];
  bool _cargando = false;
  bool _cargadoAlgunaVez = false;
  String? _error;
  bool _desechado = false;

  bool get cargando => _cargando;
  String? get error => _error;
  // la primera carga muestra el indicador; las siguientes conservan la lista
  bool get cargandoPrimeraVez => _cargando && !_cargadoAlgunaVez;
  bool get vacio => _cargadoAlgunaVez && _error == null && _salidas.isEmpty;

  List<SalidaModel> get activas => _salidas
      .where((salida) => salida.plan.estado != EstadoPlan.cancelado)
      .toList();

  List<SalidaModel> get canceladas => _salidas
      .where((salida) => salida.plan.estado == EstadoPlan.cancelado)
      .toList();

  Future<void> cargar() async {
    if (_cargando) return;
    _cargando = true;
    _error = null;
    _notificar();
    try {
      _salidas = await _repositorio.obtenerMisSalidas();
      _cargadoAlgunaVez = true;
    } catch (error) {
      _error = error is AppException ? error.mensaje : MensajesError.generico;
    } finally {
      _cargando = false;
      _notificar();
    }
  }

  void _notificar() {
    if (!_desechado) notifyListeners();
  }

  @override
  void dispose() {
    _desechado = true;
    _suscripcion.cancel();
    super.dispose();
  }
}
