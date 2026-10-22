import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/widgets/estado_vacio.dart';
import '../data/plan_model.dart';
import '../data/salidas_repository.dart';
import 'mis_salidas_view_model.dart';
import 'widgets/tarjeta_salida.dart';

// pestana mis salidas: acceso a crear plan y lista de planes del usuario
class MisSalidasScreen extends StatelessWidget {
  const MisSalidasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) =>
          MisSalidasViewModel(context.read<SalidasRepository>())..cargar(),
      child: const _MisSalidasVista(),
    );
  }
}

class _MisSalidasVista extends StatelessWidget {
  const _MisSalidasVista();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MisSalidasViewModel>();
    final textos = Theme.of(context).textTheme;
    final activas = vm.activas;
    final canceladas = vm.canceladas;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: vm.cargar,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.margin),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('Mis salidas', style: textos.headlineMedium),
                  ),
                  if (activas.isNotEmpty) _ChipActivas(total: activas.length),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Organiza y participa en planes grupales en Arequipa.',
                style: textos.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _BotonCrear(onTap: () => context.push(Rutas.crearPlan)),
              const SizedBox(height: AppSpacing.lg),
              ..._contenido(context, vm, activas, canceladas),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _contenido(
    BuildContext context,
    MisSalidasViewModel vm,
    List<SalidaModel> activas,
    List<SalidaModel> canceladas,
  ) {
    if (vm.cargandoPrimeraVez) {
      return const [
        Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }
    if (vm.error != null && activas.isEmpty && canceladas.isEmpty) {
      return [
        EstadoVacio(
          icono: Icons.cloud_off_outlined,
          titulo: 'No se pudieron cargar tus salidas',
          mensaje: vm.error,
        ),
        Center(
          child: OutlinedButton(
            onPressed: vm.cargar,
            child: const Text('Reintentar'),
          ),
        ),
      ];
    }
    if (vm.vacio) {
      return const [
        EstadoVacio(
          icono: Icons.groups_outlined,
          titulo: 'Aún no tienes salidas',
          mensaje: 'Crea una salida y comparte su código con tus amigos.',
        ),
      ];
    }
    return [
      if (activas.isNotEmpty) ...[
        const _TituloSeccion(
          icono: Icons.event_available_outlined,
          texto: 'Planes activos',
        ),
        for (final salida in activas) _tarjeta(context, salida),
      ],
      if (canceladas.isNotEmpty) ...[
        const _TituloSeccion(
          icono: Icons.event_busy_outlined,
          texto: 'Cancelados',
        ),
        for (final salida in canceladas) _tarjeta(context, salida),
      ],
    ];
  }

  Widget _tarjeta(BuildContext context, SalidaModel salida) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: TarjetaSalida(
        salida: salida,
        onTap: () => context.push(Rutas.detallePlan(salida.plan.id)),
      ),
    );
  }
}

class _ChipActivas extends StatelessWidget {
  const _ChipActivas({required this.total});

  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.tealSurface,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        total == 1 ? '1 activa' : '$total activas',
        style: Theme.of(context).textTheme.labelMedium
            ?.copyWith(color: AppColors.primary),
      ),
    );
  }
}

class _BotonCrear extends StatelessWidget {
  const _BotonCrear({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return Material(
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              const Icon(
                Icons.add_circle_outline,
                color: AppColors.onPrimary,
                size: 32,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Crear nueva salida',
                      style: textos.titleMedium?.copyWith(
                        color: AppColors.onPrimary,
                      ),
                    ),
                    Text(
                      'Organiza una salida grupal',
                      style: textos.bodySmall?.copyWith(
                        color: AppColors.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward, color: AppColors.onPrimary),
            ],
          ),
        ),
      ),
    );
  }
}

class _TituloSeccion extends StatelessWidget {
  const _TituloSeccion({required this.icono, required this.texto});

  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.gutterSm),
      child: Row(
        children: [
          Icon(icono, size: 20, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Text(texto, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}
