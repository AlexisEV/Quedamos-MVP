import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../itinerario/presentation/widgets/bloque_presupuesto.dart';
import '../../../itinerario/presentation/widgets/datos_actividad.dart';
import '../../data/plan_model.dart';
import '../detalle_plan_view_model.dart';

// itinerario de solo lectura para todo el grupo con su estimacion (rf12, p08)
class TarjetaItinerario extends StatelessWidget {
  const TarjetaItinerario({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DetallePlanViewModel>();
    final textos = Theme.of(context).textTheme;
    final confirmado = vm.salida?.plan.estado == EstadoPlan.confirmado;
    final actividades = vm.actividades;
    final estimacion = vm.estimacion;
    final sinHorario = actividades.where((a) => a.inicio == null).length;
    final String estado;
    if (confirmado) {
      estado = 'Itinerario confirmado.';
    } else if (vm.itinerarioBloqueadoPorEmpate) {
      estado = 'Por confirmar: falta resolver el empate del último puesto.';
    } else {
      estado =
          'Por confirmar: los administradores definen el orden y la fecha y '
          'hora de cada actividad.';
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.route_outlined, color: AppColors.primary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Text('Itinerario', style: textos.titleLarge)),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              estado,
              style: textos.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
            if (actividades.isEmpty) ...[
              const SizedBox(height: AppSpacing.gutterSm),
              Text(
                'Todavía no hay actividades en el itinerario.',
                style: textos.bodyMedium,
              ),
            ],
            if (!confirmado && sinHorario > 0) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                sinHorario == 1
                    ? '1 actividad sin fecha/hora.'
                    : '$sinHorario actividades sin fecha/hora.',
                style: textos.bodySmall?.copyWith(color: AppColors.tertiary),
              ),
            ],
            for (final (i, actividad) in actividades.indexed) ...[
              const SizedBox(height: AppSpacing.gutterSm),
              if (i > 0) ...[
                const Divider(height: 1),
                const SizedBox(height: AppSpacing.gutterSm),
              ],
              DatosActividad(actividad: actividad, numero: i + 1),
            ],
            if (estimacion != null && actividades.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              BloquePresupuesto(estimacion: estimacion),
            ],
          ],
        ),
      ),
    );
  }
}
