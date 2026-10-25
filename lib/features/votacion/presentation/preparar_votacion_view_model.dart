import 'package:flutter/foundation.dart';

import '../../../core/errors/app_exception.dart';
import '../../lugares/data/propuesta_model.dart';
import '../../lugares/data/propuestas_repository.dart';
import '../../salidas/data/plan_model.dart';
import '../../salidas/data/salidas_repository.dart';
import '../../salidas/presentation/crear_plan_view_model.dart';
import '../data/votacion_repository.dart';

// limites que los administradores ajustan hasta abrir la votacion (rf18)
const limitesPreparables = [
  LimitePlan.candidatos,
  LimitePlan.selecciones,
  LimitePlan.actividades,
];

// p05 preparar votacion: candidatos, limites, plazo de voto y apertura
class PrepararVotacionViewModel extends ChangeNotifier {
  PrepararVotacionViewModel(
    this._salidas,
    this._propuestas,
    this._votacion,
    this.planId, {
    DateTime Function()? ahora,
  }) : _ahora = ahora ?? DateTime.now;

  final SalidasRepository _salidas;
  final PropuestasRepository _propuestas;
  final VotacionRepository _votacion;
  final String planId;
  final DateTime Function() _ahora;

  SalidaModel? _salida;
  List<PropuestaModel> _listaPropuestas = const [];
  // lugares de la lista final guardada en el servidor
  Set<String> _guardados = const {};
  // valores en edicion
  Set<String> _seleccion = {};
  final Map<LimitePlan, int> _valores = {};
  DateTime? _plazoVoto;
  bool _cargando = false;
  bool _noEncontrado = false;
  String? _error;
  bool _guardando = false;
  bool _abriendo = false;
  String? _errorAccion;
  bool _desechado = false;

  SalidaModel? get salida => _salida;
  List<PropuestaModel> get propuestas => _listaPropuestas;
  bool get cargando => _cargando;
  bool get noEncontrado => _noEncontrado;
  String? get error => _error;
  bool get guardando => _guardando;
  bool get abriendo => _abriendo;
  bool get ocupado => _guardando || _abriendo;
  String? get errorAccion => _errorAccion;
  String? get usuarioActualId => _propuestas.usuarioActualId;
  DateTime? get plazoVoto => _plazoVoto;
  Set<String> get seleccion => Set.unmodifiable(_seleccion);

  // solo administradores mientras el plan recibe propuestas
  bool get puedePreparar {
    final salida = _salida;
    return salida != null &&
        salida.esAdministrador &&
        salida.plan.estado == EstadoPlan.recibiendoPropuestas;
  }

  int valor(LimitePlan limite) => _valores[limite] ?? limite.inicial;

  bool puedeBajar(LimitePlan limite) =>
      !ocupado && valor(limite) > limite.minimo;

  bool puedeSubir(LimitePlan limite) =>
      !ocupado && valor(limite) < limite.maximo;

  void bajar(LimitePlan limite) {
    if (!puedeBajar(limite)) return;
    _valores[limite] = valor(limite) - 1;
    notifyListeners();
  }

  void subir(LimitePlan limite) {
    if (!puedeSubir(limite)) return;
    _valores[limite] = valor(limite) + 1;
    notifyListeners();
  }

  String? get errorLimites {
    if (valor(LimitePlan.selecciones) > valor(LimitePlan.candidatos)) {
      return MensajesError.seleccionesMayoresQueCandidatos;
    }
    if (_seleccion.length > valor(LimitePlan.candidatos)) {
      return MensajesError.candidatosSuperanMaximo;
    }
    return null;
  }

  bool estaSeleccionado(String lugarId) => _seleccion.contains(lugarId);

  // un candidato nuevo solo entra si queda espacio bajo el maximo
  bool puedeAlternar(String lugarId) =>
      !ocupado &&
      (estaSeleccionado(lugarId) ||
          _seleccion.length < valor(LimitePlan.candidatos));

  void alternar(String lugarId) {
    if (!puedeAlternar(lugarId)) return;
    if (!_seleccion.remove(lugarId)) _seleccion.add(lugarId);
    notifyListeners();
  }

  // null quita el plazo
  void fijarPlazoVoto(DateTime? instante) {
    if (ocupado) return;
    _plazoVoto = instante?.toUtc();
    notifyListeners();
  }

  bool get _plazoCambio => _plazoVoto != _salida?.plan.fechaLimiteVoto;

  // un plazo nuevo debe ser futuro; el ya guardado se puede conservar
  String? get errorPlazo {
    final plazo = _plazoVoto;
    if (plazo == null || !_plazoCambio) return null;
    return plazo.isAfter(_ahora()) ? null : MensajesError.plazoEnPasado;
  }

  bool get _limitesCambiaron {
    final plan = _salida?.plan;
    if (plan == null) return false;
    return valor(LimitePlan.candidatos) != plan.maxCandidatos ||
        valor(LimitePlan.selecciones) != plan.maxSelecciones ||
        valor(LimitePlan.actividades) != plan.maxActividades;
  }

  bool get _candidatosCambiaron => !setEquals(_seleccion, _guardados);

  bool get hayCambios =>
      _limitesCambiaron || _candidatosCambiaron || _plazoCambio;

  bool get _valido => errorLimites == null && errorPlazo == null;

  bool get puedeGuardar => puedePreparar && !ocupado && hayCambios && _valido;

  bool get puedeAbrir =>
      puedePreparar && !ocupado && _seleccion.isNotEmpty && _valido;

  Future<void> cargar() async {
    if (_cargando || ocupado) return;
    _cargando = true;
    _error = null;
    _notificar();
    try {
      final salida = await _salidas.obtenerSalida(planId);
      _noEncontrado = salida == null;
      if (salida != null) {
        final propuestas = await _propuestas.obtenerPropuestas(planId);
        final candidatos = await _votacion.obtenerCandidatos(planId);
        // una recarga no descarta lo que el administrador aun no guardo
        final conservarLimites = _limitesCambiaron;
        final conservarCandidatos = _candidatosCambiaron;
        final conservarPlazo = _salida != null && _plazoCambio;
        _salida = salida;
        _listaPropuestas = propuestas;
        _guardados = {for (final c in candidatos) c.lugarId};
        _reiniciarEdicion(
          salida.plan,
          conservarLimites: conservarLimites,
          conservarCandidatos: conservarCandidatos,
          conservarPlazo: conservarPlazo,
        );
      }
    } catch (error) {
      _error = _mensaje(error);
    } finally {
      _cargando = false;
      _notificar();
    }
  }

  // cada valor editado se conserva; el resto toma lo guardado en el servidor
  void _reiniciarEdicion(
    PlanModel plan, {
    bool conservarLimites = false,
    bool conservarCandidatos = false,
    bool conservarPlazo = false,
  }) {
    if (conservarCandidatos) {
      // una propuesta retirada mientras tanto ya no puede ser candidata
      final propuestos = {for (final p in _listaPropuestas) p.lugarId};
      _seleccion = _seleccion.intersection(propuestos);
    } else {
      _seleccion = Set.of(_guardados);
    }
    if (!conservarLimites) {
      _valores
        ..[LimitePlan.candidatos] = plan.maxCandidatos
        ..[LimitePlan.selecciones] = plan.maxSelecciones
        ..[LimitePlan.actividades] = plan.maxActividades;
    }
    if (!conservarPlazo) _plazoVoto = plan.fechaLimiteVoto;
    _errorAccion = null;
  }

  // true solo cuando el servidor confirmo todos los cambios
  Future<bool> guardar() async {
    if (!puedeGuardar) return false;
    _guardando = true;
    _errorAccion = null;
    _notificar();
    try {
      await _guardarCambios();
      return true;
    } catch (error) {
      _errorAccion = _mensaje(error);
      return false;
    } finally {
      _guardando = false;
      _notificar();
    }
  }

  // guarda lo pendiente y abre la votacion; true solo con la confirmacion del servidor
  Future<bool> abrir() async {
    if (!puedeAbrir) return false;
    _abriendo = true;
    _errorAccion = null;
    _notificar();
    try {
      await _guardarCambios();
      _actualizarPlan(await _votacion.abrirVotacion(planId));
      return true;
    } catch (error) {
      _errorAccion = _mensaje(error);
      return false;
    } finally {
      _abriendo = false;
      _notificar();
    }
  }

  // cada paso confirmado se refleja en el estado guardado, para que un
  // reintento tras una falla parcial solo envie lo que falta
  Future<void> _guardarCambios() async {
    final plan = _salida!.plan;
    // si la lista nueva cabe en el maximo vigente se guarda antes de cambiarlo;
    // si no, primero se sube el maximo
    final candidatosPrimero = _seleccion.length <= plan.maxCandidatos;
    if (candidatosPrimero) await _guardarCandidatos();
    if (_limitesCambiaron) {
      _actualizarPlan(
        await _votacion.actualizarLimites(
          planId: planId,
          maxCandidatos: valor(LimitePlan.candidatos),
          maxSelecciones: valor(LimitePlan.selecciones),
          maxActividades: valor(LimitePlan.actividades),
        ),
      );
    }
    if (!candidatosPrimero) await _guardarCandidatos();
    if (_plazoCambio) {
      _actualizarPlan(
        await _votacion.definirPlazos(
          planId: planId,
          fechaLimiteVoto: _plazoVoto,
          // la asistencia se define al confirmar; se conserva la vigente
          fechaLimiteAsistencia: _salida!.plan.fechaLimiteAsistencia,
        ),
      );
    }
  }

  Future<void> _guardarCandidatos() async {
    if (!_candidatosCambiaron) return;
    final lista = Set.of(_seleccion);
    await _votacion.definirCandidatos(planId: planId, lugarIds: lista);
    _guardados = lista;
  }

  void _actualizarPlan(PlanModel plan) {
    final salida = _salida!;
    _salida = SalidaModel(
      plan: plan,
      miRol: salida.miRol,
      esCreador: salida.esCreador,
      totalParticipantes: salida.totalParticipantes,
    );
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
