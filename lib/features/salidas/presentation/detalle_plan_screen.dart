import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/utils/formato.dart';
import '../../../core/widgets/estado_vacio.dart';
import '../data/plan_model.dart';
import '../data/salidas_repository.dart';
import 'detalle_plan_view_model.dart';
import 'widgets/cabecera_plan.dart';

// detalle de la salida: fase, rol, presupuesto, codigo y limites
class DetallePlanScreen extends StatelessWidget {
  const DetallePlanScreen({super.key, required this.planId});

  final String planId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) =>
          DetallePlanViewModel(context.read<SalidasRepository>(), planId)
            ..cargar(),
      child: const _DetalleVista(),
    );
  }
}

class _DetalleVista extends StatelessWidget {
  const _DetalleVista();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DetallePlanViewModel>();
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de salida')),
      body: _cuerpo(context, vm),
    );
  }

  Widget _cuerpo(BuildContext context, DetallePlanViewModel vm) {
    final salida = vm.salida;
    if (salida != null) {
      return RefreshIndicator(
        onRefresh: vm.cargar,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.margin),
          children: [
            _TarjetaResumen(salida: salida),
            const SizedBox(height: AppSpacing.md),
            _TarjetaLimites(plan: salida.plan),
          ],
        ),
      );
    }
    if (vm.noEncontrado) {
      return const EstadoVacio(
        icono: Icons.search_off,
        titulo: 'No encontramos esta salida',
        mensaje: 'Puede que no exista o que no participes en ella.',
      );
    }
    if (vm.error != null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          EstadoVacio(
            icono: Icons.cloud_off_outlined,
            titulo: 'No se pudo cargar la salida',
            mensaje: vm.error,
          ),
          OutlinedButton(onPressed: vm.cargar, child: const Text('Reintentar')),
        ],
      );
    }
    return const Center(child: CircularProgressIndicator());
  }
}

class _TarjetaResumen extends StatelessWidget {
  const _TarjetaResumen({required this.salida});

  final SalidaModel salida;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final plan = salida.plan;
    final total = salida.totalParticipantes;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CabeceraPlan(salida: salida, estiloNombre: textos.headlineSmall),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Dato(
                  icono: Icons.payments_outlined,
                  texto: 'Presupuesto por persona: ',
                  valor: formatearSoles(plan.presupuestoSoles),
                ),
                const SizedBox(height: AppSpacing.sm),
                _Dato(
                  icono: Icons.group_outlined,
                  texto: total == 1 ? '1 participante' : '$total participantes',
                ),
                const SizedBox(height: AppSpacing.md),
                _BloqueCodigo(plan: plan),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato({required this.icono, required this.texto, this.valor});

  final IconData icono;
  final String texto;
  final String? valor;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return Row(
      children: [
        Icon(icono, size: 20, color: AppColors.primary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text.rich(
            TextSpan(
              text: texto,
              style: textos.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
              children: [
                if (valor != null)
                  TextSpan(
                    text: valor,
                    style: textos.titleMedium?.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _BloqueCodigo extends StatelessWidget {
  const _BloqueCodigo({required this.plan});

  final PlanModel plan;

  Future<void> _copiar(BuildContext context) async {
    final mensajes = ScaffoldMessenger.of(context);
    await Clipboard.setData(ClipboardData(text: plan.codigoInvitacion));
    mensajes.showSnackBar(const SnackBar(content: Text('Código copiado.')));
  }

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    // el codigo queda inactivo cuando el plan se cancela
    final activo = plan.estado != EstadoPlan.cancelado;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CÓDIGO DE SALIDA',
                      style: textos.labelSmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    // el codigo siempre en una linea; se reduce si no cabe
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: SelectableText(
                        plan.codigoInvitacion,
                        maxLines: 1,
                        style: textos.headlineMedium?.copyWith(
                          letterSpacing: 4,
                          color: activo
                              ? AppColors.textPrimary
                              : AppColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (activo)
                FilledButton.icon(
                  onPressed: () => _copiar(context),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 44),
                    backgroundColor: AppColors.surfaceWhite,
                    foregroundColor: AppColors.primary,
                  ),
                  icon: const Icon(Icons.copy, size: 18),
                  label: const Text('Copiar código'),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            activo
                ? 'Comparte este código para que tus amigos se unan.'
                : 'Código inactivo: la salida fue cancelada.',
            style: textos.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _TarjetaLimites extends StatelessWidget {
  const _TarjetaLimites({required this.plan});

  final PlanModel plan;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final filas = [
      ('Lugares propuestos por persona', plan.maxPropuestasPorPersona),
      ('Candidatos en la votación', plan.maxCandidatos),
      ('Selecciones por persona', plan.maxSelecciones),
      ('Actividades del itinerario', plan.maxActividades),
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.tune, color: AppColors.primary),
                const SizedBox(width: AppSpacing.sm),
                Text('Límites del plan', style: textos.titleLarge),
              ],
            ),
            for (final (etiqueta, valor) in filas)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.gutterSm),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        etiqueta,
                        style: textos.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    Text('$valor', style: textos.titleMedium),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
