import 'package:flutter/foundation.dart';

import '../../../core/errors/app_exception.dart';
import '../data/auth_repository.dart';

enum ModoAcceso { iniciarSesion, registrarse }

// estado de p11; la navegacion tras el exito la hace el redirect del router
class AccesoViewModel extends ChangeNotifier {
  AccesoViewModel(this._repositorio);

  final AuthRepository _repositorio;

  ModoAcceso _modo = ModoAcceso.iniciarSesion;
  bool _enviando = false;
  String? _error;
  bool _desechado = false;

  ModoAcceso get modo => _modo;
  bool get esRegistro => _modo == ModoAcceso.registrarse;
  bool get enviando => _enviando;
  String? get error => _error;

  void cambiarModo(ModoAcceso modo) {
    if (_enviando || modo == _modo) return;
    _modo = modo;
    _error = null;
    notifyListeners();
  }

  // devuelve true solo cuando el servidor confirmo el registro o el acceso
  Future<bool> enviar({
    required String nombreVisible,
    required String correo,
    required String contrasena,
  }) async {
    if (_enviando) return false;
    _enviando = true;
    _error = null;
    notifyListeners();
    try {
      if (esRegistro) {
        await _repositorio.registrar(
          nombreVisible: nombreVisible,
          correo: correo,
          contrasena: contrasena,
        );
      } else {
        await _repositorio.iniciarSesion(
          correo: correo,
          contrasena: contrasena,
        );
      }
      return true;
    } on AppException catch (e) {
      _error = e.mensaje;
      return false;
    } catch (_) {
      _error = MensajesError.generico;
      return false;
    } finally {
      _enviando = false;
      // con exito el router desmonta la pantalla antes de terminar
      if (!_desechado) notifyListeners();
    }
  }

  @override
  void dispose() {
    _desechado = true;
    super.dispose();
  }
}
