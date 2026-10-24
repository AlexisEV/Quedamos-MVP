import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/mensaje_error.dart';
import '../../data/propuesta_model.dart';
import '../proponer_view_model.dart';
import 'selector_destino.dart';

// barra inferior de la ficha para proponer el lugar al plan destino (p04)
class BarraProponer extends StatelessWidget {
  const BarraProponer({super.key});

  // sin destino primero se elige el plan y luego se propone en el mismo paso
  Future<void> _proponerEligiendo(BuildContext context) async {
    final vm = context.read<ProponerViewModel>();
    final elegido = await elegirDestino(context, lugarId: vm.lugarId);
    if (elegido == null || !context.mounted) return;
    await _proponer(context, elegido);
  }

  Future<void> _cambiarDestino(BuildContext context) async {
    final vm = context.read<ProponerViewModel>();
    final elegido = await elegirDestino(context, lugarId: vm.lugarId);
    if (elegido != null) vm.elegir(elegido);
  }

  Future<void> _proponer(BuildContext context, DestinoPlan destino) async {
    final vm = context.read<ProponerViewModel>();
    final mensajes = ScaffoldMessenger.of(context);
    final guardado = await vm.proponer(destino);
    if (guardado) {
      mensajes.showSnackBar(
        SnackBar(content: Text('Propuesto en ${destino.plan.nombre}.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProponerViewModel>();
    final textos = Theme.of(context).textTheme;
    final destino = vm.destinoActual;
    return Material(
      color: AppColors.surfaceWhite,
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (vm.errorEnvio != null) ...[
                MensajeError(mensaje: vm.errorEnvio!),
                const SizedBox(height: AppSpacing.gutterSm),
              ],
              if (destino != null)
                Row(
                  children: [
                    const Icon(
                      Icons.event_note_outlined,
                      size: 20,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Proponer para: ${destino.plan.nombre}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textos.bodyMedium,
                      ),
                    ),
                    TextButton(
                      onPressed: vm.enviando
                          ? null
                          : () => _cambiarDestino(context),
                      child: const Text('Cambiar plan'),
                    ),
                  ],
                ),
              _boton(context, vm, destino),
            ],
          ),
        ),
      ),
    );
  }

  Widget _boton(
    BuildContext context,
    ProponerViewModel vm,
    DestinoPlan? destino,
  ) {
    if (vm.cargandoPrimeraVez) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.sm),
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (vm.error != null) {
      return OutlinedButton.icon(
        onPressed: vm.cargar,
        icon: const Icon(Icons.refresh),
        label: const Text('No se pudieron cargar tus salidas. Reintentar'),
      );
    }
    if (destino == null) {
      return FilledButton.icon(
        onPressed: vm.enviando ? null : () => _proponerEligiendo(context),
        icon: const Icon(Icons.add_circle_outline),
        label: const Text('Proponer al grupo'),
      );
    }
    if (destino.yaPropuesto(vm.lugarId)) {
      return FilledButton.icon(
        onPressed: null,
        icon: const Icon(Icons.check_circle_outline),
        label: const Text('Ya propuesto en este plan'),
      );
    }
    if (destino.limiteAlcanzado) {
      return FilledButton(
        onPressed: null,
        child: Text(
          'Llegaste a tu límite de ${destino.maxPropuestas} '
          'propuestas en este plan',
          textAlign: TextAlign.center,
        ),
      );
    }
    return FilledButton.icon(
      onPressed: vm.enviando ? null : () => _proponer(context, destino),
      icon: vm.enviando
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.add_circle_outline),
      label: Text(
        'Proponer a ${destino.plan.nombre}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
