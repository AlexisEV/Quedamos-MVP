import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/errors/app_exception.dart';
import '../../itinerario/data/actividad_model.dart';
import '../../itinerario/data/cambio_plan_model.dart';
import '../../itinerario/data/estimacion_presupuesto.dart';
import '../../itinerario/data/itinerario_repository.dart';
import '../../lugares/data/propuesta_model.dart';
import '../../lugares/data/propuestas_repository.dart';
import '../../votacion/data/candidato_model.dart';
import '../../votacion/data/resultado_votacion.dart';
import '../../votacion/data/votacion_repository.dart';
import '../data/participante_model.dart';
import '../data/plan_model.dart';
import '../data/salidas_repository.dart';
import 'resumen_compartido.dart';

class DetallePlanViewModel extends ChangeNotifier {
  DetallePlanViewModel(
    this._repositorio,
    this._propuestas,
    this._votacion,
    this.planId, {
    this.itinerario,
  }) {
    // las propuestas pueden cambiar desde la ficha de un lugar en otra pestana
    _suscripcion = _propuestas.cambios
        .where((id) => id == planId)
        .listen((_) => _recargarPropuestas());
  }

  final SalidasRepository _repositorio;
  final PropuestasRepository _propuestas;
  final VotacionRepository _votacion;
  // null omite el itinerario y su estimacion
  final ItinerarioRepository? itinerario;
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
  // candidatos de la ultima seleccion guardada por el usuario
  Set<String> _misVotos = const {};
  String? _retirando;
  String? _errorPropuestas;
  bool _cerrando = false;
  String? _errorCierre;
  bool _resolviendo = false;
  String? _errorEmpate;
  List<ActividadModel> _actividades = const [];
  EstimacionPresupuesto? _estimacion;
  // respuesta en guardado; null cuando no hay guardado en curso
  EstadoAsistencia? _respondiendo;
  String? _errorAsistencia;
  bool _guardandoPlazo = false;
  String? _errorPlazo;
  List<CambioPlanModel> _cambios = const [];
  // actividad cuyo horario se esta guardando
  String? _cambiandoHorario;
  String? _errorHorario;
  bool _cancelando = false;
  String? _errorCancelacion;
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
  int get misVotos => _misVotos.length;

  bool get enVotacion => _salida?.plan.estado == EstadoPlan.enVotacion;

  // nadie puede elegir mas lugares que candidatos existentes
  int get maximoVotos {
    final maximo = _salida?.plan.maxSelecciones ?? 0;
    return maximo < _candidatos.length ? maximo : _candidatos.length;
  }

  bool get cerrando => _cerrando;
  String? get errorCierre => _errorCierre;
  bool get resolviendo => _resolviendo;
  String? get errorEmpate => _errorEmpate;

  // tras el cierre los candidatos se muestran como resultado ordenado por votos
  bool get votacionCerrada => switch (_salida?.plan.estado) {
    EstadoPlan.preparandoItinerario || EstadoPlan.confirmado => true,
    _ => false,
  };

  ResultadoVotacion? get resultado {
    final salida = _salida;
    if (salida == null || !votacionCerrada) return null;
    return ResultadoVotacion(_candidatos, salida.plan.maxActividades);
  }

  // solo administradores cierran, de forma manual (rf08, rb05)
  bool get puedeCerrarVotacion =>
      enVotacion && (_salida?.esAdministrador ?? false);

  // solo administradores eligen entre los empatados antes de armar el itinerario (rb06)
  bool get puedeResolverEmpate =>
      _salida?.plan.estado == EstadoPlan.preparandoItinerario &&
      (_salida?.esAdministrador ?? false) &&
      (resultado?.empatePendiente ?? false);

  // actividades en orden de ejecucion; existen desde el cierre de la votacion
  List<ActividadModel> get actividades => _actividades;
  EstimacionPresupuesto? get estimacion => _estimacion;

  bool get confirmado => _salida?.plan.estado == EstadoPlan.confirmado;
  bool get cancelado => _salida?.plan.estado == EstadoPlan.cancelado;

  // historial de reemplazos, horarios y cancelacion, del mas reciente al mas antiguo (rf10)
  List<CambioPlanModel> get cambios => _cambios;
  String? get cambiandoHorario => _cambiandoHorario;
  String? get errorHorario => _errorHorario;
  bool get cancelando => _cancelando;
  String? get errorCancelacion => _errorCancelacion;

  // solo administradores cambian actividades del plan confirmado (rf10)
  bool get puedeCambiarItinerario =>
      confirmado &&
      (_salida?.esAdministrador ?? false) &&
      _actividades.isNotEmpty;

  // solo administradores cancelan, desde cualquier fase activa (rf10)
  bool get puedeCancelar => puedeGestionar;

  // inicio de la salida: hora de la primera actividad del itinerario confirmado
  DateTime? get inicioSalida {
    if (!confirmado || _actividades.isEmpty) return null;
    return _actividades.first.inicio;
  }

  // resumen para la hoja de compartir; solo existe con el plan confirmado (rf09)
  String? get textoCompartido {
    final salida = _salida;
    if (salida == null || !confirmado) return null;
    return textoResumenCompartido(
      plan: salida.plan,
      actividades: _actividades,
      estimacion: _estimacion,
    );
  }

  // asistencia para toda la salida, solo con el itinerario confirmado (rf16)
  bool get puedeResponderAsistencia => confirmado;
  EstadoAsistencia? get respondiendo => _respondiendo;
  String? get errorAsistencia => _errorAsistencia;
  bool get guardandoPlazo => _guardandoPlazo;
  String? get errorPlazo => _errorPlazo;

  ParticipanteModel? get miParticipacion {
    final yo = usuarioActualId;
    for (final p in _participantes) {
      if (p.perfilId == yo) return p;
    }
    return null;
  }

  EstadoAsistencia get miAsistencia =>
      miParticipacion?.asistencia ?? EstadoAsistencia.pendiente;

  int conteoAsistencia(EstadoAsistencia estado) =>
      _participantes.where((p) => p.asistencia == estado).length;

  DateTime? get plazoAsistencia => _salida?.plan.fechaLimiteAsistencia;

  // el plazo vencido no bloquea la respuesta; solo se indica (rf16)
  bool get plazoAsistenciaVencido {
    final plazo = plazoAsistencia;
    return plazo != null && !plazo.isAfter(DateTime.now());
  }

  // solo administradores fijan o quitan el plazo, con el plan confirmado
  bool get puedeDefinirPlazoAsistencia =>
      confirmado && (_salida?.esAdministrador ?? false);

  // solo administradores ordenan y asignan horarios antes de confirmar (rf12, p08)
  bool get puedeRevisarItinerario =>
      _salida?.plan.estado == EstadoPlan.preparandoItinerario &&
      (_salida?.esAdministrador ?? false);

  // el itinerario se edita solo con el empate resuelto (rb06)
  bool get itinerarioBloqueadoPorEmpate => resultado?.empatePendiente ?? false;

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
      _misVotos = salida != null && enVotacion
          ? await _votacion.obtenerMisVotos(planId)
          : const {};
      final repositorio = itinerario;
      // un plan cancelado conserva el itinerario que tenia, si lo hubo
      final conItinerario =
          salida != null &&
          (votacionCerrada || cancelado) &&
          repositorio != null;
      _actividades = conItinerario
          ? await repositorio.obtenerActividades(planId)
          : const [];
      _estimacion = conItinerario && (!cancelado || _actividades.isNotEmpty)
          ? await repositorio.obtenerEstimacion(planId)
          : null;
      _cambios = repositorio != null && (confirmado || cancelado)
          ? await repositorio.obtenerCambios(planId)
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

  // true solo cuando el servidor guardo la respuesta; si falla se conserva la anterior
  Future<bool> responderAsistencia(EstadoAsistencia estado) async {
    if (_respondiendo != null ||
        !puedeResponderAsistencia ||
        estado == EstadoAsistencia.pendiente) {
      return false;
    }
    _respondiendo = estado;
    _errorAsistencia = null;
    _notificar();
    try {
      await _repositorio.responderAsistencia(planId: planId, estado: estado);
    } catch (error) {
      _errorAsistencia = _mensaje(error);
      _respondiendo = null;
      _notificar();
      return false;
    }
    final yo = usuarioActualId;
    _participantes = [
      for (final p in _participantes)
        p.perfilId == yo ? p.conAsistencia(estado) : p,
    ];
    _respondiendo = null;
    _notificar();
    return true;
  }

  // null quita el plazo; se reenvia el plazo de voto vigente porque la rpc reemplaza ambos
  Future<bool> definirPlazoAsistencia(DateTime? plazo) async {
    final salida = _salida;
    if (_guardandoPlazo || salida == null || !puedeDefinirPlazoAsistencia) {
      return false;
    }
    _guardandoPlazo = true;
    _errorPlazo = null;
    _notificar();
    try {
      final plan = await _votacion.definirPlazos(
        planId: planId,
        fechaLimiteVoto: salida.plan.fechaLimiteVoto,
        fechaLimiteAsistencia: plazo,
      );
      _salida = SalidaModel(
        plan: plan,
        miRol: salida.miRol,
        esCreador: salida.esCreador,
        totalParticipantes: salida.totalParticipantes,
      );
      return true;
    } catch (error) {
      _errorPlazo = _mensaje(error);
      return false;
    } finally {
      _guardandoPlazo = false;
      _notificar();
    }
  }

  // true solo cuando el servidor guardo el nuevo inicio; si falla se conserva el anterior
  Future<bool> cambiarHorario(ActividadModel actividad, DateTime inicio) async {
    final repositorio = itinerario;
    if (_cambiandoHorario != null ||
        repositorio == null ||
        !puedeCambiarItinerario) {
      return false;
    }
    _cambiandoHorario = actividad.id;
    _errorHorario = null;
    _notificar();
    try {
      await repositorio.cambiarHorario(
        actividadId: actividad.id,
        inicio: inicio,
      );
    } catch (error) {
      _errorHorario = _mensaje(error);
      _cambiandoHorario = null;
      _notificar();
      return false;
    }
    _cambiandoHorario = null;
    await cargar();
    return true;
  }

  // true solo cuando el servidor cancelo el plan; si falla el plan sigue igual
  Future<bool> cancelarPlan() async {
    if (_cancelando || !puedeCancelar) return false;
    _cancelando = true;
    _errorCancelacion = null;
    _notificar();
    try {
      await _repositorio.cancelarPlan(planId);
    } catch (error) {
      _errorCancelacion = _mensaje(error);
      _cancelando = false;
      _notificar();
      return false;
    }
    _cancelando = false;
    await cargar();
    return true;
  }

  // true solo cuando el servidor confirmo el cierre; un rechazo deja la votacion abierta
  Future<bool> cerrarVotacion() async {
    if (_cerrando || !puedeCerrarVotacion) return false;
    _cerrando = true;
    _errorCierre = null;
    _notificar();
    try {
      await _votacion.cerrarVotacion(planId);
    } catch (error) {
      _errorCierre = _mensaje(error);
      _cerrando = false;
      _notificar();
      return false;
    }
    _cerrando = false;
    await cargar();
    return true;
  }

  // true solo cuando el servidor guardo la eleccion; si falla el resultado no cambia
  Future<bool> resolverEmpate(Set<String> candidatoIds) async {
    if (_resolviendo || !puedeResolverEmpate) return false;
    _resolviendo = true;
    _errorEmpate = null;
    _notificar();
    try {
      await _votacion.resolverEmpate(
        planId: planId,
        candidatoIds: candidatoIds,
      );
    } catch (error) {
      _errorEmpate = _mensaje(error);
      _resolviendo = false;
      _notificar();
      return false;
    }
    _resolviendo = false;
    await cargar();
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
