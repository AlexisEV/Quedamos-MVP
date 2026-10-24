import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../data/lugar_model.dart';
import 'estilo_lugar.dart';

// tarjeta del catalogo con precio orientativo, zona, categoria y horario (p03)
class TarjetaLugar extends StatelessWidget {
  const TarjetaLugar({super.key, required this.lugar, required this.onTap});

  final LugarModel lugar;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final categoria = lugar.categoria;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              color: categoria.colorFondo,
              padding: const EdgeInsets.all(AppSpacing.gutterSm),
              child: Row(
                children: [
                  Icon(categoria.icono, color: categoria.colorIcono, size: 28),
                  const SizedBox(width: AppSpacing.gutterSm),
                  Expanded(
                    child: Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.xs,
                      children: [
                        EtiquetaLugar(texto: lugar.zona.etiqueta),
                        EtiquetaLugar(texto: categoria.etiqueta),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(lugar.nombre, style: textos.titleMedium),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    TextosLugar.precioPorPersona(lugar.precioEstimadoPen),
                    style: textos.labelLarge?.copyWith(
                      color: lugar.precioEstimadoPen == null
                          ? AppColors.textMuted
                          : AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      const Icon(
                        Icons.schedule,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          TextosLugar.horario(lugar.horarioAtencion),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textos.bodySmall?.copyWith(
                            color: lugar.horarioAtencion == null
                                ? AppColors.textMuted
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        color: AppColors.textMuted,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
