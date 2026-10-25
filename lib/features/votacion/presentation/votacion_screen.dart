import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/utils/formato.dart';
import '../../../core/widgets/estado_vacio.dart';
import '../../../core/widgets/mensaje_error.dart';
import '../../lugares/presentation/widgets/estilo_lugar.dart';
import '../../salidas/data/plan_model.dart';
import '../../salidas/data/salidas_repository.dart';
import '../data/candidato_model.dart';
import '../data/votacion_repository.dart';
import 'preparar_votacion_screen.dart';
import 'votar_view_model.dart';

// p05 en una sola ruta: preparar votacion mientras se reciben propuestas y votar despues
class VotacionScreen extends StatelessWidget {
  const VotacionScreen({super.key, required this.planId});

  final String planId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => VotarViewModel(
        context.read<SalidasRepository>(),
        context.read<VotacionRepository>(),
        planId,
      )..cargar(),
      child: _VotacionVista(planId: planId),
    );
  }
}

class _VotacionVista extends StatelessWidget {
  const _VotacionVista({required this.planId});

  final String planId;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<VotarViewModel>();
    if (vm.enPreparacion) return PrepararVotacionScreen(planId: planId);
    final listo = vm.salida != null && vm.votacionAbierta;
    return Scaffold(
      appBar: AppBar(title: const Text('Votar')),
      body: _cuerpo(context, vm),
      bottomNavigationBar: listo ? const _BarraGuardar() : null,
    );
  }

  Widget _cuerpo(BuildContext context, VotarViewModel vm) {
    final salida = vm.salida;
    if (salida != null && vm.votacionAbierta) {
      return RefreshIndicator(
        onRefresh: vm.cargar,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.margin),
          children: [
            _Encabezado(plan: salida.plan),
            const SizedBox(height: AppSpacing.md),
            const _Contador(),
            const SizedBox(height: AppSpacing.md),
            const _AvisoTotales(),
            const SizedBox(height: AppSpacing.sm),
            if (vm.error != null) ...[
              MensajeError(mensaje: vm.error!),
              const SizedBox(height: AppSpacing.sm),
            ],
            for (final candidato in vm.candidatos)
              _TarjetaCandidato(
                candidato: candidato,
                totalParticipantes: salida.totalParticipantes,
              ),
          ],
        ),
      );
    }
    if (salida != null) {
      final cancelado = salida.plan.estado == EstadoPlan.cancelado;
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          EstadoVacio(
            icono: Icons.lock_outline,
            titulo: cancelado
                ? 'La salida fue cancelada'
                : 'La votación está cerrada',
            mensaje: cancelado
                ? 'Ya no se puede votar en esta salida.'
                : 'Ya no se aceptan votos. Revisa el detalle de la salida.',
          ),
          OutlinedButton(
            onPressed: () => Navigator.of(context).maybePop(),
            child: const Text('Volver al detalle'),
          ),
        ],
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
            titulo: 'No se pudo cargar la votación',
            mensaje: vm.error,
          ),
          OutlinedButton(onPressed: vm.cargar, child: const Text('Reintentar')),
        ],
      );
    }
    return const Center(child: CircularProgressIndicator());
  }
}

class _Encabezado extends StatelessWidget {
  const _Encabezado({required this.plan});

  final PlanModel plan;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<VotarViewModel>();
    final textos = Theme.of(context).textTheme;
    final plazo = plan.fechaLimiteVoto;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'VOTACIÓN ABIERTA',
              style: textos.labelSmall?.copyWith(color: AppColors.primary),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(plan.nombre, style: textos.headlineSmall),
            const SizedBox(height: AppSpacing.sm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.timer_outlined,
                  size: 20,
                  color: vm.plazoVencido
                      ? AppColors.error
                      : AppColors.secondary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    plazo == null
                        ? 'Sin plazo para votar'
                        : vm.plazoVencido
                        ? 'Plazo vencido (${formatearFechaHoraLima(plazo)}): '
                              'aún puedes votar hasta el cierre.'
                        : 'Plazo para votar: ${formatearFechaHoraLima(plazo)}',
                    style: textos.bodyMedium,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Contador extends StatelessWidget {
  const _Contador();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<VotarViewModel>();
    final textos = Theme.of(context).textTheme;
    final elegidos = vm.seleccion.length;
    final String estado;
    final Color colorEstado;
    if (vm.hayCambios) {
      estado = vm.yaVoto
          ? 'Cambios sin guardar: cuenta tu última selección guardada.'
          : 'Todavía no guardaste tu voto.';
      colorEstado = AppColors.secondary;
    } else if (vm.yaVoto) {
      estado = 'Voto guardado. Puedes cambiarlo hasta el cierre.';
      colorEstado = AppColors.primary;
    } else {
      estado = 'Todavía no votaste.';
      colorEstado = AppColors.textSecondary;
    }
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.how_to_vote_outlined, color: AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Has seleccionado $elegidos de ${vm.maximo} '
                  '${vm.maximo == 1 ? 'lugar permitido' : 'lugares permitidos'}',
                  style: textos.titleSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              for (var i = 0; i < vm.maximo; i++)
                Expanded(
                  child: Container(
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: i < elegidos
                          ? AppColors.primary
                          : AppColors.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(estado, style: textos.bodySmall?.copyWith(color: colorEstado)),
        ],
      ),
    );
  }
}

class _AvisoTotales extends StatelessWidget {
  const _AvisoTotales();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<VotarViewModel>();
    final textos = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.info_outline, size: 18, color: AppColors.textMuted),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            vm.totalesDesactualizados
                ? 'Tu voto se guardó, pero no se pudieron actualizar los '
                      'totales. Desliza hacia abajo para recargar.'
                : 'Totales no definitivos: pueden cambiar hasta que un '
                      'administrador cierre la votación. No se muestra quién '
                      'votó por cada lugar.',
            style: textos.bodySmall?.copyWith(
              color: vm.totalesDesactualizados
                  ? AppColors.error
                  : AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

class _TarjetaCandidato extends StatelessWidget {
  const _TarjetaCandidato({
    required this.candidato,
    required this.totalParticipantes,
  });

  final CandidatoModel candidato;
  final int totalParticipantes;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<VotarViewModel>();
    final textos = Theme.of(context).textTheme;
    final categoria = candidato.categoria;
    final elegido = vm.estaSeleccionado(candidato.id);
    final habilitado = vm.puedeAlternar(candidato.id);
    final votos = vm.total(candidato.id);
    // la barra muestra la parte del grupo que eligio el lugar
    final proporcion = totalParticipantes == 0
        ? 0.0
        : (votos / totalParticipantes).clamp(0.0, 1.0);
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(
          color: elegido ? AppColors.primary : AppColors.borderSubtle,
          width: elegido ? 2 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: habilitado ? () => vm.alternar(candidato.id) : null,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.gutterSm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor:
                        categoria?.colorFondo ?? AppColors.surfaceContainer,
                    child: Icon(
                      categoria?.icono ?? Icons.place_outlined,
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
                          style: textos.titleSmall,
                        ),
                        Text(
                          [
                            if (candidato.zona != null)
                              candidato.zona!.etiqueta,
                            if (categoria != null) categoria.etiqueta,
                          ].join(' · '),
                          style: textos.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          TextosLugar.precioPorPersona(
                            candidato.precioEstimadoPen,
                          ),
                          style: textos.bodySmall?.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Checkbox(
                    value: elegido,
                    onChanged: habilitado
                        ? (_) => vm.alternar(candidato.id)
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Text(
                    'Total de votos',
                    style: textos.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    votos == 1 ? '1 voto' : '$votos votos',
                    style: textos.labelLarge,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: proporcion,
                  minHeight: 6,
                  color: AppColors.tealLight,
                  backgroundColor: AppColors.surfaceContainerHighest,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BarraGuardar extends StatelessWidget {
  const _BarraGuardar();

  Future<void> _guardar(BuildContext context) async {
    final vm = context.read<VotarViewModel>();
    final mensajes = ScaffoldMessenger.of(context);
    if (await vm.guardar()) {
      mensajes.showSnackBar(
        const SnackBar(content: Text('Tus votos se guardaron.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<VotarViewModel>();
    final textos = Theme.of(context).textTheme;
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: const BoxDecoration(
          color: AppColors.surfaceWhite,
          border: Border(top: BorderSide(color: AppColors.borderSubtle)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (vm.errorGuardado != null) ...[
              MensajeError(mensaje: vm.errorGuardado!),
              const SizedBox(height: AppSpacing.sm),
            ],
            FilledButton.icon(
              onPressed: vm.puedeGuardar ? () => _guardar(context) : null,
              icon: vm.guardando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.onPrimary,
                      ),
                    )
                  : const Icon(Icons.check_circle_outline),
              label: Text(
                'Guardar mis votos (${vm.seleccion.length}/${vm.maximo})',
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Las selecciones pueden modificarse hasta el cierre manual por '
              'un administrador.',
              textAlign: TextAlign.center,
              style: textos.bodySmall?.copyWith(color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
