import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/utils/formato.dart';
import '../../../core/widgets/estado_vacio.dart';
import '../../../core/widgets/mensaje_error.dart';
import '../../lugares/data/lugar_model.dart';
import '../../lugares/data/lugares_repository.dart';
import '../../lugares/presentation/widgets/estilo_lugar.dart';
import '../../salidas/data/salidas_repository.dart';
import '../../votacion/data/votacion_repository.dart';
import '../data/itinerario_repository.dart';
import 'reemplazar_actividad_view_model.dart';
import 'widgets/datos_actividad.dart';

// p07: elegir reemplazo de una actividad confirmada, sin votacion (rf10)
// al guardar devuelve true a la pantalla anterior
class ReemplazarActividadScreen extends StatelessWidget {
  const ReemplazarActividadScreen({
    super.key,
    required this.planId,
    required this.actividadId,
  });

  final String planId;
  final String actividadId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ReemplazarActividadViewModel(
        context.read<SalidasRepository>(),
        context.read<VotacionRepository>(),
        context.read<LugaresRepository>(),
        context.read<ItinerarioRepository>(),
        planId: planId,
        actividadId: actividadId,
      )..cargar(),
      child: const _Vista(),
    );
  }
}

class _Vista extends StatelessWidget {
  const _Vista();

  Future<void> _confirmar(BuildContext context) async {
    final vm = context.read<ReemplazarActividadViewModel>();
    final actual = vm.actividad?.nombreLugar ?? 'La actividad';
    final nuevo = vm.alternativaElegida?.nombre ?? 'el lugar elegido';
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reemplazar actividad'),
        content: Text(
          '$actual se reemplaza por $nuevo en la misma posición y con la '
          'misma fecha y hora. El grupo verá el cambio en el itinerario.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Volver'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Reemplazar'),
          ),
        ],
      ),
    );
    if (confirmado != true || !context.mounted) return;
    if (await vm.confirmar() && context.mounted) context.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ReemplazarActividadViewModel>();
    final listo = vm.puedeReemplazar;
    return Scaffold(
      appBar: AppBar(title: const Text('Reemplazar actividad')),
      body: _cuerpo(context, vm),
      bottomNavigationBar: listo
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.margin,
                  AppSpacing.sm,
                  AppSpacing.margin,
                  AppSpacing.sm,
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
                      onPressed: vm.elegido == null || vm.guardando
                          ? null
                          : () => _confirmar(context),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                      icon: vm.guardando
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check_circle_outline),
                      label: const Text('Confirmar cambio de actividad'),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  Widget _cuerpo(BuildContext context, ReemplazarActividadViewModel vm) {
    if (vm.cargando && vm.salida == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (vm.error != null && vm.salida == null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          EstadoVacio(
            icono: Icons.cloud_off_outlined,
            titulo: 'No se pudieron cargar las alternativas',
            mensaje: vm.error,
          ),
          OutlinedButton(onPressed: vm.cargar, child: const Text('Reintentar')),
        ],
      );
    }
    final actividad = vm.actividad;
    if (!vm.puedeReemplazar || actividad == null) {
      return const EstadoVacio(
        icono: Icons.lock_outline,
        titulo: 'No se puede reemplazar esta actividad',
        mensaje: 'Solo un administrador cambia actividades de una salida confirmada.',
      );
    }
    final textos = Theme.of(context).textTheme;
    final deVotacion = vm.deVotacion;
    final catalogo = vm.catalogo;
    return RefreshIndicator(
      onRefresh: vm.cargar,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.margin),
        children: [
          Text(
            'Plan · ${vm.salida!.plan.nombre}',
            style: textos.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Estás cambiando una actividad de la salida confirmada. '
            'El reemplazo se aplica sin votación.',
            style: textos.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          _TarjetaActual(vm: vm),
          if (vm.estimacion != null) ...[
            const SizedBox(height: AppSpacing.md),
            _TarjetaBalance(vm: vm),
          ],
          const SizedBox(height: AppSpacing.lg),
          _TituloSeccion(
            icono: Icons.how_to_vote_outlined,
            titulo: 'Opciones de la votación',
            detalle: deVotacion.length == 1
                ? '1 opción no elegida'
                : '${deVotacion.length} opciones no elegidas',
          ),
          if (deVotacion.isEmpty)
            _TextoVacio(
              'No quedan candidatos de la votación fuera del itinerario.',
            )
          else
            for (final a in deVotacion) _TarjetaAlternativa(alternativa: a),
          const SizedBox(height: AppSpacing.lg),
          const _TituloSeccion(
            icono: Icons.storefront_outlined,
            titulo: 'Catálogo',
            detalle: 'Filtra por zona y categoría',
          ),
          _Filtros(vm: vm),
          const SizedBox(height: AppSpacing.sm),
          if (catalogo.isEmpty)
            _TextoVacio('Sin lugares para estos filtros.')
          else
            for (final a in catalogo) _TarjetaAlternativa(alternativa: a),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.gutterSm),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 20,
                  color: AppColors.primary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'El cambio se actualizará en el itinerario y generará un '
                    'aviso automático en la app.',
                    style: textos.bodyMedium,
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

class _TarjetaActual extends StatelessWidget {
  const _TarjetaActual({required this.vm});

  final ReemplazarActividadViewModel vm;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final actividad = vm.actividad!;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: AppColors.coralSurface,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                const Icon(Icons.swap_horiz, color: AppColors.secondary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'ACTIVIDAD A SUSTITUIR',
                    style: textos.labelMedium?.copyWith(
                      color: AppColors.secondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: DatosActividad(
              actividad: actividad,
              numero: actividad.posicion,
            ),
          ),
        ],
      ),
    );
  }
}

class _TarjetaBalance extends StatelessWidget {
  const _TarjetaBalance({required this.vm});

  final ReemplazarActividadViewModel vm;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final e = vm.estimacion!;
    final elegida = vm.alternativaElegida;
    final proyectado = elegida == null ? null : vm.totalCon(elegida);
    final incompletaNueva = elegida != null && vm.incompletaCon(elegida);
    final excesoNuevo = elegida == null ? 0.0 : vm.excesoCon(elegida);
    final diferencia = proyectado == null ? null : proyectado - e.totalEstimado;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: AppColors.primary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Presupuesto por persona',
                    style: textos.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Tope: ${formatearSoles(e.presupuestoSoles)}',
              style: textos.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _Monto(
                    etiqueta: e.incompleta ? 'Actual (incompleto)' : 'Actual',
                    valor: formatearSoles(e.totalEstimado),
                    color: e.excede
                        ? AppColors.budgetExceeded
                        : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _Monto(
                    etiqueta: incompletaNueva
                        ? 'Proyectado (incompleto)'
                        : 'Proyectado',
                    valor: proyectado == null
                        ? 'Elige una opción'
                        : formatearSoles(proyectado),
                    color: proyectado == null
                        ? AppColors.textMuted
                        : excesoNuevo > 0
                        ? AppColors.budgetExceeded
                        : AppColors.primary,
                  ),
                ),
              ],
            ),
            if (diferencia != null && diferencia != 0) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                diferencia < 0
                    ? 'Ahorro de ${formatearSoles(-diferencia)} por persona.'
                    : 'Aumenta ${formatearSoles(diferencia)} por persona.',
                style: textos.bodyMedium?.copyWith(
                  color: diferencia < 0
                      ? AppColors.primary
                      : AppColors.tertiary,
                ),
              ),
            ],
            if (excesoNuevo > 0) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Supera el presupuesto en ${formatearSoles(excesoNuevo)} por '
                'persona. Se puede confirmar igualmente.',
                style: textos.bodySmall?.copyWith(
                  color: AppColors.budgetExceeded,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Monto extends StatelessWidget {
  const _Monto({
    required this.etiqueta,
    required this.valor,
    required this.color,
  });

  final String etiqueta;
  final String valor;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.gutterSm),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            etiqueta,
            style: textos.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(valor, style: textos.titleMedium?.copyWith(color: color)),
        ],
      ),
    );
  }
}

class _TituloSeccion extends StatelessWidget {
  const _TituloSeccion({
    required this.icono,
    required this.titulo,
    required this.detalle,
  });

  final IconData icono;
  final String titulo;
  final String detalle;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Icon(icono, color: AppColors.secondary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(titulo, style: textos.titleLarge)),
          Flexible(
            child: Text(
              detalle,
              textAlign: TextAlign.end,
              style: textos.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _TextoVacio extends StatelessWidget {
  const _TextoVacio(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Text(
        texto,
        style: Theme.of(context).textTheme.bodyMedium
            ?.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}

class _Filtros extends StatelessWidget {
  const _Filtros({required this.vm});

  final ReemplazarActividadViewModel vm;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _Chip(
                texto: 'Todas las zonas',
                activo: vm.zona == null,
                alTocar: () => vm.elegirZona(null),
              ),
              for (final zona in ZonaLugar.values)
                _Chip(
                  texto: zona.etiqueta,
                  activo: vm.zona == zona,
                  alTocar: () => vm.elegirZona(zona),
                ),
            ],
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _Chip(
                texto: 'Todas las categorías',
                activo: vm.categoria == null,
                alTocar: () => vm.elegirCategoria(null),
              ),
              for (final categoria in CategoriaLugar.values)
                _Chip(
                  texto: categoria.etiqueta,
                  activo: vm.categoria == categoria,
                  alTocar: () => vm.elegirCategoria(categoria),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.texto,
    required this.activo,
    required this.alTocar,
  });

  final String texto;
  final bool activo;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: ChoiceChip(
        label: Text(texto),
        selected: activo,
        onSelected: (_) => alTocar(),
      ),
    );
  }
}

class _TarjetaAlternativa extends StatelessWidget {
  const _TarjetaAlternativa({required this.alternativa});

  final AlternativaReemplazo alternativa;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ReemplazarActividadViewModel>();
    final textos = Theme.of(context).textTheme;
    final a = alternativa;
    final elegida = vm.elegido == a.lugarId;
    final total = vm.totalCon(a);
    final exceso = vm.excesoCon(a);
    final incompleta = vm.incompletaCon(a);
    final datos = [
      a.zona?.etiqueta,
      a.categoria?.etiqueta,
    ].whereType<String>().join(' · ');
    return Card(
      color: elegida ? AppColors.tealSurface : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(
          color: elegida ? AppColors.primary : AppColors.borderSubtle,
        ),
      ),
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: vm.guardando ? null : () => vm.elegir(a.lugarId),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.gutterSm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color:
                          a.categoria?.colorFondo ??
                          AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(
                      a.categoria?.icono ?? Icons.place_outlined,
                      color: a.categoria?.colorIcono ?? AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.gutterSm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(a.nombre, style: textos.titleMedium),
                        if (datos.isNotEmpty)
                          Text(
                            datos,
                            style: textos.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          TextosLugar.precioPorPersona(a.precioEstimadoPen),
                          style: textos.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Icon(
                    elegida ? Icons.check_circle : Icons.circle_outlined,
                    color: elegida
                        ? AppColors.primary
                        : AppColors.outlineVariant,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: [
                  if (a.votos != null)
                    _Insignia(
                      texto: a.votos == 1 ? '1 voto' : '${a.votos} votos',
                      fondo: AppColors.surfaceContainerLow,
                      color: AppColors.textSecondary,
                    ),
                  if (total != null)
                    exceso > 0
                        ? _Insignia(
                            texto: 'Excede por ${formatearSoles(exceso)}',
                            fondo: AppColors.budgetBadgeBg,
                            color: AppColors.budgetExceeded,
                          )
                        : _Insignia(
                            texto:
                                'Nuevo total: ${formatearSoles(total)}'
                                '${incompleta ? ' (incompleto)' : ''}',
                            fondo: AppColors.tealSurface,
                            color: AppColors.primary,
                          ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Insignia extends StatelessWidget {
  const _Insignia({
    required this.texto,
    required this.fondo,
    required this.color,
  });

  final String texto;
  final Color fondo;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
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
