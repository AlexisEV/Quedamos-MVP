import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/widgets/estado_vacio.dart';
import '../data/lugar_model.dart';
import '../data/lugares_repository.dart';
import 'destino_propuesta.dart';
import 'explorar_view_model.dart';
import 'widgets/selector_destino.dart';
import 'widgets/tarjeta_lugar.dart';

// pestana explorar: catalogo de lugares de arequipa (p03)
class ExplorarScreen extends StatelessWidget {
  const ExplorarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) =>
          ExplorarViewModel(context.read<LugaresRepository>())..cargar(),
      child: const _ExplorarVista(),
    );
  }
}

class _ExplorarVista extends StatelessWidget {
  const _ExplorarVista();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ExplorarViewModel>();
    final textos = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: vm.cargar,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.margin),
            children: [
              Text('Explorar lugares', style: textos.headlineMedium),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Lugares de Arequipa con ubicación, horario y precio orientativo.',
                style: textos.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const _AvisoDestino(),
              ..._contenido(context, vm),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _contenido(BuildContext context, ExplorarViewModel vm) {
    if (vm.cargandoPrimeraVez) {
      return const [
        Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }
    if (vm.error != null && vm.lugares.isEmpty) {
      return [
        EstadoVacio(
          icono: Icons.cloud_off_outlined,
          titulo: 'No se pudieron cargar los lugares',
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
          icono: Icons.explore_outlined,
          titulo: 'Aún no hay lugares en el catálogo',
          mensaje: 'Pronto podrás consultar lugares de Arequipa aquí.',
        ),
      ];
    }
    return [for (final lugar in vm.lugares) _tarjeta(context, lugar)];
  }

  Widget _tarjeta(BuildContext context, LugarModel lugar) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: TarjetaLugar(
        lugar: lugar,
        onTap: () => context.push(Rutas.fichaLugar(lugar.id)),
      ),
    );
  }
}

// plan al que se envian las propuestas desde la ficha, si ya se eligio
class _AvisoDestino extends StatelessWidget {
  const _AvisoDestino();

  Future<void> _cambiar(BuildContext context) async {
    final destino = context.read<DestinoPropuesta>();
    final elegido = await elegirDestino(context);
    if (elegido != null) destino.fijar(elegido.plan);
  }

  @override
  Widget build(BuildContext context) {
    final destino = context.watch<DestinoPropuesta>();
    if (!destino.hayDestino) return const SizedBox.shrink();
    final textos = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.sm,
          AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.tealSurface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Row(
          children: [
            const Icon(Icons.event_note_outlined, color: AppColors.primary),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Proponer para',
                    style: textos.labelMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    destino.nombrePlan ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textos.titleMedium,
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => _cambiar(context),
              child: const Text('Cambiar'),
            ),
          ],
        ),
      ),
    );
  }
}
