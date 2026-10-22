import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../features/auth/data/auth_repository.dart';
import '../features/auth/presentation/sesion_view_model.dart';
import '../features/perfil/data/perfil_repository.dart';
import '../features/salidas/data/salidas_repository.dart';
import 'router.dart';
import 'theme/app_theme.dart';

class QuedamosApp extends StatefulWidget {
  const QuedamosApp({
    super.key,
    required this.authRepository,
    required this.perfilRepository,
    required this.salidasRepository,
  });

  final AuthRepository authRepository;
  final PerfilRepository perfilRepository;
  final SalidasRepository salidasRepository;

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

  @override
  void dispose() {
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
        ChangeNotifierProvider<SesionViewModel>.value(value: _sesion),
      ],
      child: MaterialApp.router(
        title: 'Quedamos',
        theme: AppTheme.claro,
        routerConfig: _router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
