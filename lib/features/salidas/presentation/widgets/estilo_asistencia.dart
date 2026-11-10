import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../data/participante_model.dart';

// colores e iconos de cada respuesta de asistencia, compartidos por las tarjetas
extension EstiloAsistencia on EstadoAsistencia {
  Color get color => switch (this) {
    EstadoAsistencia.asistire => AppColors.primary,
    EstadoAsistencia.pendiente => AppColors.tertiary,
    EstadoAsistencia.noAsistire => AppColors.budgetExceeded,
  };

  Color get fondo => switch (this) {
    EstadoAsistencia.asistire => AppColors.tealSurface,
    EstadoAsistencia.pendiente => AppColors.amberSurface,
    EstadoAsistencia.noAsistire => AppColors.budgetBadgeBg,
  };

  // tono de la barra del grupo
  Color get colorBarra => switch (this) {
    EstadoAsistencia.asistire => AppColors.tealLight,
    EstadoAsistencia.pendiente => AppColors.amber,
    EstadoAsistencia.noAsistire => AppColors.budgetExceeded,
  };

  IconData get icono => switch (this) {
    EstadoAsistencia.asistire => Icons.check_circle_outline,
    EstadoAsistencia.pendiente => Icons.schedule,
    EstadoAsistencia.noAsistire => Icons.cancel_outlined,
  };
}

// chip con la respuesta de un integrante en la lista del grupo
class ChipAsistencia extends StatelessWidget {
  const ChipAsistencia({super.key, required this.estado});

  final EstadoAsistencia estado;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: estado.fondo,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(estado.icono, size: 14, color: estado.color),
          const SizedBox(width: AppSpacing.xs),
          Text(
            estado.etiqueta,
            style: Theme.of(context).textTheme.labelMedium
                ?.copyWith(color: estado.color),
          ),
        ],
      ),
    );
  }
}
