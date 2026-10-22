import 'package:flutter/foundation.dart';

import '../../../core/errors/app_exception.dart';
import '../data/plan_model.dart';
import '../data/salidas_repository.dart';

class DetallePlanViewModel extends ChangeNotifier {
  DetallePlanViewModel(this._repositorio, this.planId);

  final SalidasRepository _repositorio;
  final String planId;

  SalidaModel? _salida;
  bool _cargando = false;
  bool _noEncontrado = false;
  String? _error;
  bool _desechado = false;

  SalidaModel? get salida => _salida;
  bool get cargando => _cargando;
  // el plan no existe o el usuario no participa en el
  bool get noEncontrado => _noEncontrado;
  String? get error => _error;

  Future<void> cargar() async {
    if (_cargando) return;
    _cargando = true;
    _error = null;
    _notificar();
    try {
      _salida = await _repositorio.obtenerSalida(planId);
      _noEncontrado = _salida == null;
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
    super.dispose();
  }
}
