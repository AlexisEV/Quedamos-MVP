import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../app/router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/mensaje_error.dart';
import '../../../lugares/data/propuesta_model.dart';
import '../../../lugares/presentation/destino_propuesta.dart';
import '../../../lugares/presentation/widgets/estilo_lugar.dart';
import '../detalle_plan_view_model.dart';

// propuestas del plan para revisarlas antes de definir candidatos (rf05, p05)
class TarjetaPropuestas extends StatelessWidget {
  const TarjetaPropuestas({super.key});

  // fija este plan como destino y abre explorar para elegir lugares
  void _proponerLugares(BuildContext context) {
    final salida = context.read<DetallePlanViewModel>().salida;
    if (salida == null) return;
    context.read<DestinoPropuesta>().fijar(salida.plan);
    context.go(Rutas.explorar);
  }

  Future<void> _retirar(BuildContext context, PropuestaModel propuesta) async {
    final vm = context.read<DetallePlanViewModel>();
    final mensajes = ScaffoldMessenger.of(context);
    final nombre = propuesta.nombreLugar ?? 'este lugar';
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Retirar propuesta'),
        content: Text(
          'Se quitará $nombre de las propuestas de la salida '
          'y se liberará el cupo de quien lo propuso.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Retirar'),
          ),
        ],
      ),
    );
    if (confirmado != true) return;
    final retirada = await vm.retirarPropuesta(propuesta);
    if (retirada) {
      mensajes.showSnackBar(
        const SnackBar(content: Text('Propuesta retirada.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DetallePlanViewModel>();
    final textos = Theme.of(context).textTheme;
    final plan = vm.salida?.plan;
    if (plan == null) return const SizedBox.shrink();
    final propuestas = vm.propuestas;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.place_outlined, color: AppColors.primary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Propuestas (${propuestas.length})',
                    style: textos.titleLarge,
                  ),
                ),
                if (vm.recibePropuestas)
                  Text(
                    'Tus propuestas ${vm.misPropuestas}/'
                    '${plan.maxPropuestasPorPersona}',
                    style: textos.labelMedium?.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            if (propuestas.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Text(
                  vm.recibePropuestas
                      ? 'Aún no hay propuestas. Elige lugares en Explorar.'
                      : 'No se registraron propuestas.',
                  style: textos.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            for (final propuesta in propuestas)
              _FilaPropuesta(
                propuesta: propuesta,
                esPropia: propuesta.propuestoPor == vm.usuarioActualId,
                retirando: vm.retirando == propuesta.id,
                onRetirar: vm.puedeRetirar(propuesta) && vm.retirando == null
                    ? () => _retirar(context, propuesta)
                    : null,
                mostrarRetirar: vm.puedeRetirar(propuesta),
              ),
            if (vm.errorPropuestas != null) ...[
              const SizedBox(height: AppSpacing.sm),
              MensajeError(mensaje: vm.errorPropuestas!),
            ],
            if (vm.recibePropuestas) ...[
              const SizedBox(height: AppSpacing.gutterSm),
              FilledButton.tonalIcon(
                onPressed: () => _proponerLugares(context),
                icon: const Icon(Icons.add_location_alt_outlined),
                label: const Text('Proponer lugares'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FilaPropuesta extends StatelessWidget {
  const _FilaPropuesta({
    required this.propuesta,
    required this.esPropia,
    required this.retirando,
    required this.onRetirar,
    required this.mostrarRetirar,
  });

  final PropuestaModel propuesta;
  final bool esPropia;
  final bool retirando;
  final VoidCallback? onRetirar;
  final bool mostrarRetirar;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final categoria = propuesta.categoria;
    final autor = esPropia ? 'ti' : propuesta.nombreAutor;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor:
                categoria?.colorFondo ?? AppColors.surfaceContainer,
            child: Icon(
              categoria?.icono ?? Icons.place_outlined,
              size: 18,
              color: categoria?.colorIcono ?? AppColors.textMuted,
            ),
          ),
          const SizedBox(width: AppSpacing.gutterSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  // el lugar pudo dejar de publicarse despues de proponerse
                  propuesta.nombreLugar ?? 'Lugar no disponible',
                  style: textos.titleSmall?.copyWith(
                    color: propuesta.nombreLugar == null
                        ? AppColors.textMuted
                        : null,
                  ),
                ),
                Text(
                  [
                    if (categoria != null) categoria.etiqueta,
                    'Propuesto por $autor',
                  ].join(' · '),
                  style: textos.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (retirando)
            const Padding(
              padding: EdgeInsets.all(AppSpacing.gutterSm),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (mostrarRetirar)
            IconButton(
              tooltip: 'Retirar propuesta',
              onPressed: onRetirar,
              icon: const Icon(Icons.cancel_outlined),
              color: AppColors.error,
            ),
        ],
      ),
    );
  }
}
