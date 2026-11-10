import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../features/notificaciones/presentation/notificaciones_view_model.dart';

// contenedor de las 4 pestanas con la barra inferior
class ShellScreen extends StatelessWidget {
  const ShellScreen({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _irARama(int indice) {
    // tocar la pestana activa vuelve a su ruta inicial
    navigationShell.goBranch(
      indice,
      initialLocation: indice == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final nuevas = context.select<NotificacionesViewModel?, int>(
      (vm) => vm?.noLeidas ?? 0,
    );
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _irARama,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups),
            label: 'Mis salidas',
          ),
          const NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: 'Explorar',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: nuevas > 0,
              label: Text('$nuevas'),
              child: const Icon(Icons.notifications_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: nuevas > 0,
              label: Text('$nuevas'),
              child: const Icon(Icons.notifications),
            ),
            label: 'Avisos',
          ),
          const NavigationDestination(
            icon: Icon(Icons.account_circle_outlined),
            selectedIcon: Icon(Icons.account_circle),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
