import 'package:go_router/go_router.dart';

import '../features/auth/presentation/acceso_screen.dart';
import '../features/auth/presentation/sesion_view_model.dart';
import '../features/lugares/presentation/explorar_screen.dart';
import '../features/lugares/presentation/ficha_lugar_screen.dart';
import '../features/notificaciones/presentation/notificaciones_screen.dart';
import '../features/perfil/presentation/perfil_screen.dart';
import '../features/salidas/presentation/crear_plan_screen.dart';
import '../features/salidas/presentation/detalle_plan_screen.dart';
import '../features/salidas/presentation/mis_salidas_screen.dart';
import '../features/votacion/presentation/votacion_screen.dart';
import 'shell_screen.dart';

abstract final class Rutas {
  static const acceso = '/acceso';
  static const salidas = '/salidas';
  static const crearPlan = '/salidas/crear';
  static String detallePlan(String planId) => '/salidas/$planId';
  static String votacion(String planId) => '/salidas/$planId/votacion';
  static const explorar = '/explorar';
  static String fichaLugar(String lugarId) => '/explorar/$lugarId';
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
                // crear va antes de :planId para que no se lea como un id
                routes: [
                  GoRoute(
                    path: 'crear',
                    builder: (context, state) => const CrearPlanScreen(),
                  ),
                  GoRoute(
                    path: ':planId',
                    builder: (context, state) => DetallePlanScreen(
                      planId: state.pathParameters['planId']!,
                    ),
                    // p05: preparar votacion o votar segun la fase del plan
                    routes: [
                      GoRoute(
                        path: 'votacion',
                        builder: (context, state) => VotacionScreen(
                          planId: state.pathParameters['planId']!,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Rutas.explorar,
                builder: (context, state) => const ExplorarScreen(),
                routes: [
                  GoRoute(
                    path: ':lugarId',
                    builder: (context, state) => FichaLugarScreen(
                      lugarId: state.pathParameters['lugarId']!,
                    ),
                  ),
                ],
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
