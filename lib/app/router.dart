import 'package:go_router/go_router.dart';

import '../features/auth/presentation/acceso_screen.dart';
import '../features/auth/presentation/sesion_view_model.dart';
import '../features/lugares/presentation/explorar_screen.dart';
import '../features/notificaciones/presentation/notificaciones_screen.dart';
import '../features/perfil/presentation/perfil_screen.dart';
import '../features/salidas/presentation/mis_salidas_screen.dart';
import 'shell_screen.dart';

abstract final class Rutas {
  static const acceso = '/acceso';
  static const salidas = '/salidas';
  static const explorar = '/explorar';
  static const notificaciones = '/notificaciones';
  static const perfil = '/perfil';
}

GoRouter crearRouter(SesionViewModel sesion) {
  return GoRouter(
    initialLocation: Rutas.salidas,
    refreshListenable: sesion,
    redirect: (context, state) {
      final enAcceso = state.matchedLocation == Rutas.acceso;
      // sin sesion solo se permite p11; con sesion p11 ya no aplica
      if (!sesion.haySesion) return enAcceso ? null : Rutas.acceso;
      if (enAcceso) return Rutas.salidas;
      return null;
    },
    routes: [
      GoRoute(
        path: Rutas.acceso,
        builder: (context, state) => const AccesoScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            ShellScreen(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Rutas.salidas,
                builder: (context, state) => const MisSalidasScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Rutas.explorar,
                builder: (context, state) => const ExplorarScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Rutas.notificaciones,
                builder: (context, state) => const NotificacionesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Rutas.perfil,
                builder: (context, state) => const PerfilScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
