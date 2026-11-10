import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/utils/formato.dart';
import '../../../lugares/presentation/widgets/estilo_lugar.dart';
import '../../data/actividad_model.dart';

// posicion, lugar, hora de la actividad, horario de atencion y precio (rf09, rf12)
class DatosActividad extends StatelessWidget {
  const DatosActividad({
    super.key,
    required this.actividad,
    required this.numero,
  });

  final ActividadModel actividad;
  // posicion visible; durante la edicion puede diferir de la guardada
  final int numero;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final categoria = actividad.categoria;
    final inicio = actividad.inicio;
    final precio = actividad.precioEstimadoPen;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: AppColors.primary,
          child: Text(
            '$numero',
            style: textos.labelLarge?.copyWith(color: AppColors.onPrimary),
          ),
        ),
        const SizedBox(width: AppSpacing.gutterSm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (categoria != null) ...[
                    Icon(
                      categoria.icono,
                      size: 18,
                      color: categoria.colorIcono,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                  ],
                  Expanded(
                    child: Text(
                      actividad.nombreLugar ?? 'Lugar no disponible',
                      style: textos.titleMedium,
                    ),
                  ),
                ],
              ),
              if (inicio != null)
                _Linea(
                  icono: Icons.schedule,
                  texto: 'Actividad: ${formatearFechaHoraLima(inicio)}',
                  color: AppColors.primary,
                )
              else
                const _Linea(
                  icono: Icons.event_busy_outlined,
                  texto: 'Sin fecha/hora',
                  color: AppColors.tertiary,
                ),
              _Linea(
                icono: Icons.storefront_outlined,
                texto:
                    'Atención del local: '
                    '${actividad.horarioAtencion ?? TextosLugar.desconocido}',
              ),
              _Linea(
                icono: Icons.payments_outlined,
                texto: precio == null
                    ? 'Precio desconocido'
                    : 'Estimado por persona: ${formatearSoles(precio)}',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Linea extends StatelessWidget {
  const _Linea({required this.icono, required this.texto, this.color});

  final IconData icono;
  final String texto;
  // un color resalta la hora de la actividad frente a los datos del lugar
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final tono = color ?? AppColors.textSecondary;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, size: 16, color: tono),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              texto,
              style: textos.bodySmall?.copyWith(
                color: tono,
                fontWeight: color == null ? null : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
