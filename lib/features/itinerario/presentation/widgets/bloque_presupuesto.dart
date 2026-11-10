import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/utils/formato.dart';
import '../../data/estimacion_presupuesto.dart';

// presupuesto por persona frente a la estimacion del itinerario (rb08, rf12)
class BloquePresupuesto extends StatelessWidget {
  const BloquePresupuesto({super.key, required this.estimacion});

  final EstimacionPresupuesto estimacion;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final e = estimacion;
    final colorTotal = e.excede ? AppColors.budgetExceeded : AppColors.primary;
    final sinPrecio = e.sinPrecio == 1
        ? '1 actividad no tiene'
        : '${e.sinPrecio} actividades no tienen';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _Monto(
                etiqueta: 'Presupuesto por persona',
                valor: formatearSoles(e.presupuestoSoles),
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _Monto(
                etiqueta: e.incompleta
                    ? 'Estimado por persona (incompleto)'
                    : 'Estimado por persona',
                valor: formatearSoles(e.totalEstimado),
                color: colorTotal,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.gutterSm),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.full),
          child: LinearProgressIndicator(
            value: e.uso,
            minHeight: 8,
            color: colorTotal,
            backgroundColor: AppColors.surfaceContainerHigh,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Solo actividades; el transporte va aparte.',
          style: textos.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
        if (e.incompleta) ...[
          const SizedBox(height: AppSpacing.gutterSm),
          _Aviso(
            icono: Icons.help_outline,
            fondo: AppColors.amberSurface,
            color: AppColors.tertiary,
            texto:
                'Estimación incompleta: $sinPrecio precio conocido '
                'y no suma al total.',
          ),
        ],
        if (e.excede) ...[
          const SizedBox(height: AppSpacing.gutterSm),
          _Aviso(
            icono: Icons.warning_amber_rounded,
            fondo: AppColors.budgetBadgeBg,
            color: AppColors.budgetExceeded,
            texto:
                'La estimación (${formatearSoles(e.totalEstimado)}) supera el '
                'presupuesto (${formatearSoles(e.presupuestoSoles)}) en '
                '${formatearSoles(e.exceso)} por persona. '
                'Un administrador puede confirmar igualmente.',
          ),
        ],
      ],
    );
  }
}

class _Monto extends StatelessWidget {
  const _Monto({
    required this.etiqueta,
    required this.valor,
    required this.color,
  });

  final String etiqueta;
  final String valor;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.gutterSm),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            etiqueta,
            style: textos.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(valor, style: textos.titleLarge?.copyWith(color: color)),
        ],
      ),
    );
  }
}

class _Aviso extends StatelessWidget {
  const _Aviso({
    required this.icono,
    required this.fondo,
    required this.color,
    required this.texto,
  });

  final IconData icono;
  final Color fondo;
  final Color color;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.gutterSm),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, size: 20, color: color),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(texto, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
