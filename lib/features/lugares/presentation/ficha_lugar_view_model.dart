import 'package:flutter/foundation.dart';

import '../../../core/errors/app_exception.dart';
import '../data/lugar_model.dart';
import '../data/lugares_repository.dart';

class FichaLugarViewModel extends ChangeNotifier {
  FichaLugarViewModel(this._repositorio, this.lugarId);

  final LugaresRepository _repositorio;
  final String lugarId;

  LugarModel? _lugar;
  bool _cargando = false;
  bool _noEncontrado = false;
  String? _error;
  bool _desechado = false;

  LugarModel? get lugar => _lugar;
  bool get cargando => _cargando;
  // el lugar no existe o ya no esta publicado
  bool get noEncontrado => _noEncontrado;
  String? get error => _error;

  Future<void> cargar() async {
    if (_cargando) return;
    _cargando = true;
    _error = null;
    _notificar();
    try {
      final lugar = await _repositorio.obtenerLugar(lugarId);
      _lugar = lugar;
      _noEncontrado = lugar == null;
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
