import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/utils/formato.dart';
import '../../../lugares/presentation/widgets/estilo_lugar.dart';
import '../../../votacion/data/candidato_model.dart';
import '../../data/plan_model.dart';
import '../detalle_plan_view_model.dart';

// lista final fija desde que se abre la votacion (rb07, p05)
class TarjetaCandidatos extends StatelessWidget {
  const TarjetaCandidatos({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DetallePlanViewModel>();
    final textos = Theme.of(context).textTheme;
    final plan = vm.salida?.plan;
    if (plan == null) return const SizedBox.shrink();
    final candidatos = vm.candidatos;
    final plazo = plan.fechaLimiteVoto;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.checklist, color: AppColors.primary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Candidatos (${candidatos.length})',
                    style: textos.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Lista final fija: no se añaden, retiran ni reemplazan '
              'candidatos.',
              style: textos.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
            if (plan.estado == EstadoPlan.enVotacion) ...[
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  const Icon(
                    Icons.timer_outlined,
                    size: 20,
                    color: AppColors.secondary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      plazo == null
                          ? 'Sin plazo para votar'
                          : 'Plazo para votar: ${formatearFechaHoraLima(plazo)}',
                      style: textos.bodyMedium,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            for (final candidato in candidatos) _FilaCandidato(candidato),
          ],
        ),
      ),
    );
  }
}

class _FilaCandidato extends StatelessWidget {
  const _FilaCandidato(this.candidato);

  final CandidatoModel candidato;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final categoria = candidato.categoria;
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
                  candidato.nombreLugar ?? 'Lugar no disponible',
                  style: textos.titleSmall?.copyWith(
                    color: candidato.nombreLugar == null
                        ? AppColors.textMuted
                        : null,
                  ),
                ),
                Text(
                  [
                    if (categoria != null) categoria.etiqueta,
                    TextosLugar.precioPorPersona(candidato.precioEstimadoPen),
                  ].join(' · '),
                  style: textos.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
