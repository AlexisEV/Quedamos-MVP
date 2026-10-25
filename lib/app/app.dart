import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../features/auth/data/auth_repository.dart';
import '../features/auth/presentation/sesion_view_model.dart';
import '../features/lugares/data/lugares_repository.dart';
import '../features/lugares/data/propuestas_repository.dart';
import '../features/lugares/presentation/destino_propuesta.dart';
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
  });

  final AuthRepository authRepository;
  final PerfilRepository perfilRepository;
  final SalidasRepository salidasRepository;
  final LugaresRepository lugaresRepository;
  final PropuestasRepository propuestasRepository;
  final VotacionRepository votacionRepository;

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

  @override
  void initState() {
    super.initState();
    _sesion.addListener(_limpiarDestinoSinSesion);
  }

  // el destino pertenece a la cuenta; no pasa a la siguiente sesion
  void _limpiarDestinoSinSesion() {
    if (!_sesion.haySesion) _destino.limpiar();
  }

  @override
  void dispose() {
    _sesion.removeListener(_limpiarDestinoSinSesion);
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
        ChangeNotifierProvider<DestinoPropuesta>.value(value: _destino),
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
