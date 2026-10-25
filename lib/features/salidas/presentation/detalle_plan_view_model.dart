import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/errors/app_exception.dart';
import '../../lugares/data/propuesta_model.dart';
import '../../lugares/data/propuestas_repository.dart';
import '../../votacion/data/candidato_model.dart';
import '../../votacion/data/votacion_repository.dart';
import '../data/participante_model.dart';
import '../data/plan_model.dart';
import '../data/salidas_repository.dart';

class DetallePlanViewModel extends ChangeNotifier {
  DetallePlanViewModel(
    this._repositorio,
    this._propuestas,
    this._votacion,
    this.planId,
  ) {
    // las propuestas pueden cambiar desde la ficha de un lugar en otra pestana
    _suscripcion = _propuestas.cambios
        .where((id) => id == planId)
        .listen((_) => _recargarPropuestas());
  }

  final SalidasRepository _repositorio;
  final PropuestasRepository _propuestas;
  final VotacionRepository _votacion;
  final String planId;
  late final StreamSubscription<String> _suscripcion;

  SalidaModel? _salida;
  List<ParticipanteModel> _participantes = const [];
  bool _cargando = false;
  bool _noEncontrado = false;
  String? _error;
  bool _asignando = false;
  String? _errorAsignacion;
  List<PropuestaModel> _listaPropuestas = const [];
  List<CandidatoModel> _candidatos = const [];
  String? _retirando;
  String? _errorPropuestas;
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
  List<PropuestaModel> get propuestas => _listaPropuestas;
  // id de la propuesta que se esta retirando
  String? get retirando => _retirando;
  String? get errorPropuestas => _errorPropuestas;
  List<CandidatoModel> get candidatos => _candidatos;

  bool get recibePropuestas =>
      _salida?.plan.estado == EstadoPlan.recibiendoPropuestas;

  // desde que se abre la votacion la lista final queda fija y reemplaza a las propuestas
  bool get muestraCandidatos => switch (_salida?.plan.estado) {
    EstadoPlan.enVotacion ||
    EstadoPlan.preparandoItinerario ||
    EstadoPlan.confirmado => true,
    _ => false,
  };

  // solo administradores mientras se reciben propuestas (rf05, rf18)
  bool get puedePrepararVotacion =>
      recibePropuestas && (_salida?.esAdministrador ?? false);

  int propuestasDe(String perfilId) =>
      _listaPropuestas.where((p) => p.propuestoPor == perfilId).length;

  int get misPropuestas => propuestasDe(usuarioActualId ?? '');

  // el autor o un administrador retira solo mientras se reciben propuestas (rf05)
  bool puedeRetirar(PropuestaModel propuesta) {
    final salida = _salida;
    return salida != null &&
        recibePropuestas &&
        (propuesta.propuestoPor == usuarioActualId || salida.esAdministrador);
  }

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
      _listaPropuestas = salida == null
          ? const []
          : await _propuestas.obtenerPropuestas(planId);
      _candidatos = salida != null && muestraCandidatos
          ? await _votacion.obtenerCandidatos(planId)
          : const [];
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

  Future<void> _recargarPropuestas() async {
    try {
      _listaPropuestas = await _propuestas.obtenerPropuestas(planId);
      _notificar();
    } catch (_) {
      // se conserva la lista anterior; la siguiente recarga la actualiza
    }
  }

  // true solo cuando el servidor confirmo el retiro; si falla la lista no cambia
  Future<bool> retirarPropuesta(PropuestaModel propuesta) async {
    if (_retirando != null || !puedeRetirar(propuesta)) return false;
    _retirando = propuesta.id;
    _errorPropuestas = null;
    _notificar();
    try {
      await _propuestas.retirar(propuesta);
      _listaPropuestas = _listaPropuestas
          .where((p) => p.id != propuesta.id)
          .toList();
      return true;
    } catch (error) {
      _errorPropuestas = _mensaje(error);
      return false;
    } finally {
      _retirando = null;
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
    _suscripcion.cancel();
    super.dispose();
  }
}
