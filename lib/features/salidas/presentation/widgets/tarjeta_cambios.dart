import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/utils/formato.dart';
import '../../../itinerario/data/cambio_plan_model.dart';
import '../detalle_plan_view_model.dart';

// historial de cambios del plan para todo el grupo (rf10); oculto si no hay cambios
class TarjetaCambios extends StatelessWidget {
  const TarjetaCambios({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DetallePlanViewModel>();
    final textos = Theme.of(context).textTheme;
    final cambios = vm.cambios;
    if (cambios.isEmpty) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.history, color: AppColors.primary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text('Cambios del plan', style: textos.titleLarge),
                ),
              ],
            ),
            for (final (i, cambio) in cambios.indexed) ...[
              const SizedBox(height: AppSpacing.gutterSm),
              if (i > 0) ...[
                const Divider(height: 1),
                const SizedBox(height: AppSpacing.gutterSm),
              ],
              _FilaCambio(cambio: cambio),
            ],
          ],
        ),
      ),
    );
  }
}

class _FilaCambio extends StatelessWidget {
  const _FilaCambio({required this.cambio});

  final CambioPlanModel cambio;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final (icono, color) = switch (cambio.tipo) {
      TipoCambio.reemplazo => (Icons.swap_horiz, AppColors.secondary),
      TipoCambio.horario => (Icons.schedule, AppColors.tertiary),
      TipoCambio.cancelacion => (Icons.event_busy_outlined, AppColors.error),
    };
    final autor = cambio.realizadoPor ?? 'Un administrador';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icono, size: 20, color: color),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(cambio.tipo.etiqueta, style: textos.titleSmall),
              if (_detalle() case final detalle?)
                Text(detalle, style: textos.bodyMedium),
              Text(
                '$autor · ${formatearFechaHoraLima(cambio.creadoEn)}',
                style: textos.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String? _detalle() {
    const desconocido = 'Lugar no disponible';
    switch (cambio.tipo) {
      case TipoCambio.reemplazo:
        return '${cambio.lugarAnterior ?? desconocido} → '
            '${cambio.lugarNuevo ?? desconocido}';
      case TipoCambio.horario:
        final anterior = cambio.inicioAnterior;
        final nuevo = cambio.inicioNuevo;
        final lugar = cambio.lugarNuevo ?? desconocido;
        return '$lugar: '
            '${anterior == null ? 'Sin fecha/hora' : formatearFechaHoraLima(anterior)}'
            ' → '
            '${nuevo == null ? 'Sin fecha/hora' : formatearFechaHoraLima(nuevo)}';
      case TipoCambio.cancelacion:
        return null;
    }
  }
}
