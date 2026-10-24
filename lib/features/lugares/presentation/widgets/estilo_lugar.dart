import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/utils/formato.dart';
import '../../data/lugar_model.dart';

// icono y colores de cada categoria; reemplazan la foto mientras el catalogo no tenga imagenes
extension EstiloCategoria on CategoriaLugar {
  IconData get icono => switch (this) {
    CategoriaLugar.restaurantes => Icons.restaurant,
    CategoriaLugar.cafesYPostres => Icons.local_cafe_outlined,
    CategoriaLugar.bares => Icons.local_bar_outlined,
    CategoriaLugar.entretenimientoYCultura => Icons.theater_comedy_outlined,
  };

  Color get colorFondo => switch (this) {
    CategoriaLugar.restaurantes => AppColors.coralSurface,
    CategoriaLugar.cafesYPostres => AppColors.amberSurface,
    CategoriaLugar.bares => AppColors.tealSurface,
    CategoriaLugar.entretenimientoYCultura => AppColors.surfaceContainerLow,
  };

  Color get colorIcono => switch (this) {
    CategoriaLugar.restaurantes => AppColors.secondary,
    CategoriaLugar.cafesYPostres => AppColors.tertiary,
    CategoriaLugar.bares => AppColors.primary,
    CategoriaLugar.entretenimientoYCultura => AppColors.inverseSurface,
  };
}

// textos compartidos por la tarjeta y la ficha; lo desconocido se dice como tal (rf04)
abstract final class TextosLugar {
  static const desconocido = 'Desconocido';
  static const precioOrientativo = 'Precio orientativo, puede variar.';

  static String precioPorPersona(double? precio) => precio == null
      ? 'Precio desconocido'
      : '${formatearSoles(precio)} / pers. (estimado)';

  static String horario(String? horario) => horario ?? 'Horario desconocido';
}

// etiqueta pequena de zona o categoria
class EtiquetaLugar extends StatelessWidget {
  const EtiquetaLugar({super.key, required this.texto, this.icono});

  final String texto;
  final IconData? icono;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icono != null) ...[
            Icon(icono, size: 14, color: AppColors.textSecondary),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(
            texto,
            style: Theme.of(context).textTheme.labelMedium
                ?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
