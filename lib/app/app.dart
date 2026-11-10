import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../features/auth/data/auth_repository.dart';
import '../features/auth/presentation/sesion_view_model.dart';
import '../features/itinerario/data/itinerario_repository.dart';
import '../features/lugares/data/lugares_repository.dart';
import '../features/lugares/data/propuestas_repository.dart';
import '../features/lugares/presentation/destino_propuesta.dart';
import '../features/notificaciones/data/avisos_locales.dart';
import '../features/notificaciones/data/notificaciones_repository.dart';
import '../features/notificaciones/presentation/notificaciones_view_model.dart';
import '../features/perfil/data/perfil_repository.dart';
import '../features/salidas/data/salidas_repository.dart';
import '../features/votacion/data/votacion_repository.dart';
import 'router.dart';
import 'theme/app_theme.dart';

class QuedamosApp extends StatefulWidget {
  const QuedamosApp({
    super.key,
    required this.authRepository,
    required this.perfilRepository,
    required this.salidasRepository,
    required this.lugaresRepository,
    required this.propuestasRepository,
    required this.votacionRepository,
    required this.itinerarioRepository,
    required this.notificacionesRepository,
    required this.avisosLocales,
  });

  final AuthRepository authRepository;
  final PerfilRepository perfilRepository;
  final SalidasRepository salidasRepository;
  final LugaresRepository lugaresRepository;
  final PropuestasRepository propuestasRepository;
  final VotacionRepository votacionRepository;
  final ItinerarioRepository itinerarioRepository;
  final NotificacionesRepository notificacionesRepository;
  final AvisosLocales avisosLocales;

  @override
  State<QuedamosApp> createState() => _QuedamosAppState();
}

class _QuedamosAppState extends State<QuedamosApp> {
  late final SesionViewModel _sesion = SesionViewModel(
    haySesionInicial: widget.authRepository.haySesion,
    cambiosDeSesion: widget.authRepository.cambiosDeSesion,
  );

  // el router se crea una sola vez para no perder la navegacion al reconstruir
  late final GoRouter _router = crearRouter(_sesion);

  final _destino = DestinoPropuesta();

  late final NotificacionesViewModel _notificaciones = NotificacionesViewModel(
    widget.notificacionesRepository,
    widget.avisosLocales,
    cambios: widget.salidasRepository.cambiosDeAvisos,
  );

  late final AppLifecycleListener _ciclo;

  bool _habiaSesion = false;

  @override
  void initState() {
    super.initState();
    _sesion.addListener(_alCambiarSesion);
    // sincroniza los avisos al volver la app a primer plano
    _ciclo = AppLifecycleListener(
      onResume: () {
        if (_sesion.haySesion) _notificaciones.sincronizar();
      },
    );
    _iniciarAvisos();
  }

  Future<void> _iniciarAvisos() async {
    try {
      await widget.avisosLocales.inicializar(_abrirAviso);
      final payload = await widget.avisosLocales.payloadDeArranque();
      if (payload != null) _abrirAviso(payload);
    } catch (_) {
      // sin avisos locales la app sigue funcionando con el historial
    }
    _habiaSesion = _sesion.haySesion;
    if (_habiaSesion) _notificaciones.alIniciarSesion();
  }

  // el destino y los avisos pertenecen a la cuenta; no pasan a la siguiente sesion
  void _alCambiarSesion() {
    final haySesion = _sesion.haySesion;
    if (haySesion == _habiaSesion) return;
    _habiaSesion = haySesion;
    if (haySesion) {
      _notificaciones.alIniciarSesion();
    } else {
      _destino.limpiar();
      _notificaciones.limpiar();
    }
  }

  // tocar un aviso del sistema abre su contexto y lo marca leido
  void _abrirAviso(String? payload) {
    final datos = NotificacionesViewModel.leerPayload(payload);
    if (datos == null || !_sesion.haySesion) return;
    _notificaciones.marcarLeida(datos.id);
    _router.go(datos.ruta);
  }

  @override
  void dispose() {
    _sesion.removeListener(_alCambiarSesion);
    _ciclo.dispose();
    _notificaciones.dispose();
    _destino.dispose();
    _router.dispose();
    _sesion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthRepository>.value(value: widget.authRepository),
        Provider<PerfilRepository>.value(value: widget.perfilRepository),
        Provider<SalidasRepository>.value(value: widget.salidasRepository),
        Provider<LugaresRepository>.value(value: widget.lugaresRepository),
        Provider<PropuestasRepository>.value(
          value: widget.propuestasRepository,
        ),
        Provider<VotacionRepository>.value(value: widget.votacionRepository),
        Provider<ItinerarioRepository>.value(
          value: widget.itinerarioRepository,
        ),
        ChangeNotifierProvider<DestinoPropuesta>.value(value: _destino),
        ChangeNotifierProvider<NotificacionesViewModel>.value(
          value: _notificaciones,
        ),
        ChangeNotifierProvider<SesionViewModel>.value(value: _sesion),
      ],
      child: MaterialApp.router(
        title: 'Quedamos',
        theme: AppTheme.claro,
        routerConfig: _router,
        debugShowCheckedModeBanner: false,
        // calendario, reloj y textos de material en espanol
        locale: const Locale('es'),
        supportedLocales: const [Locale('es')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
      ),
    );
  }
}
