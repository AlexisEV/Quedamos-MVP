import 'package:flutter/foundation.dart';

import '../../../core/errors/app_exception.dart';
import '../../lugares/data/lugar_model.dart';
import '../../lugares/data/lugares_repository.dart';
import '../../salidas/data/plan_model.dart';
import '../../salidas/data/salidas_repository.dart';
import '../../votacion/data/votacion_repository.dart';
import '../data/actividad_model.dart';
import '../data/estimacion_presupuesto.dart';
import '../data/itinerario_repository.dart';

// alternativa para reemplazar una actividad: de la votacion (con votos) o del catalogo
class AlternativaReemplazo {
  const AlternativaReemplazo({
    required this.lugarId,
    required this.nombre,
    this.categoria,
    this.zona,
    this.precioEstimadoPen,
    this.votos,
  });

  final String lugarId;
  final String nombre;
  final CategoriaLugar? categoria;
  final ZonaLugar? zona;
  // null cuando el precio es desconocido
  final double? precioEstimadoPen;
  // solo para candidatos de la votacion
  final int? votos;
}

// p07: el administrador elige otro lugar para una actividad confirmada (rf10, rb11)
class ReemplazarActividadViewModel extends ChangeNotifier {
  ReemplazarActividadViewModel(
    this._salidas,
    this._votacion,
    this._lugares,
    this._itinerario, {
    required this.planId,
    required this.actividadId,
  });

  final SalidasRepository _salidas;
  final VotacionRepository _votacion;
  final LugaresRepository _lugares;
  final ItinerarioRepository _itinerario;
  final String planId;
  final String actividadId;

  SalidaModel? _salida;
  List<ActividadModel> _actividades = const [];
  EstimacionPresupuesto? _estimacion;
  List<AlternativaReemplazo> _deVotacion = const [];
  List<AlternativaReemplazo> _catalogo = const [];
  ZonaLugar? _zona;
  CategoriaLugar? _categoria;
  String? _elegido;
  bool _cargando = false;
  String? _error;
  bool _guardando = false;
  String? _errorGuardado;
  bool _desechado = false;

  SalidaModel? get salida => _salida;
  EstimacionPresupuesto? get estimacion => _estimacion;
  bool get cargando => _cargando;
  String? get error => _error;
  bool get guardando => _guardando;
  String? get errorGuardado => _errorGuardado;
  ZonaLugar? get zona => _zona;
  CategoriaLugar? get categoria => _categoria;
  String? get elegido => _elegido;

  ActividadModel? get actividad {
    for (final a in _actividades) {
      if (a.id == actividadId) return a;
    }
    return null;
  }

  // solo un administrador con el plan confirmado y la actividad vigente
  bool get puedeReemplazar =>
      _salida != null &&
      _salida!.esAdministrador &&
      _salida!.plan.estado == EstadoPlan.confirmado &&
      actividad != null;

  // candidatos no elegidos de la votacion, de mas a menos votados
  List<AlternativaReemplazo> get deVotacion => _deVotacion;

  // catalogo filtrado por los chips, sin lugares del itinerario ni de la votacion,
  // de mas economico a mas caro y con el precio desconocido al final
  List<AlternativaReemplazo> get catalogo => _catalogo
      .where(
        (a) =>
            (_zona == null || a.zona == _zona) &&
            (_categoria == null || a.categoria == _categoria),
      )
      .toList();

  AlternativaReemplazo? get alternativaElegida {
    for (final a in [..._deVotacion, ..._catalogo]) {
      if (a.lugarId == _elegido) return a;
    }
    return null;
  }

  // estimacion por persona si la actividad se reemplaza por el lugar dado (rb08)
  double? totalCon(AlternativaReemplazo alternativa) {
    final e = _estimacion;
    final actual = actividad;
    if (e == null || actual == null) return null;
    return e.totalEstimado -
        (actual.precioEstimadoPen ?? 0) +
        (alternativa.precioEstimadoPen ?? 0);
  }

  // la estimacion queda incompleta si alguna actividad resultante no tiene precio
  bool incompletaCon(AlternativaReemplazo alternativa) {
    final e = _estimacion;
    final actual = actividad;
    if (e == null || actual == null) return false;
    final sinPrecio =
        e.sinPrecio -
        (actual.precioEstimadoPen == null ? 1 : 0) +
        (alternativa.precioEstimadoPen == null ? 1 : 0);
    return sinPrecio > 0;
  }

  // exceso sobre el presupuesto por persona; 0 si no lo supera
  double excesoCon(AlternativaReemplazo alternativa) {
    final total = totalCon(alternativa);
    final presupuesto = _estimacion?.presupuestoSoles;
    if (total == null || presupuesto == null || total <= presupuesto) return 0;
    return total - presupuesto;
  }

  Future<void> cargar() async {
    if (_cargando) return;
    _cargando = true;
    _error = null;
    _notificar();
    try {
      _salida = await _salidas.obtenerSalida(planId);
      if (_salida == null) {
        _actividades = const [];
        return;
      }
      _actividades = await _itinerario.obtenerActividades(planId);
      _estimacion = await _itinerario.obtenerEstimacion(planId);
      final candidatos = await _votacion.obtenerCandidatos(planId);
      final lugares = await _lugares.obtenerLugares();
      final enItinerario = {for (final a in _actividades) a.lugarId};

      final deVotacion = [
        for (final c in candidatos)
          if (!enItinerario.contains(c.lugarId) && c.nombreLugar != null)
            AlternativaReemplazo(
              lugarId: c.lugarId,
              nombre: c.nombreLugar!,
              categoria: c.categoria,
              zona: c.zona,
              precioEstimadoPen: c.precioEstimadoPen,
              votos: c.totalVotos ?? 0,
            ),
      ]..sort((a, b) => (b.votos ?? 0).compareTo(a.votos ?? 0));
      _deVotacion = deVotacion;

      final yaListados = {
        ...enItinerario,
        for (final a in deVotacion) a.lugarId,
      };
      _catalogo = [
        for (final l in lugares)
          if (!yaListados.contains(l.id))
            AlternativaReemplazo(
              lugarId: l.id,
              nombre: l.nombre,
              categoria: l.categoria,
              zona: l.zona,
              precioEstimadoPen: l.precioEstimadoPen,
            ),
      ]..sort(_porPrecio);

      // los chips arrancan con la zona y categoria de la actividad actual
      final actual = actividad;
      if (actual != null && _elegido == null) {
        _zona = actual.zona;
        _categoria = actual.categoria;
      }
      // una eleccion que ya no esta disponible se descarta
      if (alternativaElegida == null) _elegido = null;
    } catch (error) {
      _error = _mensaje(error);
    } finally {
      _cargando = false;
      _notificar();
    }
  }

  static int _porPrecio(AlternativaReemplazo a, AlternativaReemplazo b) {
    final pa = a.precioEstimadoPen;
    final pb = b.precioEstimadoPen;
    if (pa == null && pb != null) return 1;
    if (pa != null && pb == null) return -1;
    if (pa != null && pb != null && pa != pb) return pa.compareTo(pb);
    return a.nombre.compareTo(b.nombre);
  }

  void elegirZona(ZonaLugar? zona) {
    _zona = zona;
    _notificar();
  }

  void elegirCategoria(CategoriaLugar? categoria) {
    _categoria = categoria;
    _notificar();
  }

  void elegir(String lugarId) {
    if (_guardando) return;
    _elegido = lugarId;
    _errorGuardado = null;
    _notificar();
  }

  // true solo cuando el servidor guardo el reemplazo; si falla el itinerario no cambia
  Future<bool> confirmar() async {
    final lugarId = _elegido;
    if (_guardando || lugarId == null || !puedeReemplazar) return false;
    _guardando = true;
    _errorGuardado = null;
    _notificar();
    try {
      await _itinerario.reemplazarActividad(
        actividadId: actividadId,
        lugarId: lugarId,
      );
      return true;
    } catch (error) {
      _errorGuardado = _mensaje(error);
      return false;
    } finally {
      _guardando = false;
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
