import 'package:flutter/foundation.dart';

import '../../../core/errors/app_exception.dart';
import '../data/participante_model.dart';
import '../data/plan_model.dart';
import '../data/salidas_repository.dart';

class DetallePlanViewModel extends ChangeNotifier {
  DetallePlanViewModel(this._repositorio, this.planId);

  final SalidasRepository _repositorio;
  final String planId;

  SalidaModel? _salida;
  List<ParticipanteModel> _participantes = const [];
  bool _cargando = false;
  bool _noEncontrado = false;
  String? _error;
  bool _asignando = false;
  String? _errorAsignacion;
  bool _desechado = false;

  SalidaModel? get salida => _salida;
  List<ParticipanteModel> get participantes => _participantes;
  bool get cargando => _cargando;
  // el plan no existe o el usuario no participa en el
  bool get noEncontrado => _noEncontrado;
  String? get error => _error;
  bool get asignando => _asignando;
  String? get errorAsignacion => _errorAsignacion;
  String? get usuarioActualId => _repositorio.usuarioActualId;

  // solo administradores de un plan no cancelado gestionan roles (rf17)
  bool get puedeGestionar {
    final salida = _salida;
    return salida != null &&
        salida.esAdministrador &&
        salida.plan.estado != EstadoPlan.cancelado;
  }

  List<ParticipanteModel> get nombrables =>
      _participantes.where((p) => !p.esAdministrador).toList();

  Future<void> cargar() async {
    if (_cargando) return;
    _cargando = true;
    _error = null;
    _notificar();
    try {
      final salida = await _repositorio.obtenerSalida(planId);
      _salida = salida;
      _noEncontrado = salida == null;
      _participantes = salida == null
          ? const []
          : await _repositorio.obtenerParticipantes(planId);
    } catch (error) {
      _error = _mensaje(error);
    } finally {
      _cargando = false;
      _notificar();
    }
  }

  // true solo cuando el servidor confirmo el nuevo rol; si falla la lista no cambia
  Future<bool> nombrarAdministrador(ParticipanteModel participante) async {
    if (_asignando || !puedeGestionar) return false;
    _asignando = true;
    _errorAsignacion = null;
    _notificar();
    try {
      await _repositorio.nombrarAdministrador(
        planId: planId,
        perfilId: participante.perfilId,
      );
    } catch (error) {
      _errorAsignacion = _mensaje(error);
      _asignando = false;
      _notificar();
      return false;
    }
    try {
      _participantes = await _repositorio.obtenerParticipantes(planId);
    } catch (_) {
      // el rol ya se guardo; la lista se actualiza en la siguiente recarga
    }
    _asignando = false;
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
