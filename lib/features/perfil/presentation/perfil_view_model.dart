import 'package:flutter/foundation.dart';

import '../../../core/errors/app_exception.dart';
import '../../auth/data/auth_repository.dart';
import '../data/perfil_model.dart';
import '../data/perfil_repository.dart';

class PerfilViewModel extends ChangeNotifier {
  PerfilViewModel({
    required this.perfilRepository,
    required this.authRepository,
  });

  final PerfilRepository perfilRepository;
  final AuthRepository authRepository;

  PerfilModel? _perfil;
  bool _cargando = false;
  String? _errorCarga;
  bool _guardando = false;
  bool _cerrandoSesion = false;
  bool _desechado = false;

  PerfilModel? get perfil => _perfil;
  bool get cargando => _cargando;
  String? get errorCarga => _errorCarga;
  bool get guardando => _guardando;
  bool get cerrandoSesion => _cerrandoSesion;

  Future<void> cargar() async {
    if (_cargando) return;
    _cargando = true;
    _errorCarga = null;
    _notificar();
    try {
      _perfil = await perfilRepository.obtenerPerfilPropio();
    } catch (error) {
      _errorCarga = _mensaje(error);
    } finally {
      _cargando = false;
      _notificar();
    }
  }

  // devuelve null si el servidor guardo el nombre o el mensaje de error
  Future<String?> guardarNombreVisible(String nombreVisible) async {
    if (_guardando) return null;
    _guardando = true;
    _notificar();
    try {
      _perfil = await perfilRepository.actualizarNombreVisible(nombreVisible);
      return null;
    } catch (error) {
      return _mensaje(error);
    } finally {
      _guardando = false;
      _notificar();
    }
  }

  // devuelve el mensaje de error o null; con exito el router lleva a acceso
  Future<String?> cerrarSesion() async {
    if (_cerrandoSesion) return null;
    _cerrandoSesion = true;
    _notificar();
    try {
      await authRepository.cerrarSesion();
      return null;
    } catch (error) {
      return _mensaje(error);
    } finally {
      _cerrandoSesion = false;
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
    super.dispose();
  }
}
