import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/mensaje_error.dart';
import '../../../lugares/presentation/widgets/estilo_lugar.dart';
import '../../../votacion/data/candidato_model.dart';
import '../../../votacion/data/resultado_votacion.dart';
import '../detalle_plan_view_model.dart';

// resultado de la votacion cerrada ordenado por votos y desempate (rf08, p05)
class TarjetaResultado extends StatelessWidget {
  const TarjetaResultado({super.key});

  Future<void> _resolver(
    BuildContext context,
    ResultadoVotacion resultado,
  ) async {
    final vm = context.read<DetallePlanViewModel>();
    final mensajes = ScaffoldMessenger.of(context);
    final elegidos = await showModalBottomSheet<Set<String>>(
      context: context,
      // sobre el navegador raiz para que la barra de pestanas no la tape
      useRootNavigator: true,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => _HojaDesempate(
        empatados: resultado.empatados,
        cupos: resultado.cuposPendientes,
      ),
    );
    if (elegidos == null || !context.mounted) return;
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resolver empate'),
        content: const Text(
          'Los lugares elegidos pasan al itinerario. '
          'La elección es definitiva.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (confirmado != true) return;
    if (await vm.resolverEmpate(elegidos)) {
      // reemplaza un aviso anterior, como el del cierre, para confirmar al instante
      mensajes
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Empate resuelto.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DetallePlanViewModel>();
    final textos = Theme.of(context).textTheme;
    final resultado = vm.resultado;
    if (resultado == null) return const SizedBox.shrink();
    final empatados = {for (final c in resultado.empatados) c.id};
    final cupos = resultado.cuposPendientes;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.leaderboard_outlined,
                  color: AppColors.primary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Resultado de la votación',
                    style: textos.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Votación cerrada. Pasan al itinerario los más votados, hasta '
              '${resultado.maxActividades} '
              '${resultado.maxActividades == 1 ? 'actividad' : 'actividades'}; '
              'los lugares sin votos no pasan.',
              style: textos.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
            if (resultado.empatePendiente) ...[
              const SizedBox(height: AppSpacing.gutterSm),
              Container(
                padding: const EdgeInsets.all(AppSpacing.gutterSm),
                decoration: BoxDecoration(
                  color: AppColors.amberSurface,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.balance, color: AppColors.tertiary),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Empate en el último puesto: falta elegir '
                        '${cupos == 1 ? '1 lugar' : '$cupos lugares'} entre '
                        'los empatados.'
                        '${vm.puedeResolverEmpate ? '' : ' Un administrador elegirá cuál pasa al itinerario.'}',
                        style: textos.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            for (final candidato in resultado.ordenados)
              _FilaResultado(
                candidato: candidato,
                empatado: empatados.contains(candidato.id),
              ),
            if (vm.puedeResolverEmpate) ...[
              const SizedBox(height: AppSpacing.sm),
              FilledButton.icon(
                onPressed: vm.resolviendo
                    ? null
                    : () => _resolver(context, resultado),
                icon: vm.resolviendo
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.balance),
                label: const Text('Resolver empate'),
              ),
            ],
            if (vm.errorEmpate != null) ...[
              const SizedBox(height: AppSpacing.gutterSm),
              MensajeError(mensaje: vm.errorEmpate!),
            ],
          ],
        ),
      ),
    );
  }
}

String _votos(int? total) => total == 1 ? '1 voto' : '${total ?? 0} votos';

class _FilaResultado extends StatelessWidget {
  const _FilaResultado({required this.candidato, required this.empatado});

  final CandidatoModel candidato;
  final bool empatado;

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
                    _votos(candidato.totalVotos),
                    TextosLugar.precioPorPersona(candidato.precioEstimadoPen),
                  ].join(' · '),
                  style: textos.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (candidato.seleccionado)
            const _Marca(
              texto: 'Pasa al itinerario',
              color: AppColors.primary,
              fondo: AppColors.tealSurface,
            )
          else if (empatado)
            const _Marca(
              texto: 'Empate',
              color: AppColors.tertiary,
              fondo: AppColors.amberSurface,
            ),
        ],
      ),
    );
  }
}

class _Marca extends StatelessWidget {
  const _Marca({required this.texto, required this.color, required this.fondo});

  final String texto;
  final Color color;
  final Color fondo;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        texto,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color),
      ),
    );
  }
}

// eleccion de exactamente los cupos libres entre los empatados
class _HojaDesempate extends StatefulWidget {
  const _HojaDesempate({required this.empatados, required this.cupos});

  final List<CandidatoModel> empatados;
  final int cupos;

  @override
  State<_HojaDesempate> createState() => _HojaDesempateState();
}

class _HojaDesempateState extends State<_HojaDesempate> {
  final _elegidos = <String>{};

  void _alternar(String id) {
    setState(() {
      if (!_elegidos.remove(id) && _elegidos.length < widget.cupos) {
        _elegidos.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final cupos = widget.cupos;
    final completo = _elegidos.length == cupos;
    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Text(
              cupos == 1
                  ? 'Elige 1 lugar para el itinerario'
                  : 'Elige $cupos lugares para el itinerario',
              style: textos.titleMedium,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Text(
              'Empatados con ${_votos(widget.empatados.first.totalVotos)}.',
              style: textos.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final candidato in widget.empatados)
            CheckboxListTile(
              value: _elegidos.contains(candidato.id),
              onChanged: _elegidos.contains(candidato.id) || !completo
                  ? (_) => _alternar(candidato.id)
                  : null,
              title: Text(candidato.nombreLugar ?? 'Lugar no disponible'),
              subtitle: Text(
                [
                  if (candidato.categoria != null)
                    candidato.categoria!.etiqueta,
                  TextosLugar.precioPorPersona(candidato.precioEstimadoPen),
                ].join(' · '),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              0,
            ),
            child: FilledButton(
              onPressed: completo
                  ? () => Navigator.of(context).pop({..._elegidos})
                  : null,
              child: Text('Elegir (${_elegidos.length}/$cupos)'),
            ),
          ),
        ],
      ),
    );
  }
}
