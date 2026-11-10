import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/errors/app_exception.dart';
import '../data/avisos_locales.dart';
import '../data/notificacion_model.dart';
import '../data/notificaciones_repository.dart';

// estado global de avisos: sincroniza la tabla notificaciones con los avisos
// locales del dispositivo y alimenta la pestana avisos (rf14, p10)
class NotificacionesViewModel extends ChangeNotifier {
  NotificacionesViewModel(
    this._repositorio,
    this._avisos, {
    Stream<void>? cambios,
    DateTime Function()? reloj,
  }) : _reloj = reloj ?? DateTime.now {
    _suscripcion = cambios?.listen((_) => sincronizar());
  }

  final NotificacionesRepository _repositorio;
  final AvisosLocales _avisos;
  final DateTime Function() _reloj;
  StreamSubscription<void>? _suscripcion;

  List<NotificacionModel> _todas = const [];
  bool _cargando = false;
  bool _cargado = false;
  String? _error;
  bool? _permiso;
  bool _permisoPedido = false;
  bool _permisoBloqueado = false;
  bool _marcandoTodas = false;
  String? _errorMarcar;
  Future<void>? _enCurso;
  bool _repetir = false;
  bool _activo = true;

  bool get cargando => _cargando;
  bool get cargado => _cargado;
  String? get error => _error;

  // null mientras no se consulta el permiso del dispositivo
  bool? get permiso => _permiso;

  // el sistema ya no muestra el dialogo: se activa desde ajustes del telefono
  bool get permisoBloqueado => _permisoBloqueado;
  bool get marcandoTodas => _marcandoTodas;
  String? get errorMarcar => _errorMarcar;

  // avisos cuyo momento ya llego, del mas reciente al mas antiguo
  List<NotificacionModel> get historial {
    final ahora = _reloj();
    return _todas.where((n) => n.visibleEn(ahora)).toList()
      ..sort((a, b) => b.programadaPara.compareTo(a.programadaPara));
  }

  int get noLeidas => historial.where((n) => !n.leida).length;

  // tras iniciar sesion o abrir la app con sesion: pide el permiso una vez
  // por sesion y sincroniza
  Future<void> alIniciarSesion() async {
    _activo = true;
    if (!_permisoPedido) {
      _permisoPedido = true;
      final concedido = await _consultarPermiso();
      if (!concedido) await pedirPermiso();
    }
    await sincronizar();
  }

  Future<bool> _consultarPermiso() async {
    try {
      _permiso = await _avisos.permisoConcedido();
    } catch (_) {
      _permiso = false;
    }
    return _permiso!;
  }

  Future<void> pedirPermiso() async {
    bool concedido;
    try {
      concedido = await _avisos.pedirPermiso();
    } catch (_) {
      concedido = false;
    }
    _permiso = concedido;
    _permisoBloqueado = !concedido;
    notifyListeners();
    // con el permiso nuevo se programan los avisos ya leidos del servidor
    if (concedido && _cargado) await sincronizar();
  }

  // evita dos sincronizaciones a la vez; una llamada durante otra la repite
  Future<void> sincronizar() {
    if (_enCurso != null) {
      _repetir = true;
      return _enCurso!;
    }
    _enCurso = _sincronizar().whenComplete(() => _enCurso = null);
    return _enCurso!;
  }

  Future<void> _sincronizar() async {
    do {
      _repetir = false;
      await _sincronizarUnaVez();
    } while (_repetir && _activo);
  }

  Future<void> _sincronizarUnaVez() async {
    if (!_activo) return;
    _cargando = true;
    notifyListeners();
    try {
      final filas = await _repositorio.obtenerNotificaciones();
      if (!_activo) return;
      _todas = filas;
      _error = null;
      _cargado = true;
      await _consultarPermiso();
      await _aplicarEnDispositivo(filas);
    } on AppException catch (e) {
      _error = e.mensaje;
    } finally {
      _cargando = false;
      if (_activo) notifyListeners();
    }
  }

  // programa los recordatorios futuros, cancela los anulados y muestra los
  // cambios o cancelaciones aun no entregados
  Future<void> _aplicarEnDispositivo(List<NotificacionModel> filas) async {
    final ahora = _reloj();
    final entregadas = <String>[];
    for (final n in filas) {
      try {
        if (!n.activa) {
          await _avisos.cancelar(n.idLocal);
        } else if (n.programadaPara.isAfter(ahora)) {
          if (_permiso == true) {
            await _avisos.programar(
              id: n.idLocal,
              titulo: n.titulo,
              cuerpo: n.cuerpo,
              momento: n.programadaPara,
              payload: payloadDe(n),
            );
          }
        } else if (n.tipo.esInmediato &&
            n.entregadaEn == null &&
            _permiso == true) {
          await _avisos.mostrar(
            id: n.idLocal,
            titulo: n.titulo,
            cuerpo: n.cuerpo,
            payload: payloadDe(n),
          );
          entregadas.add(n.id);
        }
      } catch (_) {
        // una falla del dispositivo no impide aplicar los demas avisos
      }
    }
    if (entregadas.isEmpty) return;
    try {
      await _repositorio.marcar(entregadas, entregada: true);
      final marcadas = entregadas.toSet();
      _todas = [
        for (final n in _todas)
          marcadas.contains(n.id) ? n.copiarCon(entregadaEn: ahora) : n,
      ];
    } on AppException {
      // sin marca, el aviso puede repetirse en la siguiente sincronizacion
    }
  }

  // id y ruta separados por la barra vertical
  static String payloadDe(NotificacionModel n) => '${n.id}|${n.rutaDestino}';

  static ({String id, String ruta})? leerPayload(String? payload) {
    if (payload == null) return null;
    final corte = payload.indexOf('|');
    if (corte <= 0 || corte == payload.length - 1) return null;
    return (
      id: payload.substring(0, corte),
      ruta: payload.substring(corte + 1),
    );
  }

  // abrir un aviso lo marca leido; la navegacion no espera al servidor
  Future<void> marcarLeida(String id) async {
    final aviso = _todas.where((n) => n.id == id).firstOrNull;
    if (aviso != null && aviso.leida) return;
    try {
      await _repositorio.marcar([id], leida: true);
    } on AppException {
      return;
    }
    _reemplazarLeidas({id});
  }

  Future<void> marcarTodas() async {
    final ids = historial.where((n) => !n.leida).map((n) => n.id).toList();
    if (ids.isEmpty || _marcandoTodas) return;
    _marcandoTodas = true;
    _errorMarcar = null;
    notifyListeners();
    try {
      await _repositorio.marcar(ids, leida: true);
      _reemplazarLeidas(ids.toSet());
    } on AppException catch (e) {
      _errorMarcar = e.mensaje;
    } finally {
      _marcandoTodas = false;
      notifyListeners();
    }
  }

  void _reemplazarLeidas(Set<String> ids) {
    final ahora = _reloj();
    _todas = [
      for (final n in _todas)
        ids.contains(n.id) ? n.copiarCon(leidaEn: ahora) : n,
    ];
    notifyListeners();
  }

  // al cerrar sesion: sin avisos de la cuenta anterior en el dispositivo
  Future<void> limpiar() async {
    _activo = false;
    _todas = const [];
    _cargado = false;
    _error = null;
    _permisoPedido = false;
    _permisoBloqueado = false;
    _errorMarcar = null;
    notifyListeners();
    try {
      await _avisos.cancelarTodo();
    } catch (_) {
      // sin avisos que cancelar o plugin no disponible
    }
  }

  @override
  void dispose() {
    _suscripcion?.cancel();
    super.dispose();
  }
}
