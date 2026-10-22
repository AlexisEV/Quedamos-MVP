import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../data/plan_model.dart';

// bloque de color con nombre, fase y rol; reemplaza la foto del mockup
class CabeceraPlan extends StatelessWidget {
  const CabeceraPlan({
    super.key,
    required this.salida,
    this.estiloNombre,
    this.radio = const BorderRadius.vertical(
      top: Radius.circular(AppRadius.lg),
    ),
  });

  final SalidaModel salida;
  final TextStyle? estiloNombre;
  final BorderRadius radio;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final cancelado = salida.plan.estado == EstadoPlan.cancelado;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: radio,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: cancelado
              ? const [AppColors.textSecondary, AppColors.textMuted]
              : const [AppColors.primary, AppColors.tealLight],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ChipEstadoPlan(estado: salida.plan.estado),
              const Spacer(),
              _ChipRol(salida: salida),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            salida.plan.nombre,
            style: (estiloNombre ?? textos.titleLarge)?.copyWith(
              color: AppColors.onPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class ChipEstadoPlan extends StatelessWidget {
  const ChipEstadoPlan({super.key, required this.estado});

  final EstadoPlan estado;

  Color get _color => switch (estado) {
    EstadoPlan.recibiendoPropuestas => AppColors.secondary,
    EstadoPlan.enVotacion => AppColors.coral,
    EstadoPlan.preparandoItinerario => AppColors.amber,
    EstadoPlan.confirmado => AppColors.primary,
    EstadoPlan.cancelado => AppColors.error,
  };

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
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: _color, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            estado.etiqueta,
            style: Theme.of(context).textTheme.labelMedium
                ?.copyWith(color: _color),
          ),
        ],
      ),
    );
  }
}

class _ChipRol extends StatelessWidget {
  const _ChipRol({required this.salida});

  final SalidaModel salida;

  @override
  Widget build(BuildContext context) {
    final admin = salida.esAdministrador;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: admin ? AppColors.tealDark : AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            admin ? Icons.verified_outlined : Icons.person_outline,
            size: 14,
            color: admin ? AppColors.onPrimary : AppColors.primary,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            salida.miRol.etiqueta,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: admin ? AppColors.onPrimary : AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
