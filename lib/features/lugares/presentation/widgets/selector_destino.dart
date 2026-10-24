import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../app/router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/utils/formato.dart';
import '../../../../core/widgets/estado_vacio.dart';
import '../../data/propuesta_model.dart';
import '../../data/propuestas_repository.dart';
import '../destino_propuesta.dart';

// hoja para elegir el plan destino entre las salidas que reciben propuestas.
// con el id de un lugar marca los planes donde ese lugar ya fue propuesto
Future<DestinoPlan?> elegirDestino(BuildContext context, {String? lugarId}) {
  final repositorio = context.read<PropuestasRepository>();
  final planActual = context.read<DestinoPropuesta>().planId;
  return showModalBottomSheet<DestinoPlan>(
    context: context,
    // sobre el navegador raiz para que la barra de pestanas no la tape
    useRootNavigator: true,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => _HojaDestinos(
      repositorio: repositorio,
      planActual: planActual,
      lugarId: lugarId,
      alIrASalidas: () => context.go(Rutas.salidas),
    ),
  );
}

class _HojaDestinos extends StatefulWidget {
  const _HojaDestinos({
    required this.repositorio,
    required this.planActual,
    required this.lugarId,
    required this.alIrASalidas,
  });

  final PropuestasRepository repositorio;
  final String? planActual;
  final String? lugarId;
  final VoidCallback alIrASalidas;

  @override
  State<_HojaDestinos> createState() => _HojaDestinosState();
}

class _HojaDestinosState extends State<_HojaDestinos> {
  late Future<List<DestinoPlan>> _destinos = widget.repositorio
      .obtenerDestinos();

  void _reintentar() {
    setState(() => _destinos = widget.repositorio.obtenerDestinos());
  }

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.8,
        ),
        child: FutureBuilder<List<DestinoPlan>>(
          future: _destinos,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Padding(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError) {
              final error = snapshot.error;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  EstadoVacio(
                    icono: Icons.cloud_off_outlined,
                    titulo: 'No se pudieron cargar tus salidas',
                    mensaje: error is AppException
                        ? error.mensaje
                        : MensajesError.generico,
                  ),
                  OutlinedButton(
                    onPressed: _reintentar,
                    child: const Text('Reintentar'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
              );
            }
            final destinos = snapshot.data ?? const [];
            if (destinos.isEmpty) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const EstadoVacio(
                    icono: Icons.event_busy_outlined,
                    titulo: 'No tienes salidas recibiendo propuestas',
                    mensaje:
                        'Crea una salida o únete a una para proponer lugares.',
                  ),
                  FilledButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      widget.alIrASalidas();
                    },
                    child: const Text('Ir a Mis salidas'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
              );
            }
            return ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.md,
              ),
              children: [
                Text('Elegir plan de destino', style: textos.titleLarge),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Solo se muestran las salidas que reciben propuestas.',
                  style: textos.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                for (final destino in destinos)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.gutterSm),
                    child: _TarjetaDestino(
                      destino: destino,
                      elegido: destino.plan.id == widget.planActual,
                      yaPropuesto:
                          widget.lugarId != null &&
                          destino.yaPropuesto(widget.lugarId!),
                      onTap: () => Navigator.of(context).pop(destino),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TarjetaDestino extends StatelessWidget {
  const _TarjetaDestino({
    required this.destino,
    required this.elegido,
    required this.yaPropuesto,
    required this.onTap,
  });

  final DestinoPlan destino;
  final bool elegido;
  final bool yaPropuesto;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final plan = destino.plan;
    final secundario = textos.bodySmall?.copyWith(
      color: AppColors.textSecondary,
    );
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(
          color: elegido ? AppColors.primary : AppColors.borderSubtle,
          width: elegido ? 2 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(plan.nombre, style: textos.titleMedium),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${destino.salida.miRol.etiqueta} · '
                      '${formatearSoles(plan.presupuestoSoles)} / pers.',
                      style: secundario,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Tus propuestas ${destino.misPropuestas}/'
                      '${destino.maxPropuestas}',
                      style: secundario,
                    ),
                    if (yaPropuesto || destino.limiteAlcanzado) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        yaPropuesto
                            ? 'Ya propuesto en este plan'
                            : 'Llegaste a tu límite en este plan',
                        style: textos.labelMedium?.copyWith(
                          color: AppColors.tertiary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                elegido ? Icons.check_circle : Icons.radio_button_unchecked,
                color: elegido ? AppColors.primary : AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
