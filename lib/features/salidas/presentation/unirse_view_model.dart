import 'package:flutter/foundation.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/utils/validadores.dart';
import '../data/salidas_repository.dart';

class UnirseViewModel extends ChangeNotifier {
  UnirseViewModel(this._repositorio);

  final SalidasRepository _repositorio;

  bool _consultando = false;
  String? _error;
  bool _desechado = false;

  bool get consultando => _consultando;
  String? get error => _error;

  // devuelve el resultado solo cuando el servidor confirmo la union
  Future<ResultadoUnion?> unirse(String codigo) async {
    if (_consultando || Validadores.codigoInvitacion(codigo) != null) {
      return null;
    }
    _consultando = true;
    _error = null;
    _notificar();
    try {
      return await _repositorio.unirseConCodigo(codigo);
    } catch (error) {
      _error = error is AppException ? error.mensaje : MensajesError.generico;
      return null;
    } finally {
      _consultando = false;
      _notificar();
    }
  }

  // el error del servidor se oculta al editar el codigo
  void limpiarError() {
    if (_error == null) return;
    _error = null;
    _notificar();
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
