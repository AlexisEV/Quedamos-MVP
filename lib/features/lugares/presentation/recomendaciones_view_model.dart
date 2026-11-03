import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/errors/app_exception.dart';
import '../data/lugar_model.dart';
import '../data/lugares_repository.dart';
import '../data/propuestas_repository.dart';
import 'destino_propuesta.dart';

// recomendaciones por zona, categoria y tope de presupuesto (rf13, p09)
class RecomendacionesViewModel extends ChangeNotifier {
  RecomendacionesViewModel(this._lugares, this._propuestas, this._destino) {
    _destino.addListener(_alCambiarDestino);
    _suscripcion = _propuestas.cambios.listen((planId) {
      if (planId == _destino.planId) unawaited(_cargarPropuestos());
    });
  }

  // topes fijos en soles por persona; el filtro es precio estimado <= tope
  static const topesPresupuesto = [20, 40, 60, 100];

  final LugaresRepository _lugares;
  final PropuestasRepository _propuestas;
  final DestinoPropuesta _destino;
  late final StreamSubscription<String> _suscripcion;

  ZonaLugar? _zona;
  CategoriaLugar? _categoria;
  int? _tope;
  List<LugarModel> _recomendaciones = const [];
  Set<String> _propuestosEnDestino = const {};
  bool _consultando = false;
  bool _consultado = false;
  String? _error;
  bool _desechado = false;

  ZonaLugar? get zona => _zona;
  CategoriaLugar? get categoria => _categoria;
  int? get tope => _tope;
  List<LugarModel> get recomendaciones => _recomendaciones;
  bool get consultando => _consultando;
  bool get consultado => _consultado;
  String? get error => _error;
  // las tres entradas son obligatorias antes de consultar
  bool get puedeConsultar =>
      _zona != null && _categoria != null && _tope != null && !_consultando;
  bool get sinOpciones =>
      _consultado && _error == null && _recomendaciones.isEmpty;

  bool yaPropuesto(String lugarId) => _propuestosEnDestino.contains(lugarId);

  void elegirZona(ZonaLugar zona) {
    if (_zona == zona) return;
    _zona = zona;
    _reiniciarResultado();
  }

  void elegirCategoria(CategoriaLugar categoria) {
    if (_categoria == categoria) return;
    _categoria = categoria;
    _reiniciarResultado();
  }

  void elegirTope(int tope) {
    if (_tope == tope) return;
    _tope = tope;
    _reiniciarResultado();
  }

  Future<void> consultar() async {
    final zona = _zona;
    final categoria = _categoria;
    final tope = _tope;
    if (zona == null || categoria == null || tope == null || _consultando) {
      return;
    }
    _consultando = true;
    _error = null;
    _notificar();
    try {
      _recomendaciones = await _lugares.obtenerRecomendaciones(
        zona: zona,
        categoria: categoria,
        presupuestoSoles: tope.toDouble(),
      );
      _consultado = true;
      await _cargarPropuestos();
    } catch (error) {
      _recomendaciones = const [];
      _consultado = false;
      _error = error is AppException ? error.mensaje : MensajesError.generico;
    } finally {
      _consultando = false;
      _notificar();
    }
  }

  // la marca ya propuesto es informativa: si falla la lectura no se muestra
  Future<void> _cargarPropuestos() async {
    final planId = _destino.planId;
    if (planId == null || _recomendaciones.isEmpty) {
      _propuestosEnDestino = const {};
      _notificar();
      return;
    }
    try {
      final destinos = await _propuestas.obtenerDestinos();
      _propuestosEnDestino = const {};
      for (final destino in destinos) {
        if (destino.plan.id == planId) {
          _propuestosEnDestino = destino.lugaresPropuestos;
        }
      }
    } catch (_) {
      _propuestosEnDestino = const {};
    }
    _notificar();
  }

  void _alCambiarDestino() => unawaited(_cargarPropuestos());

  // un cambio de entrada invalida el resultado anterior hasta volver a consultar
  void _reiniciarResultado() {
    _recomendaciones = const [];
    _propuestosEnDestino = const {};
    _consultado = false;
    _error = null;
    _notificar();
  }

  void _notificar() {
    if (!_desechado) notifyListeners();
  }

  @override
  void dispose() {
    _desechado = true;
    _destino.removeListener(_alCambiarDestino);
    _suscripcion.cancel();
    super.dispose();
  }
}
