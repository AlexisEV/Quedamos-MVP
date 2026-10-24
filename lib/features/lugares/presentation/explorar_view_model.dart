import 'package:flutter/foundation.dart';

import '../../../core/errors/app_exception.dart';
import '../data/lugar_model.dart';
import '../data/lugares_repository.dart';

class ExplorarViewModel extends ChangeNotifier {
  ExplorarViewModel(this._repositorio);

  final LugaresRepository _repositorio;

  List<LugarModel> _lugares = const [];
  bool _cargando = false;
  bool _cargadoAlgunaVez = false;
  String? _error;
  bool _desechado = false;

  List<LugarModel> get lugares => _lugares;
  bool get cargando => _cargando;
  String? get error => _error;
  // la primera carga muestra el indicador; las siguientes conservan la lista
  bool get cargandoPrimeraVez => _cargando && !_cargadoAlgunaVez;
  bool get vacio => _cargadoAlgunaVez && _error == null && _lugares.isEmpty;

  Future<void> cargar() async {
    if (_cargando) return;
    _cargando = true;
    _error = null;
    _notificar();
    try {
      _lugares = await _repositorio.obtenerLugares();
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
    super.dispose();
  }
}
