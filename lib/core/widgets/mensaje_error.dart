import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';

// recuadro con el error devuelto por el servidor dentro de un formulario
class MensajeError extends StatelessWidget {
  const MensajeError({super.key, required this.mensaje});

  final String mensaje;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.gutterSm),
        decoration: BoxDecoration(
          color: AppColors.errorContainer,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.error_outline,
              size: 20,
              color: AppColors.onErrorContainer,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                mensaje,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: AppColors.onErrorContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
